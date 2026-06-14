import Foundation

/// Pure economy math. No mutation — every function derives a value from `GameState`.
enum Economy {

    // MARK: - Upgrade multipliers

    static func level(_ s: GameState, _ upgradeId: String) -> Int {
        s.upgrades[upgradeId] ?? 0
    }

    /// 1 + Σ(level × perLevel) for every upgrade with the given effect.
    static func multiplier(_ s: GameState, _ effect: UpgradeEffect) -> Double {
        var bonus = 0.0
        for u in UpgradeCatalogue.all where u.effect == effect {
            let lvl = s.upgrades[u.id] ?? 0
            bonus += Double(lvl) * u.effectPerLevel
        }
        return 1 + bonus
    }

    static func blueprintMultiplier(_ s: GameState) -> Double {
        1 + s.blueprints * Balance.blueprintProductionBonus
    }

    static func hasAutomation(_ s: GameState, _ id: String) -> Bool {
        s.automation.contains(id)
    }

    // MARK: - Boost

    static func activeBoost(_ s: GameState, now: Date) -> BoostKind? {
        s.boost.isActive(now: now) ? s.boost.activeKind : nil
    }

    static func boostProductionMult(_ s: GameState, now: Date) -> Double {
        activeBoost(s, now: now)?.productionMult ?? 1
    }
    static func boostCoinMult(_ s: GameState, now: Date) -> Double {
        activeBoost(s, now: now)?.coinMult ?? 1
    }
    static func boostSpeedMult(_ s: GameState, now: Date) -> Double {
        activeBoost(s, now: now)?.speedMult ?? 1
    }

    // MARK: - Production

    static func yieldMultiplier(for kind: ResourceKind, _ s: GameState) -> Double {
        let specific: UpgradeEffect
        switch kind {
        case .coal: specific = .coalYield
        case .steel: specific = .steelYield
        case .passengers: specific = .passengerYield
        case .cargo: specific = .cargoYield
        }
        return multiplier(s, specific) * multiplier(s, .allProduction)
    }

    /// Production per second for a single built production node.
    static func nodeProduction(_ node: NodeState, config: NodeConfig, _ s: GameState, now: Date) -> Double {
        guard node.built, let kind = config.kind.produces, node.level > 0 else { return 0 }
        let base = config.baseProduction * Double(node.level)
        return base
            * yieldMultiplier(for: kind, s)
            * blueprintMultiplier(s)
            * boostProductionMult(s, now: now)
    }

    /// Total production per second across all unlocked districts, by resource.
    static func totalProduction(_ s: GameState, now: Date) -> ResourceBundle {
        var bundle = ResourceBundle()
        for d in s.districts where d.unlocked {
            guard let cfg = Catalog.district(d.id) else { continue }
            for node in d.nodes {
                guard let nc = cfg.node(node.id), let kind = nc.kind.produces else { continue }
                bundle[kind] += nodeProduction(node, config: nc, s, now: now)
            }
        }
        return bundle
    }

    // MARK: - Booster building levels (per district)

    static func boosterLevel(_ d: DistrictState, _ kind: BuildingKind) -> Int {
        guard let cfg = Catalog.district(d.id) else { return 0 }
        for node in d.nodes {
            if let nc = cfg.node(node.id), nc.kind == kind, node.built { return node.level }
        }
        return 0
    }

    // MARK: - Trains

    static func trainSpeedMult(_ train: TrainState, district: DistrictState, _ s: GameState, now: Date) -> Double {
        let signalLvl = boosterLevel(district, .signalTower)
        return train.kind.speedMultiplier
            * (1 + Double(train.speedLevel) * Balance.trainSpeedPerLevel)
            * multiplier(s, .trainSpeed)
            * (1 + Double(signalLvl) * Balance.signalSpeedPerLevel)
            * boostSpeedMult(s, now: now)
    }

    /// Seconds for one loop of the track.
    static func trainInterval(_ train: TrainState, district: DistrictState, _ s: GameState, now: Date) -> Double {
        Balance.trainBaseInterval / max(0.001, trainSpeedMult(train, district: district, s, now: now))
    }

    static func trainCapacity(_ train: TrainState, district: DistrictState, _ s: GameState) -> Double {
        let depotLvl = boosterLevel(district, .depot)
        return Balance.trainBaseCapacityUnits
            * train.kind.capacityMultiplier
            * (1 + Double(train.capacityLevel) * Balance.trainCapacityPerLevel)
            * multiplier(s, .trainCapacity)
            * (1 + Double(depotLvl) * Balance.depotCapacityPerLevel)
            * blueprintMultiplier(s)
    }

    // MARK: - Coins

    static func coinValueMult(_ s: GameState, now: Date) -> Double {
        multiplier(s, .coinValue) * blueprintMultiplier(s) * boostCoinMult(s, now: now)
    }

