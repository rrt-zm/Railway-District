import Foundation

/// Persisted per-node (building slot) state on a district map.
struct NodeState: Codable, Identifiable, Equatable {
    var id: String
    var built: Bool = false
    var level: Int = 0
}

/// Persisted per-train state. Trains animate along the district track.
struct TrainState: Codable, Identifiable, Equatable {
    var id: String
    var kind: TrainKind
    var capacityLevel: Int = 1
    var speedLevel: Int = 1
    /// Animation phase 0..1 so trains aren't all bunched together.
    var phase: Double = 0
}

/// Persisted per-district state.
struct DistrictState: Codable, Identifiable, Equatable {
    var id: String
    var unlocked: Bool = false
    var nodes: [NodeState] = []
    var trains: [TrainState] = []

    func node(_ id: String) -> NodeState? { nodes.first { $0.id == id } }
}

/// Temporary, self-earned boost.
struct BoostState: Codable, Equatable {
    var activeKind: BoostKind? = nil
    var endsAt: Date? = nil
    /// 0..1 charge of the boost meter, filled by tapping.
    var meter: Double = 0

    func isActive(now: Date) -> Bool {
        guard let endsAt else { return false }
        return now < endsAt
    }
    func remaining(now: Date) -> Double {
        guard let endsAt else { return 0 }
        return max(0, endsAt.timeIntervalSince(now))
    }
}

enum BoostKind: String, Codable, CaseIterable {
    case rushHour      // x2 coins
    case overdrive     // x3 production
    case expressLanes  // x2 train speed

    var title: String {
        switch self {
        case .rushHour: return "Rush Hour"
        case .overdrive: return "Overdrive"
        case .expressLanes: return "Express Lanes"
        }
    }
    var detail: String {
        switch self {
        case .rushHour: return "x2 coins from every delivery"
        case .overdrive: return "x3 resource production"
        case .expressLanes: return "x2 train speed"
        }
    }
    var duration: Double { 30 }
    var coinMult: Double { self == .rushHour ? 2 : 1 }
    var productionMult: Double { self == .overdrive ? 3 : 1 }
    var speedMult: Double { self == .expressLanes ? 2 : 1 }
    var glyph: PixelGlyph {
        switch self {
        case .rushHour: return .coin
        case .overdrive: return .bolt
        case .expressLanes: return .signal
        }
    }
}

/// Lifetime + session statistics.
struct Stats: Codable, Equatable {
    var totalTaps: Double = 0
    var totalCoinsEarned: Double = 0
    var totalResourcesProduced: Double = 0
    var trainsDispatched: Double = 0
    var distanceTraveled: Double = 0
    var timePlayed: Double = 0
    var prestigeCount: Double = 0
    var buildingsBuilt: Double = 0
    var buildingsUpgraded: Double = 0
    var boostsUsed: Double = 0
    var questsCompleted: Double = 0
    var achievementsUnlocked: Double = 0
    var districtsUnlocked: Double = 1
}

/// User settings — all persisted, no permissions required.
struct Settings: Codable, Equatable {
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var highQuality: Bool = true
    var tutorialCompleted: Bool = false
}

/// A claimed/active objective snapshot. Progress is computed live from stats/state,
/// but we persist which quests are claimed and the current quest index per chain.
struct QuestProgress: Codable, Equatable {
    var claimedIds: Set<String> = []
}

/// The complete, persisted game state. Codable snapshot saved to disk.
struct GameState: Codable, Equatable {
    var version: Int = 1

    var coins: Double = 0
    var blueprints: Double = 0
    var resources: ResourceBundle = ResourceBundle()

    var lifetimeCoins: Double = 0
    var prestigeCount: Int = 0

    var districts: [DistrictState] = []
    var activeDistrictId: String = ""

    /// upgradeId -> purchased level
    var upgrades: [String: Int] = [:]
    /// unlocked automation ids (e.g. "autoDispatch")
    var automation: Set<String> = []

    var quests: QuestProgress = QuestProgress()
    var unlockedAchievements: Set<String> = []

    var boost: BoostState = BoostState()
    var stats: Stats = Stats()
    var settings: Settings = Settings()

    var lastSaved: Date = Date(timeIntervalSince1970: 0)
    var createdAt: Date = Date(timeIntervalSince1970: 0)

    func district(_ id: String) -> DistrictState? { districts.first { $0.id == id } }
    var activeDistrict: DistrictState? { district(activeDistrictId) }
}
