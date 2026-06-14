import SwiftUI
import Observation

// MARK: - Transient visual effects (not persisted)

struct FloatingText: Identifiable {
    let id = UUID()
    var text: String
    var point: CGPoint
    var color: Color
    var bornAt: Double
    var rise: CGFloat = 46
    var fontSize: CGFloat = 18
}

struct TapParticle: Identifiable {
    let id = UUID()
    var point: CGPoint
    var velocity: CGVector
    var color: Color
    var bornAt: Double
    var size: CGFloat
}

struct CoinPop: Identifiable {
    let id = UUID()
    var point: CGPoint
    var bornAt: Double
}

struct OfflineReport: Identifiable {
    let id = UUID()
    var duration: Double
    var coins: Double
    var resourcesProduced: Double
    var deliveries: Double
}

/// The central game engine + observable state. Owns the simulation tick.
@Observable
final class GameStore {

    var state: GameState

    // Transient UI effects
    var floatingTexts: [FloatingText] = []
    var particles: [TapParticle] = []
    var coinPops: [CoinPop] = []
    var screenShake: CGFloat = 0
    var achievementToast: AchievementConfig?
    var offlineReport: OfflineReport?
    var prestigeFlash: Bool = false
    var lastTapBurstAt: Double = 0

    // Internal monotonic clock (seconds since store creation) for effect lifetimes.
    private(set) var clock: Double = 0

    private var ticker: DisplayLinkTicker?
    private var saveAccumulator: Double = 0
    private var progressCheckAccumulator: Double = 0
    private var achievementQueue: [AchievementConfig] = []
    private var toastTimer: Double = 0
    private let loadedFromSave: Bool

    private let trackLengthUnits: Double = 100

    // MARK: - Lifecycle

    init() {
        if let saved = SaveService.shared.load() {
            state = saved
            loadedFromSave = true
        } else {
            state = NewGame.freshState(now: Date())
            loadedFromSave = false
        }
        Haptics.shared.hapticsEnabled = state.settings.hapticsEnabled
    }

    /// Called once when the game UI appears: applies offline progress and starts the loop.
    func begin() {
        if loadedFromSave {
            applyOfflineProgress()
        }
        startLoop()
    }

    func startLoop() {
        if ticker == nil {
            ticker = DisplayLinkTicker(onTick: { [weak self] dt in
                self?.tick(dt)
            })
        }
        ticker?.start()
    }

    func stopLoop() {
        ticker?.stop()
    }

    /// Called on scene background: persist and pause.
    func handleBackground() {
        state.lastSaved = Date()
        SaveService.shared.save(state)
        stopLoop()
    }

    /// Called on scene foreground: apply elapsed-time offline gains and resume.
    func handleForeground() {
        applyOfflineProgress()
        startLoop()
    }

    // MARK: - Simulation tick

    func tick(_ rawDt: Double) {
        let dt = min(max(rawDt, 0), 0.1) // clamp to avoid jumps after stalls
        clock += dt
        let now = Date()

        state.stats.timePlayed += dt

        // Auto-trigger boost when the meter is full.
        if Economy.hasAutomation(state, "autoBoost"),
           state.boost.meter >= Balance.boostMeterFull,
           !state.boost.isActive(now: now) {
            triggerBoost(autoPick(), now: now)
        }

        produce(dt: dt, now: now, efficiency: 1)
        runTrains(dt: dt, now: now, auto: true)

        // Decay screen shake.
        if screenShake > 0 { screenShake = max(0, screenShake - dt * 90) }

        pruneEffects()
        advanceToast(dt: dt)

        // Throttled quest/achievement evaluation.
        progressCheckAccumulator += dt
        if progressCheckAccumulator >= 0.4 {
            progressCheckAccumulator = 0
            evaluateAchievements()
        }

        // Autosave.
        saveAccumulator += dt
        if saveAccumulator >= 5 {
            saveAccumulator = 0
            state.lastSaved = now
            SaveService.shared.save(state)
        }
    }

