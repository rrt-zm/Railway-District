import SwiftUI

/// Unlock and switch between the expanding city districts.
struct DistrictsScreen: View {
    let store: GameStore

    var body: some View {
        ScreenScaffold(title: "Districts", subtitle: "Expand your railway empire", glyph: .map,
                       trailing: AnyView(HStack(spacing: 6) {
                           CurrencyChip(glyph: .coin, value: store.state.coins, tint: RD.Palette.coins, compact: true)
                       })) {
            ScrollView {
                VStack(spacing: RD.Space.md) {
                    ForEach(Catalog.districts) { cfg in
                        DistrictCard(store: store, cfg: cfg)
                    }
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, RD.Space.md)
            }
        }
    }
}

struct DistrictCard: View {
    let store: GameStore
    let cfg: DistrictConfig

    var body: some View {
        let dState = store.state.district(cfg.id)
        let unlocked = dState?.unlocked ?? false
        let active = store.state.activeDistrictId == cfg.id
        let canUnlock = store.canUnlock(cfg.id)

        VStack(spacing: 0) {
            themePreview
                .frame(height: 96)
                .clipShape(RoundedRectangle(cornerRadius: RD.Radius.md))
                .overlay(alignment: .topTrailing) {
                    if active { PixelBadge(text: "ACTIVE", tint: RD.Palette.success).padding(8) }
                    else if unlocked { PixelBadge(text: "UNLOCKED", tint: RD.Palette.brass).padding(8) }
                    else { PixelBadge(text: "LOCKED", tint: RD.Palette.woodLight).padding(8) }
                }

            HStack(alignment: .top, spacing: RD.Space.md) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(cfg.name).font(RD.Font.heavy(18)).foregroundStyle(RD.Palette.textHi)
                    Text(cfg.tagline).font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textMid).lineLimit(2)
                    Text("Delivery value x\(BigNumber.format(cfg.resourceMultiplier, decimals: 0))")
                        .font(RD.Font.heavy(11)).foregroundStyle(cfg.theme.accent)
                }
                Spacer()
                actionArea(unlocked: unlocked, active: active, canUnlock: canUnlock)
            }
            .padding(.top, RD.Space.sm)
        }
        .pixelPanel(fill: RD.Palette.panel)
    }

    private var themePreview: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: [cfg.theme.skyTop, cfg.theme.skyBottom]),
                                           startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            let gy = size.height * 0.6
            ctx.fill(Path(CGRect(x: 0, y: gy, width: size.width, height: size.height - gy)),
                     with: .color(cfg.theme.ground))
            // A little track + train.
            let ty = gy + 16
            ctx.fill(Path(CGRect(x: 0, y: ty, width: size.width, height: 4)), with: .color(RD.Palette.rail))
            MapRenderer.drawTrain(ctx: ctx, center: CGPoint(x: size.width * 0.5, y: ty - 6),
                                  kind: cfg.trainKinds.first ?? .handcar, t: 0, moving: false)
            PixelArtLibrary.draw(PixelGlyph.platform.sprite, in: ctx,
                                 rect: CGRect(x: size.width * 0.18 - 16, y: ty - 34, width: 32, height: 32))
        }
    }

    @ViewBuilder
    private func actionArea(unlocked: Bool, active: Bool, canUnlock: Bool) -> some View {
        if unlocked {
            Button {
                store.selectDistrict(cfg.id)
            } label: {
                Text(active ? "Viewing" : "Visit").font(RD.Font.heavy(13))
                    .foregroundStyle(active ? RD.Palette.textDim : RD.Palette.ink)
                    .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                    .background(Capsule().fill(active ? RD.Palette.panelLight : RD.Palette.brass))
            }
            .buttonStyle(.plain)
            .disabled(active)
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 3) {
                    PixelIcon(glyph: .coin, size: 12)
                    Text(cfg.unlockCostCoins.bn).font(RD.Font.heavy(12))
                        .foregroundStyle(store.state.coins >= cfg.unlockCostCoins ? RD.Palette.coins : RD.Palette.textDim)
                }
                if cfg.unlockBlueprints > 0 {
                    HStack(spacing: 3) {
                        PixelIcon(glyph: .blueprint, size: 12)
                        Text(cfg.unlockBlueprints.bn).font(RD.Font.heavy(12))
                            .foregroundStyle(store.state.blueprints >= cfg.unlockBlueprints ? RD.Palette.blueprints : RD.Palette.textDim)
                    }
                }
                Button {
                    if canUnlock { _ = store.unlockDistrict(cfg.id) } else { Haptics.shared.warning() }
                } label: {
                    Text("Unlock").font(RD.Font.heavy(13))
                        .foregroundStyle(canUnlock ? RD.Palette.ink : RD.Palette.textDim)
                        .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                        .background(Capsule().fill(canUnlock ? RD.Palette.success : RD.Palette.panelLight))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
