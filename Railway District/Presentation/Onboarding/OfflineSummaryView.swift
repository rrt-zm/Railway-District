import SwiftUI

/// "While You Were Away" — offline earnings summary shown on relaunch.
struct OfflineSummaryView: View {
    let report: OfflineReport
    var onCollect: () -> Void
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: RD.Space.lg) {
                VStack(spacing: RD.Space.sm) {
                    PixelIcon(glyph: .moon, size: 56)
                    Text("While You Were Away")
                        .font(RD.Font.display(22)).foregroundStyle(RD.Palette.textHi)
                    Text("Your railway kept running for \(TimeFormat.duration(report.duration)).")
                        .font(RD.Font.medium(13)).foregroundStyle(RD.Palette.textMid)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: RD.Space.sm) {
                    summaryRow(glyph: .coin, label: "Coins earned", value: report.coins.bn, color: RD.Palette.coins)
                    summaryRow(glyph: .train, label: "Deliveries", value: BigNumber.format(report.deliveries, decimals: 0), color: RD.Palette.passengers)
                    summaryRow(glyph: .crate, label: "Resources stocked", value: report.resourcesProduced.bn, color: RD.Palette.cargo)
                }
                .pixelPanel(fill: RD.Palette.panelLight)

                RDButton(title: "Collect", glyph: .coin, kind: .success) {
                    Haptics.shared.success()
                    onCollect()
                }
            }
            .padding(RD.Space.xl)
            .frame(maxWidth: 360)
            .pixelPanel(fill: RD.Palette.panel, padding: RD.Space.lg)
            .padding(RD.Space.xl)
            .scaleEffect(appear ? 1 : 0.85)
            .opacity(appear ? 1 : 0)
        }
        .onAppear { withAnimation(RD.Anim.bouncy) { appear = true } }
    }

    private func summaryRow(glyph: PixelGlyph, label: String, value: String, color: Color) -> some View {
        HStack(spacing: RD.Space.md) {
            PixelIcon(glyph: glyph, size: 26)
            Text(label).font(RD.Font.medium(13)).foregroundStyle(RD.Palette.textMid)
            Spacer()
            Text(value).font(RD.Font.heavy(17)).foregroundStyle(color)
        }
    }
}