    // MARK: - Storage

    static func storageCapacity(_ s: GameState) -> Double {
        var warehouseLevels = 0.0
        for d in s.districts where d.unlocked {
            warehouseLevels += Double(boosterLevel(d, .warehouse))
        }
        let base = Balance.baseStoragePerResource + warehouseLevels * Balance.warehouseStoragePerLevel
        return base * multiplier(s, .storage)
    }

    // MARK: - Costs

    static func buildCost(_ config: NodeConfig, district: DistrictConfig) -> Double {
        config.buildCost * district.costMultiplier
    }

    static func upgradeCost(_ node: NodeState, config: NodeConfig, district: DistrictConfig) -> Double {
        let base = config.buildCost * district.costMultiplier
        return base * pow(Balance.upgradeCostGrowth, Double(max(0, node.level)))
    }

    static func trainBuyCost(kind: TrainKind, district: DistrictConfig, existing: Int) -> Double {
        // Each additional train of any kind in a district costs progressively more.
        let kindCost = max(kind.unlockCost, 1) * district.costMultiplier * 0.02
        let scaling = pow(2.2, Double(existing))
        return max(kind.unlockCost * district.costMultiplier * 0.02, kindCost) * scaling + 1
    }

    static func trainSpeedUpgradeCost(_ train: TrainState, district: DistrictConfig) -> Double {
        Balance.trainSpeedUpgradeBase * district.costMultiplier
            * pow(Balance.trainUpgradeCostGrowth, Double(train.speedLevel))
    }

    static func trainCapacityUpgradeCost(_ train: TrainState, district: DistrictConfig) -> Double {
        Balance.trainCapacityUpgradeBase * district.costMultiplier
            * pow(Balance.trainUpgradeCostGrowth, Double(train.capacityLevel))
    }

    // MARK: - Offline

    static func offlineCapSeconds(_ s: GameState) -> Double {
        let extraHours = Double(level(s, "offline_hours"))
        let hours = 2.0 + extraHours
        return min(hours * 3600, 24 * 3600)
    }

    // MARK: - Prestige

    static func prestigeAvailable(_ s: GameState) -> Double {
        let earnable = floor(sqrt(s.lifetimeCoins / Balance.prestigeCoinsPerBlueprint))
        return max(0, earnable - s.blueprints)
    }

    static func canPrestige(_ s: GameState) -> Bool {
        s.lifetimeCoins >= Balance.prestigeUnlockLifetimeCoins && prestigeAvailable(s) >= 1
    }

    // MARK: - Aggregate rates (for HUD readouts)

    /// Estimated coins/sec from current train throughput, assuming resources are available.
    static func estimatedCoinsPerSecond(_ s: GameState, now: Date) -> Double {
        // Coins are produced when trains deliver. Bottleneck is the lesser of
        // production value/sec and train throughput value/sec.
        let prod = totalProduction(s, now: now)
        let avgValue = averageResourceValue(prod, s, now: now)
        let productionValuePerSec = prod.total * avgValue

        var throughputUnitsPerSec = 0.0
        for d in s.districts where d.unlocked {
            for t in d.trains {
                let cap = trainCapacity(t, district: d, s)
                let interval = trainInterval(t, district: d, s, now: now)
                throughputUnitsPerSec += cap / max(0.001, interval)
            }
        }
        let throughputValuePerSec = throughputUnitsPerSec * avgValue
        return min(productionValuePerSec, throughputValuePerSec)
    }

    static func averageResourceValue(_ bundle: ResourceBundle, _ s: GameState, now: Date) -> Double {
        let total = bundle.total
        guard total > 0 else {
            // Fall back to district value of a typical resource.
            let mult = coinValueMult(s, now: now)
            return ResourceKind.passengers.baseValue * districtValueMult(s) * mult
        }
        var sum = 0.0
        for k in ResourceKind.allCases {
            sum += bundle[k] * k.baseValue
        }
        return (sum / total) * districtValueMult(s) * coinValueMult(s, now: now)
    }

    /// Highest unlocked district's resource value multiplier (deliveries scale with reach).
    static func districtValueMult(_ s: GameState) -> Double {
        var best = 1.0
        for d in s.districts where d.unlocked {
            if let cfg = Catalog.district(d.id) { best = max(best, cfg.resourceMultiplier) }
        }
        return best
    }

    // MARK: - Tap

    static func tapYield(_ s: GameState, now: Date) -> Double {
        let prod = totalProduction(s, now: now).total
        let base = Balance.tapBaseYieldUnits + prod * Balance.tapProductionFraction
        return base * multiplier(s, .tapPower) * blueprintMultiplier(s)
    }

    static func boostDurationMult(_ s: GameState) -> Double {
        multiplier(s, .boostDuration)
    }
}
