import SwiftUI

/// Top heads-up display: currencies, resources, production rate.
struct TopHUD: View {
    let store: GameStore

    var body: some View {
        let s = store.state
        let now = Date()
        let prod = Economy.totalProduction(s, now: now)
        let storage = Economy.storageCapacity(s)

        VStack(spacing: RD.Space.sm) {
            HStack(spacing: RD.Space.sm) {
                CurrencyChip(glyph: .coin, value: s.coins, tint: RD.Palette.coins)
                CurrencyChip(glyph: .blueprint, value: s.blueprints, tint: RD.Palette.blueprints)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Economy.estimatedCoinsPerSecond(s, now: now).bnRate)
                        .font(RD.Font.heavy(13)).foregroundStyle(RD.Palette.coins)
                    Text("income").font(RD.Font.medium(9)).foregroundStyle(RD.Palette.textDim)
                }
            }

            HStack(spacing: RD.Space.xs) {
                ForEach(ResourceKind.allCases) { kind in
                    resourceChip(kind: kind, amount: s.resources[kind],
                                 rate: prod[kind], storage: storage)
                }
            }
        }
        .padding(RD.Space.md)
        .background(
            RD.Palette.panel.opacity(0.94)
                .overlay(Rectangle().fill(RD.Palette.woodDark).frame(height: 2), alignment: .bottom)
        )
    }

    private func resourceChip(kind: ResourceKind, amount: Double, rate: Double, storage: Double) -> some View {
        let frac = storage > 0 ? min(1, amount / storage) : 0
        return VStack(spacing: 2) {
            HStack(spacing: 2) {
                PixelIcon(glyph: kind.glyph, size: 14)
                Text(amount.bn).font(RD.Font.heavy(11)).foregroundStyle(RD.Palette.textHi)
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
            }
            PixelProgressBar(progress: frac, tint: kind.color, height: 4, showStripes: false)
            Text(rate > 0 ? "+\(rate.bn)/s" : "—")
                .font(RD.Font.medium(8)).foregroundStyle(rate > 0 ? kind.color : RD.Palette.textDim)
        }
        .padding(.horizontal, 6).padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: RD.Radius.sm).fill(RD.Palette.panelLight))
        .overlay(RoundedRectangle(cornerRadius: RD.Radius.sm).strokeBorder(kind.color.opacity(0.35), lineWidth: 1))
    }
}

/// The boost meter + activation control.
struct BoostControl: View {
    let store: GameStore
    @State private var showPicker = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
            content(now: timeline.date)
        }
        .sheet(isPresented: $showPicker) {
            BoostPickerSheet(store: store) { showPicker = false }
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let boost = store.state.boost
        if let kind = boost.activeKind, boost.isActive(now: now) {
            let remaining = boost.remaining(now: now)
            HStack(spacing: RD.Space.sm) {
                PixelIcon(glyph: kind.glyph, size: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(kind.title).font(RD.Font.heavy(13)).foregroundStyle(RD.Palette.textHi)
                    Text(kind.detail).font(RD.Font.medium(9)).foregroundStyle(RD.Palette.textMid)
                }
                Spacer()
                Text(TimeFormat.compact(remaining))
                    .font(RD.Font.mono(15)).foregroundStyle(RD.Palette.coins)
            }
            .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
            .background(
                Capsule().fill(RD.Palette.panel)
                    .overlay(Capsule().strokeBorder(RD.Palette.accent, lineWidth: 2))
            )
        } else {
            let ready = boost.meter >= Balance.boostMeterFull
            Button {
                if ready { showPicker = true } else { Haptics.shared.select() }
            } label: {
                HStack(spacing: RD.Space.sm) {
                    PixelIcon(glyph: .bolt, size: 18)
                    Text(ready ? "Boost Ready — Tap!" : "Boost Meter")
                        .font(RD.Font.heavy(13)).foregroundStyle(RD.Palette.textHi)
                    Spacer()
                    if !ready {
                        Text("\(Int(boost.meter * 100))%")
                            .font(RD.Font.heavy(12)).foregroundStyle(RD.Palette.textMid)
                    }
                }
                .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                .background(
                    ZStack(alignment: .leading) {
                        Capsule().fill(RD.Palette.panel)
                        GeometryReader { g in
                            Capsule()
                                .fill(LinearGradient(colors: [RD.Palette.accent2, RD.Palette.accent],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: g.size.width * min(1, boost.meter))
                                .opacity(0.55)
                        }
                    }
                    .overlay(Capsule().strokeBorder(ready ? RD.Palette.coins : RD.Palette.woodDark,
                                                    lineWidth: ready ? 2.5 : 1.5))
                )
                .scaleEffect(ready ? 1.0 : 1.0)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Sheet to choose which self-earned boost to spend the full meter on.
struct BoostPickerSheet: View {
    let store: GameStore
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: RD.Space.md) {
            SectionHeader("Spend Your Boost", subtitle: "Pick a 30s power-up.", glyph: .bolt)
            ForEach(BoostKind.allCases, id: \.self) { kind in
                Button {
                    if store.triggerBoost(kind) { onDone() }
                } label: {
                    HStack(spacing: RD.Space.md) {
                        PixelIcon(glyph: kind.glyph, size: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.title).font(RD.Font.heavy(16)).foregroundStyle(RD.Palette.textHi)
                            Text(kind.detail).font(RD.Font.medium(12)).foregroundStyle(RD.Palette.textMid)
                        }
                        Spacer()
                        PixelIcon(glyph: .star, size: 18)
                    }
                    .pixelPanel(fill: RD.Palette.panelLight)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(RD.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RD.Palette.panel.ignoresSafeArea())
    }
}