    private func produce(dt: Double, now: Date, efficiency: Double) {
        let cap = Economy.storageCapacity(state)
        for di in state.districts.indices where state.districts[di].unlocked {
            guard let cfg = Catalog.district(state.districts[di].id) else { continue }
            for ni in state.districts[di].nodes.indices {
                let node = state.districts[di].nodes[ni]
                guard let nc = cfg.node(node.id), let kind = nc.kind.produces else { continue }
                let rate = Economy.nodeProduction(node, config: nc, state, now: now)
                guard rate > 0 else { continue }
                let cur = state.resources[kind]
                let next = min(cap, cur + rate * dt * efficiency)
                let produced = max(0, next - cur)
                state.resources[kind] = next
                state.stats.totalResourcesProduced += produced
            }
        }
    }

    private func runTrains(dt: Double, now: Date, auto: Bool) {
        let autoDispatch = Economy.hasAutomation(state, "autoDispatch")
        for di in state.districts.indices where state.districts[di].unlocked {
            guard let cfg = Catalog.district(state.districts[di].id) else { continue }
            for ti in state.districts[di].trains.indices {
                let train = state.districts[di].trains[ti]
                guard autoDispatch else { continue } // manual mode advances via taps
                let interval = Economy.trainInterval(train, district: state.districts[di], state, now: now)
                let advance = dt / max(0.001, interval)
                advanceTrain(districtIndex: di, trainIndex: ti, by: advance, cfg: cfg, now: now)
            }
        }
    }

    /// Advances a train along the loop, triggering a delivery each time it completes.
    private func advanceTrain(districtIndex di: Int, trainIndex ti: Int, by advance: Double,
                              cfg: DistrictConfig, now: Date) {
        var phase = state.districts[di].trains[ti].phase + advance
        state.stats.distanceTraveled += advance * trackLengthUnits
        let capacity = Economy.trainCapacity(state.districts[di].trains[ti], district: state.districts[di], state)
        var safety = 0
        while phase >= 1 && safety < 4 {
            phase -= 1
            deliverUsingPool(districtIndex: di, cfg: cfg, now: now, capacity: capacity)
            safety += 1
        }
        state.districts[di].trains[ti].phase = phase
    }

    private func deliverUsingPool(districtIndex di: Int, cfg: DistrictConfig, now: Date, capacity: Double) {
        let available = state.resources.total
        guard available > 0, capacity > 0 else { return }
        let units = min(capacity, available)
        var coinValue = 0.0
        for kind in ResourceKind.allCases {
            let share = state.resources[kind] / available
            let drained = units * share
            state.resources[kind] = max(0, state.resources[kind] - drained)
            coinValue += drained * kind.baseValue
        }
        let coins = coinValue * cfg.resourceMultiplier * Economy.coinValueMult(state, now: now)
        state.coins += coins
        state.lifetimeCoins += coins
        state.stats.totalCoinsEarned += coins
        state.stats.trainsDispatched += 1

        // Coin pop at the platform if this is the visible district.
        if state.districts[di].id == state.activeDistrictId, let platform = cfg.node("\(cfg.id).platform") {
            coinPops.append(CoinPop(point: CGPoint(x: platform.x, y: platform.y), bornAt: clock))
        }
        Haptics.shared.deliver()
    }

    // MARK: - Tapping

    /// A tap on the map. `point` is in normalized 0..1 map space; `nodeId` optional.
    func tap(at point: CGPoint, nodeId: String?) {
        let now = Date()
        state.stats.totalTaps += 1

        // Yield resources to whichever production node was tapped (or spread if none).
        let yield = Economy.tapYield(state, now: now)
        let cap = Economy.storageCapacity(state)
        if let nodeId, let kind = nodeResourceKind(nodeId) {
            let cur = state.resources[kind]
            let added = min(cap, cur + yield) - cur
            state.resources[kind] = cur + added
            state.stats.totalResourcesProduced += added
            spawnFloating("+\(yield.bn)", at: point, color: kind.color)
        } else {
            // Spread yield over produced resources, plus a coin trickle.
            distributeTapYield(yield, cap: cap)
            let coinTrickle = max(1, state.coins * Balance.tapCoinFraction * 0.001 + yield * 0.05)
            state.coins += coinTrickle
            state.lifetimeCoins += coinTrickle
            spawnFloating("+\(yield.bn)", at: point, color: RD.Palette.textHi)
        }

        // Nudge every train forward (tapping literally drives the railway pre-automation).
        nudgeTrains(now: now)

        // Charge the boost meter.
        if !state.boost.isActive(now: now) {
            state.boost.meter = min(Balance.boostMeterFull, state.boost.meter + Balance.tapBoostCharge)
        }

        spawnTapParticles(at: point)
        if clock - lastTapBurstAt > 0.04 {
            lastTapBurstAt = clock
            screenShake = min(6, screenShake + 1.4)
            Haptics.shared.tap()
        }
    }

