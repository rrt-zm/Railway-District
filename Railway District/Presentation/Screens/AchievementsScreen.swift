import SwiftUI

/// Achievement grid with progress and unlock state.
struct AchievementsScreen: View {
    let store: GameStore

    private let columns = [GridItem(.flexible(), spacing: RD.Space.md),
                           GridItem(.flexible(), spacing: RD.Space.md)]

    var body: some View {
        let unlockedCount = store.state.unlockedAchievements.count
        ScreenScaffold(title: "Achievements",
                       subtitle: "\(unlockedCount)/\(AchievementCatalogue.all.count) unlocked", glyph: .star) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: RD.Space.md) {
                    ForEach(AchievementCatalogue.all) { a in
                        AchievementCell(store: store, config: a)
                    }
                }
                .padding(.horizontal, RD.Space.md)
                Color.clear.frame(height: 90)
            }
        }
    }
}

struct AchievementCell: View {
    let store: GameStore
    let config: AchievementConfig

    var body: some View {
        let unlocked = store.achievementUnlocked(config)
        let value = store.metricValue(config.metric)
        let progress = min(1, value / config.target)

        VStack(spacing: RD.Space.sm) {
            ZStack {
                Circle().fill(unlocked ? RD.Palette.brass.opacity(0.25) : RD.Palette.panelLight)
                    .frame(width: 64, height: 64)
                if unlocked {
                    PixelProgressRing(progress: 1, tint: RD.Palette.brass, lineWidth: 4, size: 64)
                } else {
                    PixelProgressRing(progress: progress, tint: RD.Palette.textMid, lineWidth: 4, size: 64)
                }
                PixelIcon(glyph: config.glyph, size: 34)
                    .opacity(unlocked ? 1 : 0.4)
                    .grayscale(unlocked ? 0 : 0.9)
            }
            Text(config.title).font(RD.Font.heavy(13)).foregroundStyle(RD.Palette.textHi)
                .multilineTextAlignment(.center).lineLimit(1)
            Text(config.detail).font(RD.Font.medium(10)).foregroundStyle(RD.Palette.textMid)
                .multilineTextAlignment(.center).lineLimit(2).frame(height: 26, alignment: .top)
            if unlocked {
                PixelBadge(text: "UNLOCKED", tint: RD.Palette.success)
            } else {
                Text("\(Int(progress * 100))%").font(RD.Font.heavy(11)).foregroundStyle(RD.Palette.textMid)
            }
        }
        .frame(maxWidth: .infinity)
        .pixelPanel(fill: RD.Palette.panel)
    }
}
