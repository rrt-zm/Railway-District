import Foundation

/// Tunable economy constants. Kept in one place so the game is balanceable.
enum Balance {
    // Upgrade cost growth per building level.
    static let upgradeCostGrowth: Double = 1.16
    // Production scales linearly with level; this is the per-level factor.
    static let productionPerLevel: Double = 1.0

    // Booster building effects (per level).
    static let signalSpeedPerLevel: Double = 0.08    // +8% train speed
    static let depotCapacityPerLevel: Double = 0.12  // +12% train capacity

    // Train base figures.
    static let trainBaseInterval: Double = 6.0       // seconds per loop at speed 1
    static let trainBaseCapacityUnits: Double = 12.0 // base units carried at capacity 1
    static let trainUpgradeCostGrowth: Double = 1.22
    static let trainSpeedUpgradeBase: Double = 120   // coins
    static let trainCapacityUpgradeBase: Double = 90 // coins
    static let trainSpeedPerLevel: Double = 0.10     // +10% per speed level
    static let trainCapacityPerLevel: Double = 0.18  // +18% per capacity level
    static let maxTrainsPerDistrict: Int = 6

    // Tapping.
    static let tapBaseYieldUnits: Double = 4.0
    static let tapProductionFraction: Double = 0.6   // tap adds this × prod/sec of resources
    static let tapCoinFraction: Double = 0.05
    static let tapPhaseNudge: Double = 0.035         // advances each train's loop on tap
    static let tapBoostCharge: Double = 0.012        // boost meter gained per tap

    // Storage.
    static let baseStoragePerResource: Double = 250
    static let warehouseStoragePerLevel: Double = 400

    // Offline.
    static let offlineCapSeconds: Double = 8 * 3600  // max 8h of accrual
    static let offlineEfficiency: Double = 0.5       // offline earns at 50%

    // Prestige.
    static let prestigeUnlockLifetimeCoins: Double = 1_000_000
    static let prestigeCoinsPerBlueprint: Double = 1_000_000 // sqrt scaling applied
    static let blueprintProductionBonus: Double = 0.02       // +2% global per blueprint spent-equiv

    // Boost meter -> on full, player may trigger a boost.
    static let boostMeterFull: Double = 1.0
}