    private func distributeTapYield(_ yield: Double, cap: Double) {
        // Give the yield to the resource with active production, else coal.
        let prod = Economy.totalProduction(state, now: Date())
        let total = prod.total
        if total <= 0 {
            let cur = state.resources.coal
            state.resources.coal = min(cap, cur + yield)
            state.stats.totalResourcesProduced += state.resources.coal - cur
            return
        }
        for kind in ResourceKind.allCases {
            let share = prod[kind] / total
            let cur = state.resources[kind]
            let added = min(cap, cur + yield * share) - cur
            state.resources[kind] = cur + max(0, added)
            state.stats.totalResourcesProduced += max(0, added)
        }
    }

    private func nudgeTrains(now: Date) {
        for di in state.districts.indices where state.districts[di].unlocked {
            guard let cfg = Catalog.district(state.districts[di].id) else { continue }
            for ti in state.districts[di].trains.indices {
                advanceTrain(districtIndex: di, trainIndex: ti, by: Balance.tapPhaseNudge, cfg: cfg, now: now)
            }
        }
    }

    private func nodeResourceKind(_ nodeId: String) -> ResourceKind? {
        for d in state.districts {
            guard let cfg = Catalog.district(d.id) else { continue }
            if let nc = cfg.node(nodeId) { return nc.kind.produces }
        }
        return nil
    }

    // MARK: - Building actions

    @discardableResult
    func build(districtId: String, nodeId: String) -> Bool {
        guard let di = state.districts.firstIndex(where: { $0.id == districtId }),
              let cfg = Catalog.district(districtId),
              let nc = cfg.node(nodeId),
              let ni = state.districts[di].nodes.firstIndex(where: { $0.id == nodeId }),
              !state.districts[di].nodes[ni].built else { return false }
        let cost = Economy.buildCost(nc, district: cfg)
        guard spend(cost) else { failFeedback(); return false }
        state.districts[di].nodes[ni].built = true
        state.districts[di].nodes[ni].level = 1
        state.stats.buildingsBuilt += 1
        Haptics.shared.build()
        saveNow()
        return true
    }

    @discardableResult
    func upgrade(districtId: String, nodeId: String) -> Bool {
        guard let di = state.districts.firstIndex(where: { $0.id == districtId }),
              let cfg = Catalog.district(districtId),
              let nc = cfg.node(nodeId),
              let ni = state.districts[di].nodes.firstIndex(where: { $0.id == nodeId }),
              state.districts[di].nodes[ni].built else { return false }
        let cost = Economy.upgradeCost(state.districts[di].nodes[ni], config: nc, district: cfg)
        guard spend(cost) else { failFeedback(); return false }
        state.districts[di].nodes[ni].level += 1
        state.stats.buildingsUpgraded += 1
        Haptics.shared.select()
        saveNow()
        return true
    }

    // MARK: - Train actions

    @discardableResult
    func buyTrain(districtId: String, kind: TrainKind) -> Bool {
        guard let di = state.districts.firstIndex(where: { $0.id == districtId }),
              let cfg = Catalog.district(districtId) else { return false }
        let count = state.districts[di].trains.count
        guard count < Balance.maxTrainsPerDistrict else { return false }
        let cost = Economy.trainBuyCost(kind: kind, district: cfg, existing: count)
        guard spend(cost) else { failFeedback(); return false }
        let phase = Double(count) / Double(Balance.maxTrainsPerDistrict)
        let train = TrainState(id: "\(districtId).t\(count)-\(UUID().uuidString.prefix(4))",
                               kind: kind, capacityLevel: 1, speedLevel: 1, phase: phase)
        state.districts[di].trains.append(train)
        Haptics.shared.build()
        saveNow()
        return true
    }

