import SwiftUI

/// "Restructure the District" — the prestige loop.
struct PrestigeScreen: View {
    let store: GameStore
    @State private var confirming = false

    var body: some View {
        let s = store.state
        let available = Economy.prestigeAvailable(s)
        let canPrestige = Economy.canPrestige(s)
        let bonus = Int((Economy.blueprintMultiplier(s) - 1) * 100)

        ScreenScaffold(title: "Restructure", subtitle: "Prestige for permanent power", glyph: .star) {
            ScrollView {
                VStack(spacing: RD.Space.lg) {
                    blueprintHero(current: s.blueprints, available: available, bonus: bonus)

                    infoPanel(
                        title: "What you gain",
                        rows: [("Blueprints", "+\(available.bn)", RD.Palette.blueprints),
                               ("Permanent production", "+\(Int(Balance.blueprintProductionBonus * 100))% each", RD.Palette.success)],
                        glyph: .blueprint)

                    infoPanel(
                        title: "What resets",
                        rows: [("Coins & resources", "reset", RD.Palette.danger),
                               ("Buildings & trains", "reset", RD.Palette.danger),
                               ("Coin upgrades & automation", "reset", RD.Palette.danger),
                               ("Districts", "back to Old Town", RD.Palette.warning)],
                        glyph: .gear)

                    infoPanel(
                        title: "What you keep",
                        rows: [("Blueprints (forever)", "kept", RD.Palette.success),
                               ("Achievements & quests", "kept", RD.Palette.success),
                               ("Lifetime stats", "kept", RD.Palette.success)],
                        glyph: .star)

                    if !canPrestige {
                        Text("Earn at least \(Balance.prestigeUnlockLifetimeCoins.bn) lifetime coins and enough progress for 1+ blueprint to restructure.")
                            .font(RD.Font.medium(12)).foregroundStyle(RD.Palette.textMid)
                            .multilineTextAlignment(.center)
                    }

                    RDButton(title: canPrestige ? "Restructure for \(available.bn) Blueprints" : "Not ready yet",
                             glyph: .star, kind: canPrestige ? .danger : .secondary,
                             disabled: !canPrestige) {
                        confirming = true
                    }
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, RD.Space.md)
            }
        }
        .overlay { if store.prestigeFlash { PrestigeFlash { store.prestigeFlash = false } } }
        .alert("Restructure the District?", isPresented: $confirming) {
            Button("Cancel", role: .cancel) {}
            Button("Restructure", role: .destructive) { _ = store.prestige() }
        } message: {
            Text("This resets your current economy but grants \(available.bn) blueprints permanently.")
        }
    }

    private func blueprintHero(current: Double, available: Double, bonus: Int) -> some View {
        VStack(spacing: RD.Space.sm) {
            PixelIcon(glyph: .blueprint, size: 60)
            HStack(spacing: RD.Space.sm) {
                Text("\(current.bn)").font(RD.Font.display(34)).foregroundStyle(RD.Palette.blueprints)
                Text("blueprints").font(RD.Font.heavy(15)).foregroundStyle(RD.Palette.textMid)
            }
            Text("Current bonus: +\(bonus)% to all production")
                .font(RD.Font.heavy(13)).foregroundStyle(RD.Palette.success)
        }
        .frame(maxWidth: .infinity)
        .pixelPanel(fill: RD.Palette.panel)
    }

    private func infoPanel(title: String, rows: [(String, String, Color)], glyph: PixelGlyph) -> some View {
        VStack(alignment: .leading, spacing: RD.Space.sm) {
            SectionHeader(title, glyph: glyph)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0).font(RD.Font.medium(13)).foregroundStyle(RD.Palette.textMid)
                    Spacer()
                    Text(row.1).font(RD.Font.heavy(13)).foregroundStyle(row.2)
                }
            }
        }
        .pixelPanel(fill: RD.Palette.panel)
    }
}

/// Full-screen "rebuild" flash sequence shown after prestige.
struct PrestigeFlash: View {
    var onDone: () -> Void
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            RD.Palette.blueprints.opacity(0.9).ignoresSafeArea()
            VStack(spacing: RD.Space.md) {
                PixelIcon(glyph: .star, size: 90).scaleEffect(scale)
                Text("District Restructured!").font(RD.Font.display(26)).foregroundStyle(RD.Palette.ink)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { scale = 1.1 }
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onDone() }
        }
    }
}
