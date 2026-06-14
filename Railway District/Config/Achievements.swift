import Foundation

struct AchievementConfig: Identifiable {
    let id: String
    let title: String
    let detail: String
    let metric: ProgressMetric
    let target: Double
    let glyph: PixelGlyph
}

enum AchievementCatalogue {
    static let all: [AchievementConfig] = [
        AchievementConfig(id: "a_tap_100", title: "Warm-Up", detail: "Tap 100 times.", metric: .totalTaps, target: 100, glyph: .hand),
        AchievementConfig(id: "a_tap_1k", title: "Trigger Finger", detail: "Tap 1,000 times.", metric: .totalTaps, target: 1_000, glyph: .hand),
        AchievementConfig(id: "a_tap_10k", title: "Tap Machine", detail: "Tap 10,000 times.", metric: .totalTaps, target: 10_000, glyph: .hand),

        AchievementConfig(id: "a_build_5", title: "Founder", detail: "Build 5 buildings.", metric: .buildingsBuilt, target: 5, glyph: .platform),
        AchievementConfig(id: "a_build_15", title: "Developer", detail: "Build 15 buildings.", metric: .buildingsBuilt, target: 15, glyph: .warehouse),
        AchievementConfig(id: "a_build_30", title: "City Planner", detail: "Build 30 buildings.", metric: .buildingsBuilt, target: 30, glyph: .map),

        AchievementConfig(id: "a_up_50", title: "Tinkerer", detail: "Upgrade 50 times.", metric: .buildingsUpgraded, target: 50, glyph: .gear),
        AchievementConfig(id: "a_up_250", title: "Engineer", detail: "Upgrade 250 times.", metric: .buildingsUpgraded, target: 250, glyph: .gear),

        AchievementConfig(id: "a_disp_100", title: "Conductor", detail: "Dispatch 100 deliveries.", metric: .trainsDispatched, target: 100, glyph: .train),
        AchievementConfig(id: "a_disp_2k", title: "Stationmaster", detail: "Dispatch 2,000 deliveries.", metric: .trainsDispatched, target: 2_000, glyph: .train),
        AchievementConfig(id: "a_disp_50k", title: "Railway Baron", detail: "Dispatch 50,000 deliveries.", metric: .trainsDispatched, target: 50_000, glyph: .train),

        AchievementConfig(id: "a_coins_1m", title: "Millionaire", detail: "Earn 1M lifetime coins.", metric: .lifetimeCoins, target: 1_000_000, glyph: .coin),
        AchievementConfig(id: "a_coins_1b", title: "Billionaire", detail: "Earn 1B lifetime coins.", metric: .lifetimeCoins, target: 1_000_000_000, glyph: .coin),
        AchievementConfig(id: "a_coins_1t", title: "Tycoon", detail: "Earn 1T lifetime coins.", metric: .lifetimeCoins, target: 1_000_000_000_000, glyph: .coin),

        AchievementConfig(id: "a_dist_2", title: "Explorer", detail: "Unlock a 2nd district.", metric: .districtsUnlocked, target: 2, glyph: .map),
        AchievementConfig(id: "a_dist_5", title: "Network", detail: "Unlock all 5 districts.", metric: .districtsUnlocked, target: 5, glyph: .star),

        AchievementConfig(id: "a_prestige_1", title: "Fresh Start", detail: "Restructure once.", metric: .prestigeCount, target: 1, glyph: .star),
        AchievementConfig(id: "a_prestige_5", title: "Visionary", detail: "Restructure 5 times.", metric: .prestigeCount, target: 5, glyph: .star),

        AchievementConfig(id: "a_boost_25", title: "Adrenaline", detail: "Use 25 boosts.", metric: .boostsUsed, target: 25, glyph: .bolt),
        AchievementConfig(id: "a_dist_far", title: "Globetrotter", detail: "Travel 1M units.", metric: .distanceTraveled, target: 1_000_000, glyph: .signal),
    ]
}