    @discardableResult
    func upgradeTrainSpeed(districtId: String, trainId: String) -> Bool {
        guard let di = state.districts.firstIndex(where: { $0.id == districtId }),
              let cfg = Catalog.district(districtId),
              let ti = state.districts[di].trains.firstIndex(where: { $0.id == trainId }) else { return false }
        let cost = Economy.trainSpeedUpgradeCost(state.districts[di].trains[ti], district: cfg)
        guard spend(cost) else { failFeedback(); return false }
        state.districts[di].trains[ti].speedLevel += 1
        Haptics.shared.select()
        saveNow()
        return true
    }

    @discardableResult
    func upgradeTrainCapacity(districtId: String, trainId: String) -> Bool {
        guard let di = state.districts.firstIndex(where: { $0.id == districtId }),
              let cfg = Catalog.district(districtId),
              let ti = state.districts[di].trains.firstIndex(where: { $0.id == trainId }) else { return false }
        let cost = Economy.trainCapacityUpgradeCost(state.districts[di].trains[ti], district: cfg)
        guard spend(cost) else { failFeedback(); return false }
        state.districts[di].trains[ti].capacityLevel += 1
        Haptics.shared.select()
        saveNow()
        return true
    }

    // MARK: - Upgrade tree

    @discardableResult
    func buyUpgrade(_ id: String) -> Bool {
        guard let cfg = UpgradeCatalogue.config(id) else { return false }
        let lvl = state.upgrades[id] ?? 0
        guard lvl < cfg.maxLevel else { return false }
        let cost = cfg.cost(forLevel: lvl)
        guard spend(cost) else { failFeedback(); return false }
        state.upgrades[id] = lvl + 1
        if let autoId = cfg.automationId { state.automation.insert(autoId) }
        Haptics.shared.success()
        saveNow()
        return true
    }

    // MARK: - Districts

    func canUnlock(_ id: String) -> Bool {
        guard let cfg = Catalog.district(id),
              let d = state.district(id), !d.unlocked else { return false }
        let prevUnlocked = cfg.order == 0 || (Catalog.districts.first(where: { $0.order == cfg.order - 1 }).map { state.district($0.id)?.unlocked ?? false } ?? false)
        return prevUnlocked
            && state.coins >= cfg.unlockCostCoins
            && state.blueprints >= cfg.unlockBlueprints
    }

    @discardableResult
    func unlockDistrict(_ id: String) -> Bool {
        guard canUnlock(id),
              let cfg = Catalog.district(id),
              let di = state.districts.firstIndex(where: { $0.id == id }) else { failFeedback(); return false }
        guard spend(cfg.unlockCostCoins) else { failFeedback(); return false }
        NewGame.activate(&state.districts[di], cfg: cfg)
        state.stats.districtsUnlocked = Double(state.districts.filter { $0.unlocked }.count)
        state.activeDistrictId = id
        Haptics.shared.success()
        saveNow()
        return true
    }

    func selectDistrict(_ id: String) {
        guard let d = state.district(id), d.unlocked else { return }
        state.activeDistrictId = id
        Haptics.shared.select()
    }

    // MARK: - Prestige

    @discardableResult
    func prestige() -> Bool {
        guard Economy.canPrestige(state) else { return false }
        let gain = Economy.prestigeAvailable(state)
        state.blueprints += gain
        state.prestigeCount += 1
        state.stats.prestigeCount += 1

        // Reset the active economy, keep meta-progress.
        state.coins = 25
        state.resources = ResourceBundle()
        state.upgrades = [:]
        state.automation = []
        state.boost = BoostState()
        state.districts = Catalog.districts.map { NewGame.emptyDistrict($0) }
        if let idx = state.districts.firstIndex(where: { $0.id == Catalog.first.id }) {
            NewGame.activate(&state.districts[idx], cfg: Catalog.first)
        }
        state.activeDistrictId = Catalog.first.id
        state.stats.districtsUnlocked = Double(state.districts.filter { $0.unlocked }.count)

        prestigeFlash = true
        Haptics.shared.success()
        saveNow()
        return true
    }

