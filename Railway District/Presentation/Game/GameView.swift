import SwiftUI

/// The main play screen: the living map, HUD, boost control and the active quest.
struct GameView: View {
    let store: GameStore
    var goToQuests: () -> Void

    var body: some View {
        let shakeX = CGFloat(CoreGraphics.sin(store.clock * 53)) * store.screenShake
        let shakeY = CGFloat(CoreGraphics.cos(store.clock * 61)) * store.screenShake

        ZStack {
            RD.Palette.panel.ignoresSafeArea()

            MapView(store: store)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                TopHUD(store: store)
                Spacer()
                VStack(spacing: RD.Space.sm) {
                    QuestBanner(store: store, goToQuests: goToQuests)
                    BoostControl(store: store)
                }
                .padding(.horizontal, RD.Space.md)
                .padding(.bottom, RD.Space.sm)
            }
        }
        .offset(x: shakeX, y: shakeY)
    }
}

/// Compact active-quest tracker shown above the boost bar.
struct QuestBanner: View {
    let store: GameStore
    var goToQuests: () -> Void

    var body: some View {
        if let q = store.activeQuest {
            let value = store.metricValue(q.metric)
            let progress = min(1, value / q.target)
            let done = store.questCompleted(q)
            Button {
                if done { _ = store.claimQuest(q) } else { goToQuests() }
            } label: {
                HStack(spacing: RD.Space.sm) {
                    PixelIcon(glyph: q.glyph, size: 22)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(q.title).font(RD.Font.heavy(13)).foregroundStyle(RD.Palette.textHi)
                            Spacer()
                            Text("\(BigNumber.format(min(value, q.target), decimals: 0))/\(q.target.bn)")
                                .font(RD.Font.medium(10)).foregroundStyle(RD.Palette.textMid)
                        }
                        PixelProgressBar(progress: progress,
                                         tint: done ? RD.Palette.success : RD.Palette.brass, height: 6)
                    }
                    if done {
                        PixelBadge(text: "CLAIM", tint: RD.Palette.success)
                    }
                }
                .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                .background(
                    RoundedRectangle(cornerRadius: RD.Radius.md).fill(RD.Palette.panel.opacity(0.94))
                        .overlay(RoundedRectangle(cornerRadius: RD.Radius.md)
                            .strokeBorder(done ? RD.Palette.success : RD.Palette.woodDark, lineWidth: 1.5))
                )
            }
            .buttonStyle(.plain)
        }
    }
}
