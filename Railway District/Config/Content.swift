import SwiftUI

/// Static layout for a single building slot on a district map.
struct NodeConfig: Identifiable {
    let id: String
    let kind: BuildingKind
    let name: String
    let x: CGFloat            // normalized 0..1 within the map area
    let y: CGFloat
    let buildCost: Double     // coins to first build (in district currency, before district mult)
    let baseProduction: Double // per-second at level 1 (production buildings only)
}

/// Visual theme palette for a district.
struct DistrictTheme {
    let skyTop: Color
    let skyBottom: Color
    let ground: Color
    let groundDark: Color
    let accent: Color
    let hasWater: Bool
    let hasSnow: Bool
}

/// Static configuration for one district.
struct DistrictConfig: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let order: Int
    let unlockCostCoins: Double
    let unlockBlueprints: Double
    let resourceMultiplier: Double   // scales coin value of deliveries here
    let costMultiplier: Double       // scales all costs here
    let theme: DistrictTheme
    let trainKinds: [TrainKind]
    let nodes: [NodeConfig]
    /// Ordered node ids forming the closed track loop trains run along.
    let trackPath: [String]

    func node(_ id: String) -> NodeConfig? { nodes.first { $0.id == id } }
}

/// Master content catalogue. All districts, nodes and progression live here.
enum Catalog {

    /// A shared hexagon layout reused across districts for clean, readable maps.
    private static func hexNodes(districtId: String,
                                 costScale: Double,
                                 prodScale: Double,
                                 names: [BuildingKind: String]) -> [NodeConfig] {
        func n(_ kind: BuildingKind, _ x: CGFloat, _ y: CGFloat, _ cost: Double, _ prod: Double) -> NodeConfig {
            NodeConfig(id: "\(districtId).\(kind.rawValue)",
                       kind: kind,
                       name: names[kind] ?? kind.title,
                       x: x, y: y,
                       buildCost: cost * costScale,
                       baseProduction: prod * prodScale)
        }
        return [
            n(.platform,    0.50, 0.83, 60,     0.40),
            n(.mine,        0.17, 0.66, 15,     0.55),
            n(.warehouse,   0.17, 0.34, 260,    0.12),
            n(.signalTower, 0.50, 0.17, 4_000,  0),
            n(.foundry,     0.83, 0.34, 1_200,  0.16),
            n(.depot,       0.83, 0.66, 11_000, 0),
        ]
    }

    private static let loopOrder = ["platform", "mine", "warehouse", "signalTower", "foundry", "depot"]

    private static func track(_ districtId: String) -> [String] {
        loopOrder.map { "\(districtId).\($0)" }
    }