    // MARK: - Boost

    @discardableResult
    func triggerBoost(_ kind: BoostKind, now: Date = Date()) -> Bool {
        guard state.boost.meter >= Balance.boostMeterFull, !state.boost.isActive(now: now) else { return false }
        let duration = kind.duration * Economy.boostDurationMult(state)
        state.boost.activeKind = kind
        state.boost.endsAt = now.addingTimeInterval(duration)
        state.boost.meter = 0
        state.stats.boostsUsed += 1
        Haptics.shared.success()
        return true
    }

    private func autoPick() -> BoostKind {
        let kinds = BoostKind.allCases
        let idx = Int(clock) % kinds.count
        return kinds[idx]
    }

    // MARK: - Quests

    func metricValue(_ metric: ProgressMetric) -> Double {
        switch metric {
        case .totalTaps: return state.stats.totalTaps
        case .lifetimeCoins: return state.lifetimeCoins
        case .currentCoins: return state.coins
        case .trainsDispatched: return state.stats.trainsDispatched
        case .buildingsBuilt: return state.stats.buildingsBuilt
        case .buildingsUpgraded: return state.stats.buildingsUpgraded
        case .districtsUnlocked: return Double(state.districts.filter { $0.unlocked }.count)
        case .prestigeCount: return Double(state.prestigeCount)
        case .distanceTraveled: return state.stats.distanceTraveled
        case .resourcesProduced: return state.stats.totalResourcesProduced
        case .boostsUsed: return state.stats.boostsUsed
        case .trainsOwned: return Double(state.districts.reduce(0) { $0 + $1.trains.count })
        }
    }

    func questCompleted(_ q: QuestConfig) -> Bool { metricValue(q.metric) >= q.target }
    func questClaimed(_ q: QuestConfig) -> Bool { state.quests.claimedIds.contains(q.id) }

    @discardableResult
    func claimQuest(_ q: QuestConfig) -> Bool {
        guard questCompleted(q), !questClaimed(q) else { return false }
        state.quests.claimedIds.insert(q.id)
        state.coins += q.rewardCoins
        state.lifetimeCoins += q.rewardCoins
        state.blueprints += q.rewardBlueprints
        state.stats.questsCompleted += 1
        Haptics.shared.success()
        saveNow()
        return true
    }

    /// The first uncompleted-or-unclaimed quest, for HUD highlighting.
    var activeQuest: QuestConfig? {
        QuestCatalogue.all.first { !questClaimed($0) }
    }

    // MARK: - Achievements

    private func evaluateAchievements() {
        for a in AchievementCatalogue.all where !state.unlockedAchievements.contains(a.id) {
            if metricValue(a.metric) >= a.target {
                state.unlockedAchievements.insert(a.id)
                state.stats.achievementsUnlocked += 1
                achievementQueue.append(a)
                Haptics.shared.success()
            }
        }
        if achievementToast == nil, !achievementQueue.isEmpty {
            achievementToast = achievementQueue.removeFirst()
            toastTimer = 3.0
        }
    }

    func achievementUnlocked(_ a: AchievementConfig) -> Bool {
        state.unlockedAchievements.contains(a.id)
    }

    private func advanceToast(dt: Double) {
        guard achievementToast != nil else { return }
        toastTimer -= dt
        if toastTimer <= 0 {
            withAnimationSafe { achievementToast = nil }
            if !achievementQueue.isEmpty {
                achievementToast = achievementQueue.removeFirst()
                toastTimer = 3.0
            }
        }
    }

    // MARK: - Settings

