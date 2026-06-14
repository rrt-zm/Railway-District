import Foundation

/// A measurable quantity used by quests & achievements.
enum ProgressMetric: String, Codable {
    case totalTaps
    case lifetimeCoins
    case currentCoins
    case trainsDispatched
    case buildingsBuilt
    case buildingsUpgraded
    case districtsUnlocked
    case prestigeCount
    case distanceTraveled
    case resourcesProduced
    case boostsUsed
    case trainsOwned
}

struct QuestConfig: Identifiable {
    let id: String
    let title: String
    let detail: String
    let metric: ProgressMetric
    let target: Double
    let rewardCoins: Double
    let rewardBlueprints: Double
    let glyph: PixelGlyph
}

enum QuestCatalogue {
    static let all: [QuestConfig] = [
        QuestConfig(id: "q1", title: "First Shift", detail: "Tap 25 times to get things moving.",
                    metric: .totalTaps, target: 25, rewardCoins: 120, rewardBlueprints: 0, glyph: .hand),
        QuestConfig(id: "q2", title: "Open the Pit", detail: "Build 1 building.",
                    metric: .buildingsBuilt, target: 1, rewardCoins: 200, rewardBlueprints: 0, glyph: .mine),
        QuestConfig(id: "q3", title: "On the Rails", detail: "Dispatch 10 train deliveries.",
                    metric: .trainsDispatched, target: 10, rewardCoins: 400, rewardBlueprints: 0, glyph: .train),
        QuestConfig(id: "q4", title: "Growing Yard", detail: "Build 4 buildings.",
                    metric: .buildingsBuilt, target: 4, rewardCoins: 1_500, rewardBlueprints: 0, glyph: .warehouse),
        QuestConfig(id: "q5", title: "Hard Worker", detail: "Tap 250 times.",
                    metric: .totalTaps, target: 250, rewardCoins: 2_500, rewardBlueprints: 0, glyph: .hand),
        QuestConfig(id: "q6", title: "Upgrade Spree", detail: "Upgrade buildings 15 times.",
                    metric: .buildingsUpgraded, target: 15, rewardCoins: 6_000, rewardBlueprints: 0, glyph: .gear),
        QuestConfig(id: "q7", title: "Busy Timetable", detail: "Dispatch 150 deliveries.",
                    metric: .trainsDispatched, target: 150, rewardCoins: 14_000, rewardBlueprints: 0, glyph: .train),
        QuestConfig(id: "q8", title: "New Horizons", detail: "Unlock the Industrial Zone.",
                    metric: .districtsUnlocked, target: 2, rewardCoins: 50_000, rewardBlueprints: 1, glyph: .map),
        QuestConfig(id: "q9", title: "Full Fleet", detail: "Own 4 trains at once.",
                    metric: .trainsOwned, target: 4, rewardCoins: 80_000, rewardBlueprints: 1, glyph: .wagon),
        QuestConfig(id: "q10", title: "Rush Manager", detail: "Use 5 boosts.",
                    metric: .boostsUsed, target: 5, rewardCoins: 120_000, rewardBlueprints: 1, glyph: .bolt),
        QuestConfig(id: "q11", title: "Long Hauler", detail: "Travel 50,000 units of track.",
                    metric: .distanceTraveled, target: 50_000, rewardCoins: 400_000, rewardBlueprints: 2, glyph: .signal),
        QuestConfig(id: "q12", title: "Coast to Coast", detail: "Unlock the Harbor.",
                    metric: .districtsUnlocked, target: 3, rewardCoins: 2_000_000, rewardBlueprints: 3, glyph: .map),
        QuestConfig(id: "q13", title: "Restructure", detail: "Prestige once to restructure the district.",
                    metric: .prestigeCount, target: 1, rewardCoins: 0, rewardBlueprints: 5, glyph: .star),
        QuestConfig(id: "q14", title: "Mountain Line", detail: "Unlock the Mountains.",
                    metric: .districtsUnlocked, target: 4, rewardCoins: 200_000_000, rewardBlueprints: 8, glyph: .map),
        QuestConfig(id: "q15", title: "Empire", detail: "Unlock the Metro Line.",
                    metric: .districtsUnlocked, target: 5, rewardCoins: 50_000_000_000, rewardBlueprints: 20, glyph: .star),
        QuestConfig(id: "q16", title: "Marathon", detail: "Dispatch 10,000 deliveries.",
                    metric: .trainsDispatched, target: 10_000, rewardCoins: 5_000_000, rewardBlueprints: 4, glyph: .train),
    ]
}
