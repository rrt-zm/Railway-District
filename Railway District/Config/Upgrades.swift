import SwiftUI

/// What a global upgrade modifies. The engine reads these to build multipliers.
enum UpgradeEffect: String, Codable {
    case tapPower
    case coalYield, steelYield, passengerYield, cargoYield
    case allProduction
    case trainSpeed, trainCapacity
    case coinValue
    case offlineHours
    case boostDuration
    case storage
}

enum UpgradeCategory: String, CaseIterable {
    case production = "Production"
    case logistics = "Logistics"
    case economy = "Economy"
    case automation = "Automation"

    var glyph: PixelGlyph {
        switch self {
        case .production: return .mine
        case .logistics: return .train
        case .economy: return .coin
        case .automation: return .gear
        }
    }
}

struct UpgradeConfig: Identifiable {
    let id: String
    let title: String
    let detail: String
    let category: UpgradeCategory
    let baseCost: Double
    let costGrowth: Double
    let maxLevel: Int
    let effect: UpgradeEffect?      // nil for pure automation toggles
    let effectPerLevel: Double      // multiplier add per level (e.g. 0.2 = +20%)
    let automationId: String?       // non-nil => one-time automation unlock
    let glyph: PixelGlyph

    var isAutomation: Bool { automationId != nil }

    func cost(forLevel level: Int) -> Double {
        baseCost * pow(costGrowth, Double(level))
    }
}

enum UpgradeCatalogue {
    static let all: [UpgradeConfig] = [
        // Production
        UpgradeConfig(id: "tap_power", title: "Stronger Hands",
                      detail: "+60% tap yield per level.",
                      category: .production, baseCost: 60, costGrowth: 1.55, maxLevel: 30,
                      effect: .tapPower, effectPerLevel: 0.6, automationId: nil, glyph: .hand),
        UpgradeConfig(id: "coal_yield", title: "Rich Seams",
                      detail: "+30% coal production per level.",
                      category: .production, baseCost: 200, costGrowth: 1.42, maxLevel: 30,
                      effect: .coalYield, effectPerLevel: 0.3, automationId: nil, glyph: .coal),
        UpgradeConfig(id: "steel_yield", title: "Hotter Furnaces",
                      detail: "+30% steel production per level.",
                      category: .production, baseCost: 1_400, costGrowth: 1.45, maxLevel: 30,
                      effect: .steelYield, effectPerLevel: 0.3, automationId: nil, glyph: .steel),
        UpgradeConfig(id: "passenger_yield", title: "Busier Platforms",
                      detail: "+30% passenger flow per level.",
                      category: .production, baseCost: 900, costGrowth: 1.44, maxLevel: 30,
                      effect: .passengerYield, effectPerLevel: 0.3, automationId: nil, glyph: .passenger),
        UpgradeConfig(id: "cargo_yield", title: "Tighter Packing",
                      detail: "+30% cargo production per level.",
                      category: .production, baseCost: 5_000, costGrowth: 1.46, maxLevel: 30,
                      effect: .cargoYield, effectPerLevel: 0.3, automationId: nil, glyph: .crate),
        UpgradeConfig(id: "all_production", title: "District Boom",
                      detail: "+18% to ALL production per level.",
                      category: .production, baseCost: 25_000, costGrowth: 1.6, maxLevel: 25,
                      effect: .allProduction, effectPerLevel: 0.18, automationId: nil, glyph: .bolt),

        // Logistics
        UpgradeConfig(id: "train_speed", title: "Faster Schedules",
                      detail: "+12% train speed per level.",
                      category: .logistics, baseCost: 500, costGrowth: 1.5, maxLevel: 30,
                      effect: .trainSpeed, effectPerLevel: 0.12, automationId: nil, glyph: .signal),
        UpgradeConfig(id: "train_capacity", title: "Bigger Wagons",
                      detail: "+15% train capacity per level.",
                      category: .logistics, baseCost: 650, costGrowth: 1.5, maxLevel: 30,
                      effect: .trainCapacity, effectPerLevel: 0.15, automationId: nil, glyph: .wagon),
        UpgradeConfig(id: "storage", title: "Big Warehousing",
                      detail: "+35% storage capacity per level.",
                      category: .logistics, baseCost: 1_200, costGrowth: 1.4, maxLevel: 25,
                      effect: .storage, effectPerLevel: 0.35, automationId: nil, glyph: .warehouse),

        // Economy
        UpgradeConfig(id: "coin_value", title: "Premium Tickets",
                      detail: "+22% coins from every delivery per level.",
                      category: .economy, baseCost: 800, costGrowth: 1.52, maxLevel: 30,
                      effect: .coinValue, effectPerLevel: 0.22, automationId: nil, glyph: .coin),
        UpgradeConfig(id: "boost_duration", title: "Longer Rushes",
                      detail: "+20% boost duration per level.",
                      category: .economy, baseCost: 3_000, costGrowth: 1.5, maxLevel: 10,
                      effect: .boostDuration, effectPerLevel: 0.2, automationId: nil, glyph: .bolt),
        UpgradeConfig(id: "offline_hours", title: "Night Watch",
                      detail: "+1 hour of offline earnings per level.",
                      category: .economy, baseCost: 10_000, costGrowth: 1.8, maxLevel: 8,
                      effect: .offlineHours, effectPerLevel: 1.0, automationId: nil, glyph: .moon),

        // Automation (one-time unlocks)
        UpgradeConfig(id: "auto_dispatch", title: "Auto-Dispatch",
                      detail: "Trains loop and deliver automatically — no tapping needed.",
                      category: .automation, baseCost: 5_000, costGrowth: 1, maxLevel: 1,
                      effect: nil, effectPerLevel: 0, automationId: "autoDispatch", glyph: .gear),
        UpgradeConfig(id: "auto_foreman", title: "Mine Foreman",
                      detail: "Production keeps flowing at full rate while you're away.",
                      category: .automation, baseCost: 60_000, costGrowth: 1, maxLevel: 1,
                      effect: nil, effectPerLevel: 0, automationId: "autoForeman", glyph: .hand),
        UpgradeConfig(id: "auto_boost", title: "Smart Dispatcher",
                      detail: "Boosts auto-trigger the moment the meter is full.",
                      category: .automation, baseCost: 250_000, costGrowth: 1, maxLevel: 1,
                      effect: nil, effectPerLevel: 0, automationId: "autoBoost", glyph: .bolt),
    ]

    static func byCategory(_ c: UpgradeCategory) -> [UpgradeConfig] {
        all.filter { $0.category == c }
    }
    static func config(_ id: String) -> UpgradeConfig? { all.first { $0.id == id } }
}