    func setSound(_ on: Bool) { state.settings.soundEnabled = on; saveNow() }
    func setMusic(_ on: Bool) { state.settings.musicEnabled = on; saveNow() }
    func setHaptics(_ on: Bool) {
        state.settings.hapticsEnabled = on
        Haptics.shared.hapticsEnabled = on
        saveNow()
    }
    func setQuality(_ high: Bool) { state.settings.highQuality = high; saveNow() }
    func completeTutorial() { state.settings.tutorialCompleted = true; saveNow() }
    func resetTutorial() { state.settings.tutorialCompleted = false; saveNow() }

    func resetProgress() {
        SaveService.shared.deleteSave()
        state = NewGame.freshState(now: Date())
        Haptics.shared.hapticsEnabled = state.settings.hapticsEnabled
        SaveService.shared.save(state)
    }

    // MARK: - Offline

    private func applyOfflineProgress() {
        let now = Date()
        let elapsed = now.timeIntervalSince(state.lastSaved)
        guard elapsed > 60 else { return } // ignore short gaps
        let capped = min(elapsed, Economy.offlineCapSeconds(state))
        let efficiency = Economy.hasAutomation(state, "autoForeman")
            ? Balance.offlineEfficiency * 1.6
            : Balance.offlineEfficiency

        let coinsRate = Economy.estimatedCoinsPerSecond(state, now: now)
        let coins = coinsRate * capped * efficiency

        // Fill resource pools partway so the player returns to a busy yard.
        let prod = Economy.totalProduction(state, now: now)
        let cap = Economy.storageCapacity(state)
        var produced = 0.0
        for kind in ResourceKind.allCases {
            let add = prod[kind] * capped * efficiency * 0.4
            let cur = state.resources[kind]
            let next = min(cap, cur + add)
            produced += next - cur
            state.resources[kind] = next
        }

        state.coins += coins
        state.lifetimeCoins += coins
        state.stats.totalCoinsEarned += coins
        let deliveries = coinsRate > 0 ? capped * efficiency * 0.2 : 0
        state.stats.trainsDispatched += deliveries

        if coins > 0 || produced > 0 {
            offlineReport = OfflineReport(duration: elapsed, coins: coins,
                                          resourcesProduced: produced, deliveries: deliveries)
        }
        state.lastSaved = now
    }

    // MARK: - Helpers

    func canAfford(_ cost: Double) -> Bool { state.coins >= cost }

    @discardableResult
    private func spend(_ cost: Double) -> Bool {
        guard state.coins >= cost else { return false }
        state.coins -= cost
        return true
    }

    private func saveNow() {
        state.lastSaved = Date()
        SaveService.shared.save(state)
    }

    private func failFeedback() {
        Haptics.shared.warning()
    }

    // MARK: - Effects

    private func spawnFloating(_ text: String, at point: CGPoint, color: Color) {
        floatingTexts.append(FloatingText(text: text, point: point, color: color, bornAt: clock))
        if floatingTexts.count > 40 { floatingTexts.removeFirst(floatingTexts.count - 40) }
    }

    private func spawnTapParticles(at point: CGPoint) {
        guard state.settings.highQuality else { return }
        let count = 6
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * 2 * .pi + Double(clock)
            let speed = 0.10 + 0.06 * Double((i % 3))
            let v = CGVector(dx: CoreGraphics.cos(angle) * speed, dy: CoreGraphics.sin(angle) * speed - 0.05)
            let colors: [Color] = [RD.Palette.coins, RD.Palette.accent, RD.Palette.textHi, RD.Palette.passengers]
            particles.append(TapParticle(point: point, velocity: v,
                                         color: colors[i % colors.count],
                                         bornAt: clock, size: 5 + CGFloat(i % 3) * 2))
        }
        if particles.count > 120 { particles.removeFirst(particles.count - 120) }
    }

    private func pruneEffects() {
        floatingTexts.removeAll { clock - $0.bornAt > 1.1 }
        particles.removeAll { clock - $0.bornAt > 0.8 }
        coinPops.removeAll { clock - $0.bornAt > 0.9 }
    }

    private func withAnimationSafe(_ body: () -> Void) {
        body()
    }
}
