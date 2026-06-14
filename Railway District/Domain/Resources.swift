import SwiftUI

/// The four production resources that feed the railway economy.
enum ResourceKind: String, Codable, CaseIterable, Identifiable {
    case coal, steel, passengers, cargo
    var id: String { rawValue }

    var title: String {
        switch self {
        case .coal: return "Coal"
        case .steel: return "Steel"
        case .passengers: return "Passengers"
        case .cargo: return "Cargo"
        }
    }

    /// Coins earned per unit when delivered by a train (before district & upgrade multipliers).
    var baseValue: Double {
        switch self {
        case .coal: return 1.0
        case .steel: return 4.5
        case .passengers: return 3.0
        case .cargo: return 8.0
        }
    }

    var color: Color {
        switch self {
        case .coal: return RD.Palette.coal
        case .steel: return RD.Palette.steel
        case .passengers: return RD.Palette.passengers
        case .cargo: return RD.Palette.cargo
        }
    }

    /// Symbol used by the pixel-icon drawer.
    var glyph: PixelGlyph {
        switch self {
        case .coal: return .coal
        case .steel: return .steel
        case .passengers: return .passenger
        case .cargo: return .crate
        }
    }
}

/// Currencies that are not "produced" but earned through delivery and prestige.
enum Currency {
    static let coinsColor = RD.Palette.coins
    static let blueprintsColor = RD.Palette.blueprints
}

/// A bundle of all four resources. Used for storage, production rates and offline gains.
struct ResourceBundle: Codable, Equatable {
    var coal: Double = 0
    var steel: Double = 0
    var passengers: Double = 0
    var cargo: Double = 0

    subscript(_ kind: ResourceKind) -> Double {
        get {
            switch kind {
            case .coal: return coal
            case .steel: return steel
            case .passengers: return passengers
            case .cargo: return cargo
            }
        }
        set {
            switch kind {
            case .coal: coal = newValue
            case .steel: steel = newValue
            case .passengers: passengers = newValue
            case .cargo: cargo = newValue
            }
        }
    }

    var total: Double { coal + steel + passengers + cargo }
    var isEmpty: Bool { total <= 0.0001 }

    static func + (lhs: ResourceBundle, rhs: ResourceBundle) -> ResourceBundle {
        ResourceBundle(coal: lhs.coal + rhs.coal,
                       steel: lhs.steel + rhs.steel,
                       passengers: lhs.passengers + rhs.passengers,
                       cargo: lhs.cargo + rhs.cargo)
    }

    static func zero() -> ResourceBundle { ResourceBundle() }
}