    static let districts: [DistrictConfig] = [
        DistrictConfig(
            id: "oldtown",
            name: "Old Town",
            tagline: "A sleepy depot where it all begins.",
            order: 0,
            unlockCostCoins: 0,
            unlockBlueprints: 0,
            resourceMultiplier: 1.0,
            costMultiplier: 1.0,
            theme: DistrictTheme(skyTop: Color(hex: 0x8FD3E8), skyBottom: Color(hex: 0xCDEBE0),
                                 ground: RD.Palette.grass, groundDark: RD.Palette.grassDark,
                                 accent: Color(hex: 0xF2A65A), hasWater: false, hasSnow: false),
            trainKinds: [.handcar, .steamer],
            nodes: hexNodes(districtId: "oldtown", costScale: 1, prodScale: 1,
                            names: [.platform: "Town Station", .mine: "Old Pit",
                                    .warehouse: "Goods Shed", .signalTower: "Clock Signal",
                                    .foundry: "Smithy", .depot: "Wooden Depot"]),
            trackPath: track("oldtown")
        ),
        DistrictConfig(
            id: "industrial",
            name: "Industrial Zone",
            tagline: "Smokestacks, steel and steam.",
            order: 1,
            unlockCostCoins: 250_000,
            unlockBlueprints: 0,
            resourceMultiplier: 6.0,
            costMultiplier: 12.0,
            theme: DistrictTheme(skyTop: Color(hex: 0x9A8FA8), skyBottom: Color(hex: 0xD8B98C),
                                 ground: Color(hex: 0x7C6E5A), groundDark: Color(hex: 0x5E5142),
                                 accent: RD.Palette.brass, hasWater: false, hasSnow: false),
            trainKinds: [.steamer, .diesel],
            nodes: hexNodes(districtId: "industrial", costScale: 30, prodScale: 7,
                            names: [.platform: "Works Halt", .mine: "Deep Seam",
                                    .warehouse: "Freight Yard", .signalTower: "Gantry Signal",
                                    .foundry: "Blast Furnace", .depot: "Engine Shed"]),
            trackPath: track("industrial")
        ),
        DistrictConfig(
            id: "harbor",
            name: "Harbor",
            tagline: "Salt air, cranes and cargo ships.",
            order: 2,
            unlockCostCoins: 40_000_000,
            unlockBlueprints: 3,
            resourceMultiplier: 42.0,
            costMultiplier: 140.0,
            theme: DistrictTheme(skyTop: Color(hex: 0x7EC4D6), skyBottom: Color(hex: 0xBFE8D2),
                                 ground: Color(hex: 0x6FA3A0), groundDark: Color(hex: 0x4E7C7A),
                                 accent: RD.Palette.water, hasWater: true, hasSnow: false),
            trainKinds: [.diesel, .electric],
            nodes: hexNodes(districtId: "harbor", costScale: 900, prodScale: 52,
                            names: [.platform: "Quay Station", .mine: "Dredge Works",
                                    .warehouse: "Container Stack", .signalTower: "Lighthouse Signal",
                                    .foundry: "Dock Foundry", .depot: "Marine Depot"]),
            trackPath: track("harbor")
        ),
        DistrictConfig(
            id: "mountains",
            name: "Mountains",
            tagline: "Switchbacks through the high snow.",
            order: 3,
            unlockCostCoins: 6_000_000_000,
            unlockBlueprints: 12,
            resourceMultiplier: 300.0,
            costMultiplier: 1_600.0,
            theme: DistrictTheme(skyTop: Color(hex: 0x6E84B8), skyBottom: Color(hex: 0xDCE6F2),
                                 ground: Color(hex: 0xE8EEF5), groundDark: Color(hex: 0xBCC6D6),
                                 accent: RD.Palette.passengers, hasWater: false, hasSnow: true),
            trainKinds: [.electric, .bullet],
            nodes: hexNodes(districtId: "mountains", costScale: 28_000, prodScale: 420,
                            names: [.platform: "Summit Halt", .mine: "Ore Tunnel",
                                    .warehouse: "Cold Store", .signalTower: "Peak Signal",
                                    .foundry: "Alpine Forge", .depot: "Rock Depot"]),
            trackPath: track("mountains")
        ),
        DistrictConfig(
            id: "metro",
            name: "Metro Line",
            tagline: "Neon tunnels and bullet speed.",
            order: 4,
            unlockCostCoins: 900_000_000_000,
            unlockBlueprints: 40,
            resourceMultiplier: 2_200.0,
            costMultiplier: 18_000.0,
            theme: DistrictTheme(skyTop: Color(hex: 0x2B2342), skyBottom: Color(hex: 0x52407A),
                                 ground: Color(hex: 0x3A3358), groundDark: Color(hex: 0x2A2444),
                                 accent: RD.Palette.blueprints, hasWater: false, hasSnow: false),
            trainKinds: [.electric, .bullet],
            nodes: hexNodes(districtId: "metro", costScale: 1_400_000, prodScale: 5_200,
                            names: [.platform: "Central Hub", .mine: "Geo Tap",
                                    .warehouse: "Auto Vault", .signalTower: "Laser Signal",
                                    .foundry: "Fusion Forge", .depot: "Mag Depot"]),
            trackPath: track("metro")
        ),
    ]

    static func district(_ id: String) -> DistrictConfig? { districts.first { $0.id == id } }
    static var first: DistrictConfig { districts[0] }
}
