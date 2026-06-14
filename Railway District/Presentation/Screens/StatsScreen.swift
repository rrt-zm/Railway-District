import SwiftUI

/// Lifetime and session statistics with a custom production chart.
struct StatsScreen: View {
    let store: GameStore

    var body: some View {
        let s = store.state
        let st = s.stats
        let prod = Economy.totalProduction(s, now: Date())

        ScreenScaffold(title: "Statistics", subtitle: "Lifetime railway record", glyph: .signal) {
            ScrollView {
                VStack(spacing: RD.Space.md) {
                    ProductionChart(production: prod)

                    statGrid(st: st, s: s)

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, RD.Space.md)
            }
        }
    }

    private func statGrid(st: Stats, s: GameState) -> some View {
        let items: [(PixelGlyph, String, String)] = [
            (.hand, "Total taps", BigNumber.format(st.totalTaps, decimals: 0)),
            (.coin, "Lifetime coins", st.totalCoinsEarned.bn),
            (.train, "Deliveries", BigNumber.format(st.trainsDispatched, decimals: 0)),
            (.signal, "Distance", "\(st.distanceTraveled.bn) u"),
            (.warehouse, "Buildings built", BigNumber.format(st.buildingsBuilt, decimals: 0)),
            (.gear, "Upgrades", BigNumber.format(st.buildingsUpgraded, decimals: 0)),
            (.map, "Districts", "\(Int(metricDistricts(s)))/\(Catalog.districts.count)"),
            (.blueprint, "Blueprints", s.blueprints.bn),
            (.star, "Prestiges", BigNumber.format(st.prestigeCount, decimals: 0)),
            (.bolt, "Boosts used", BigNumber.format(st.boostsUsed, decimals: 0)),
            (.crate, "Resources made", st.totalResourcesProduced.bn),
            (.moon, "Time played", TimeFormat.duration(st.timePlayed)),
        ]
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: RD.Space.md),
                                   GridItem(.flexible(), spacing: RD.Space.md)], spacing: RD.Space.md) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: RD.Space.sm) {
                    PixelIcon(glyph: item.0, size: 24)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.2).font(RD.Font.heavy(15)).foregroundStyle(RD.Palette.textHi)
                            .lineLimit(1).minimumScaleFactor(0.6)
                        Text(item.1).font(RD.Font.medium(10)).foregroundStyle(RD.Palette.textMid)
                    }
                    Spacer(minLength: 0)
                }
                .pixelPanel(fill: RD.Palette.panel, padding: RD.Space.sm)
            }
        }
    }

    private func metricDistricts(_ s: GameState) -> Double {
        Double(s.districts.filter { $0.unlocked }.count)
    }
}

/// Custom-drawn bar chart of current production per resource.
struct ProductionChart: View {
    let production: ResourceBundle

    var body: some View {
        let values = ResourceKind.allCases.map { ($0, production[$0]) }
        let maxVal = max(values.map { $0.1 }.max() ?? 1, 0.0001)

        VStack(alignment: .leading, spacing: RD.Space.sm) {
            SectionHeader("Production / sec", glyph: .bolt)
            HStack(alignment: .bottom, spacing: RD.Space.md) {
                ForEach(values, id: \.0) { kind, value in
                    VStack(spacing: 4) {
                        Text(value.bn).font(RD.Font.heavy(10)).foregroundStyle(RD.Palette.textHi)
                            .lineLimit(1).minimumScaleFactor(0.5)
                        GeometryReader { geo in
                            let h = max(4, CGFloat(value / maxVal) * geo.size.height)
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(colors: [kind.color, kind.color.mix(.white, 0.3)],
                                                         startPoint: .bottom, endPoint: .top))
                                    .frame(height: h)
                                    .animation(RD.Anim.smooth, value: h)
                            }
                        }
                        PixelIcon(glyph: kind.glyph, size: 18)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130)
        }
        .pixelPanel(fill: RD.Palette.panel)
    }
}
