import SwiftUI

/// Steady stream of objectives with rewards.
struct QuestsScreen: View {
    let store: GameStore

    var body: some View {
        ScreenScaffold(title: "Quests", subtitle: "Objectives & rewards", glyph: .star) {
            ScrollView {
                VStack(spacing: RD.Space.md) {
                    ForEach(QuestCatalogue.all) { q in
                        QuestRow(store: store, quest: q)
                    }
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, RD.Space.md)
            }
        }
    }
}

struct QuestRow: View {
    let store: GameStore
    let quest: QuestConfig

    var body: some View {
        let value = store.metricValue(quest.metric)
        let progress = min(1, value / quest.target)
        let done = store.questCompleted(quest)
        let claimed = store.questClaimed(quest)

        HStack(spacing: RD.Space.md) {
            ZStack {
                RoundedRectangle(cornerRadius: RD.Radius.md)
                    .fill(claimed ? RD.Palette.success.opacity(0.18) : RD.Palette.panelLight)
                    .frame(width: 50, height: 50)
                PixelIcon(glyph: quest.glyph, size: 32)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(quest.title).font(RD.Font.heavy(15)).foregroundStyle(RD.Palette.textHi)
                    Spacer()
                    rewardLabel
                }
                Text(quest.detail).font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textMid).lineLimit(1)
                HStack(spacing: RD.Space.sm) {
                    PixelProgressBar(progress: progress,
                                     tint: claimed ? RD.Palette.success : RD.Palette.brass, height: 6)
                    Text("\(BigNumber.format(min(value, quest.target), decimals: 0))/\(quest.target.bn)")
                        .font(RD.Font.medium(9)).foregroundStyle(RD.Palette.textMid).fixedSize()
                }
            }
            actionView(done: done, claimed: claimed)
        }
        .pixelPanel(fill: RD.Palette.panel)
        .opacity(claimed ? 0.7 : 1)
    }

    private var rewardLabel: some View {
        HStack(spacing: RD.Space.xs) {
            if quest.rewardCoins > 0 {
                HStack(spacing: 2) { PixelIcon(glyph: .coin, size: 11); Text(quest.rewardCoins.bn).font(RD.Font.heavy(10)) }
                    .foregroundStyle(RD.Palette.coins)
            }
            if quest.rewardBlueprints > 0 {
                HStack(spacing: 2) { PixelIcon(glyph: .blueprint, size: 11); Text(quest.rewardBlueprints.bn).font(RD.Font.heavy(10)) }
                    .foregroundStyle(RD.Palette.blueprints)
            }
        }
    }

    @ViewBuilder
    private func actionView(done: Bool, claimed: Bool) -> some View {
        if claimed {
            PixelIcon(glyph: .star, size: 22).opacity(0.6)
        } else if done {
            Button { _ = store.claimQuest(quest) } label: {
                Text("Claim").font(RD.Font.heavy(13)).foregroundStyle(RD.Palette.ink)
                    .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                    .background(Capsule().fill(RD.Palette.success))
            }
            .buttonStyle(.plain)
        } else {
            Text("\(Int(min(1, store.metricValue(quest.metric) / quest.target) * 100))%")
                .font(RD.Font.heavy(13)).foregroundStyle(RD.Palette.textMid).frame(width: 44)
        }
    }
}
