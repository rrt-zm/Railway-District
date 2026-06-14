import SwiftUI

/// Buy, upgrade and automate the trains running the active district's loop.
struct TrainsScreen: View {
    let store: GameStore

    private var cfg: DistrictConfig? { Catalog.district(store.state.activeDistrictId) }

    var body: some View {
        ScreenScaffold(title: "Trains", subtitle: cfg?.name, glyph: .train,
                       trailing: AnyView(CurrencyChip(glyph: .coin, value: store.state.coins,
                                                      tint: RD.Palette.coins, compact: true))) {
            ScrollView {
                VStack(spacing: RD.Space.md) {
                    DistrictSwitcher(store: store)
                    automationCard
                    if let cfg, let district = store.state.district(cfg.id) {
                        SectionHeader("Fleet (\(district.trains.count)/\(Balance.maxTrainsPerDistrict))",
                                      subtitle: "Trains haul resources to coins.", glyph: .wagon)
                            .padding(.top, RD.Space.xs)
                        if district.trains.isEmpty {
                            PixelEmptyState(glyph: .train, title: "No trains yet",
                                            message: "Buy your first train below to start hauling.")
                        }
                        ForEach(district.trains) { t in
                            TrainCard(store: store, district: cfg, train: t)
                        }
                        SectionHeader("Buy a Train", glyph: .train).padding(.top, RD.Space.sm)
                        ForEach(cfg.trainKinds, id: \.self) { kind in
                            BuyTrainRow(store: store, district: cfg, kind: kind,
                                        existing: district.trains.count)
                        }
                    }
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, RD.Space.md)
            }
        }
    }

    private var automationCard: some View {
        let has = store.state.automation.contains("autoDispatch")
        return HStack(spacing: RD.Space.md) {
            PixelIcon(glyph: .gear, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(has ? "Auto-Dispatch Active" : "Manual Dispatch")
                    .font(RD.Font.heavy(15)).foregroundStyle(RD.Palette.textHi)
                Text(has ? "Trains loop automatically." : "Tap the map to push your trains around the loop.")
                    .font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textMid)
            }
            Spacer()
            PixelBadge(text: has ? "ON" : "OFF", tint: has ? RD.Palette.success : RD.Palette.woodLight)
        }
        .pixelPanel(fill: RD.Palette.panelLight)
    }
}

struct TrainCard: View {
    let store: GameStore
    let district: DistrictConfig
    let train: TrainState

    var body: some View {
        let now = Date()
        let dState = store.state.district(district.id)!
        let interval = Economy.trainInterval(train, district: dState, store.state, now: now)
        let capacity = Economy.trainCapacity(train, district: dState, store.state)
        let speedCost = Economy.trainSpeedUpgradeCost(train, district: district)
        let capCost = Economy.trainCapacityUpgradeCost(train, district: district)

        VStack(spacing: RD.Space.sm) {
            HStack(spacing: RD.Space.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: RD.Radius.md).fill(train.kind.bodyColor.opacity(0.2))
                        .frame(width: 54, height: 54)
                    PixelIcon(glyph: .train, size: 38)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(train.kind.title).font(RD.Font.heavy(16)).foregroundStyle(RD.Palette.textHi)
                    HStack(spacing: RD.Space.sm) {
                        Text("cap \(capacity.bn)").font(RD.Font.medium(11)).foregroundStyle(RD.Palette.cargo)
                        Text("\(BigNumber.format(interval, decimals: 1))s/loop")
                            .font(RD.Font.medium(11)).foregroundStyle(RD.Palette.passengers)
                    }
                }
                Spacer()
            }
            HStack(spacing: RD.Space.sm) {
                upgradePill(title: "Speed Lv\(train.speedLevel)", cost: speedCost) {
                    _ = store.upgradeTrainSpeed(districtId: district.id, trainId: train.id)
                }
                upgradePill(title: "Cargo Lv\(train.capacityLevel)", cost: capCost) {
                    _ = store.upgradeTrainCapacity(districtId: district.id, trainId: train.id)
                }
            }
        }
        .pixelPanel(fill: RD.Palette.panel)
    }

    private func upgradePill(title: String, cost: Double, action: @escaping () -> Void) -> some View {
        Button(action: { if store.canAfford(cost) { action() } else { Haptics.shared.warning() } }) {
            HStack(spacing: RD.Space.xs) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(RD.Font.heavy(12)).foregroundStyle(RD.Palette.textHi)
                    HStack(spacing: 2) {
                        PixelIcon(glyph: .coin, size: 11)
                        Text(cost.bn).font(RD.Font.medium(11))
                            .foregroundStyle(store.canAfford(cost) ? RD.Palette.coins : RD.Palette.textDim)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, RD.Space.sm).padding(.vertical, RD.Space.sm)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: RD.Radius.sm).fill(RD.Palette.panelLight))
            .overlay(RoundedRectangle(cornerRadius: RD.Radius.sm)
                .strokeBorder(store.canAfford(cost) ? RD.Palette.success : RD.Palette.woodDark, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct BuyTrainRow: View {
    let store: GameStore
    let district: DistrictConfig
    let kind: TrainKind
    let existing: Int

    var body: some View {
        let cost = Economy.trainBuyCost(kind: kind, district: district, existing: existing)
        let full = existing >= Balance.maxTrainsPerDistrict
        HStack(spacing: RD.Space.md) {
            PixelIcon(glyph: .train, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title).font(RD.Font.heavy(15)).foregroundStyle(RD.Palette.textHi)
                Text("Speed x\(BigNumber.format(kind.speedMultiplier, decimals: 1)) · Cap x\(BigNumber.format(kind.capacityMultiplier, decimals: 0))")
                    .font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textMid)
            }
            Spacer()
            Button(action: {
                if full { Haptics.shared.warning() }
                else if store.canAfford(cost) { _ = store.buyTrain(districtId: district.id, kind: kind) }
                else { Haptics.shared.warning() }
            }) {
                VStack(spacing: 1) {
                    Text(full ? "Full" : "Buy").font(RD.Font.heavy(13))
                    if !full {
                        HStack(spacing: 2) {
                            PixelIcon(glyph: .coin, size: 11)
                            Text(cost.bn).font(RD.Font.heavy(12))
                        }
                    }
                }
                .foregroundStyle(!full && store.canAfford(cost) ? RD.Palette.ink : RD.Palette.textDim)
                .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                .frame(minWidth: 84)
                .background(RoundedRectangle(cornerRadius: RD.Radius.md)
                    .fill(!full && store.canAfford(cost) ? RD.Palette.brass : RD.Palette.panelLight))
            }
            .buttonStyle(.plain)
        }
        .pixelPanel(fill: RD.Palette.panel)
    }
}
