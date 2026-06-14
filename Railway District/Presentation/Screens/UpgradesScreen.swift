import SwiftUI

/// The global upgrade tree across production, logistics, economy and automation.
struct UpgradesScreen: View {
    let store: GameStore
    @State private var category: UpgradeCategory = .production

    var body: some View {
        ScreenScaffold(title: "Upgrades", subtitle: "Permanent network boosts", glyph: .gear,
                       trailing: AnyView(CurrencyChip(glyph: .coin, value: store.state.coins,
                                                      tint: RD.Palette.coins, compact: true))) {
            VStack(spacing: RD.Space.sm) {
                categoryTabs
                ScrollView {
                    VStack(spacing: RD.Space.md) {
                        ForEach(UpgradeCatalogue.byCategory(category)) { up in
                            UpgradeCard(store: store, config: up)
                        }
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, RD.Space.md)
                }
            }
        }
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RD.Space.sm) {
                ForEach(UpgradeCategory.allCases, id: \.self) { cat in
                    let selected = cat == category
                    Button { withAnimation(RD.Anim.snappy) { category = cat }; Haptics.shared.select() } label: {
                        HStack(spacing: RD.Space.xs) {
                            PixelIcon(glyph: cat.glyph, size: 16)
                            Text(cat.rawValue).font(RD.Font.heavy(13))
                                .foregroundStyle(selected ? RD.Palette.ink : RD.Palette.textMid)
                        }
                        .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                        .background(Capsule().fill(selected ? RD.Palette.brass : RD.Palette.panelLight))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, RD.Space.md)
        }
    }
}

struct UpgradeCard: View {
    let store: GameStore
    let config: UpgradeConfig

    var body: some View {
        let level = store.state.upgrades[config.id] ?? 0
        let maxed = level >= config.maxLevel
        let cost = config.cost(forLevel: level)
        let owned = config.isAutomation && level >= 1

        HStack(spacing: RD.Space.md) {
            ZStack {
                RoundedRectangle(cornerRadius: RD.Radius.md).fill(RD.Palette.panelLight)
                    .frame(width: 54, height: 54)
                PixelIcon(glyph: config.glyph, size: 36)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: RD.Space.xs) {
                    Text(config.title).font(RD.Font.heavy(15)).foregroundStyle(RD.Palette.textHi)
                    if !config.isAutomation {
                        PixelBadge(text: "Lv \(level)/\(config.maxLevel)", tint: RD.Palette.brass)
                    } else if owned {
                        PixelBadge(text: "OWNED", tint: RD.Palette.success)
                    }
                }
                Text(config.detail).font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textMid).lineLimit(2)
            }
            Spacer(minLength: RD.Space.sm)

            if maxed || owned {
                Text(owned ? "✓" : "MAX").font(RD.Font.heavy(14)).foregroundStyle(RD.Palette.success)
                    .frame(minWidth: 72)
            } else {
                Button(action: {
                    if store.canAfford(cost) { _ = store.buyUpgrade(config.id) } else { Haptics.shared.warning() }
                }) {
                    VStack(spacing: 1) {
                        Text(config.isAutomation ? "Unlock" : "Buy").font(RD.Font.heavy(13))
                        HStack(spacing: 2) {
                            PixelIcon(glyph: .coin, size: 11)
                            Text(cost.bn).font(RD.Font.heavy(12))
                        }
                    }
                    .foregroundStyle(store.canAfford(cost) ? RD.Palette.ink : RD.Palette.textDim)
                    .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                    .frame(minWidth: 80)
                    .background(RoundedRectangle(cornerRadius: RD.Radius.md)
                        .fill(store.canAfford(cost) ? RD.Palette.brass : RD.Palette.panelLight))
                }
                .buttonStyle(.plain)
            }
        }
        .pixelPanel(fill: RD.Palette.panel)
    }
}
