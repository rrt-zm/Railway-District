import SwiftUI

/// Building archetypes placed on the district map.
/// Production buildings emit a resource; booster buildings raise global multipliers.
enum BuildingKind: String, Codable, CaseIterable, Identifiable {
    case mine          // -> coal
    case foundry       // -> steel
    case platform      // -> passengers
    case warehouse     // -> cargo (and adds storage)
    case signalTower   // booster: train speed / route throughput
    case depot         // booster: train capacity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mine: return "Coal Mine"
        case .foundry: return "Foundry"
        case .platform: return "Platform"
        case .warehouse: return "Warehouse"
        case .signalTower: return "Signal Tower"
        case .depot: return "Depot"
        }
    }

    var subtitle: String {
        switch self {
        case .mine: return "Digs up coal"
        case .foundry: return "Smelts steel"
        case .platform: return "Boards passengers"
        case .warehouse: return "Packs cargo & adds storage"
        case .signalTower: return "Speeds up every train"
        case .depot: return "Boosts train capacity"
        }
    }

    /// Resource produced, or nil for boosters.
    var produces: ResourceKind? {
        switch self {
        case .mine: return .coal
        case .foundry: return .steel
        case .platform: return .passengers
        case .warehouse: return .cargo
        case .signalTower, .depot: return nil
        }
    }

    var isBooster: Bool { produces == nil }

    var color: Color {
        switch self {
        case .mine: return RD.Palette.coal
        case .foundry: return RD.Palette.cargo
        case .platform: return RD.Palette.passengers
        case .warehouse: return RD.Palette.woodLight
        case .signalTower: return RD.Palette.signalGreen
        case .depot: return RD.Palette.brass
        }
    }

    var glyph: PixelGlyph {
        switch self {
        case .mine: return .mine
        case .foundry: return .foundry
        case .platform: return .platform
        case .warehouse: return .warehouse
        case .signalTower: return .signal
        case .depot: return .depot
        }
    }
}

/// Train tiers — visual skin + base stat scaling. Unlocked by district / progression.
enum TrainKind: String, Codable, CaseIterable, Identifiable {
    case handcar
    case steamer
    case diesel
    case electric
    case bullet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .handcar: return "Handcar"
        case .steamer: return "Steam Engine"
        case .diesel: return "Diesel Loco"
        case .electric: return "Electric Unit"
        case .bullet: return "Bullet Train"
        }
    }

    /// Base capacity & speed scaling for the tier.
    var capacityMultiplier: Double {
        switch self {
        case .handcar: return 1
        case .steamer: return 3
        case .diesel: return 9
        case .electric: return 26
        case .bullet: return 70
        }
    }

    var speedMultiplier: Double {
        switch self {
        case .handcar: return 1
        case .steamer: return 1.35
        case .diesel: return 1.8
        case .electric: return 2.5
        case .bullet: return 3.6
        }
    }

    var bodyColor: Color {
        switch self {
        case .handcar: return RD.Palette.woodLight
        case .steamer: return RD.Palette.signalRed
        case .diesel: return RD.Palette.brass
        case .electric: return RD.Palette.passengers
        case .bullet: return RD.Palette.blueprints
        }
    }

    /// Cost in coins to purchase the first train of this tier in a district.
    var unlockCost: Double {
        switch self {
        case .handcar: return 0
        case .steamer: return 2_500
        case .diesel: return 180_000
        case .electric: return 9_000_000
        case .bullet: return 750_000_000
        }
    }
}
