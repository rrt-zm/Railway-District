import SwiftUI

/// Manage and upgrade the buildings of the active district.
struct BuildScreen: View {
    let store: GameStore

    private var cfg: DistrictConfig? { Catalog.district(store.state.activeDistrictId) }

    var body: some View {
        ScreenScaffold(title: "Stations", subtitle: cfg?.name, glyph: .warehouse,
                       trailing: AnyView(CurrencyChip(glyph: .coin, value: store.state.coins,
                                                      tint: RD.Palette.coins, compact: true))) {
            ScrollView {
                VStack(spacing: RD.Space.md) {
                    DistrictSwitcher(store: store)
                    if let cfg, let district = store.state.district(cfg.id) {
                        ForEach(cfg.nodes) { nc in
                            if let node = district.node(nc.id) {
                                BuildingCard(store: store, district: cfg, node: nc, state: node)
                            }
                        }
                    }
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, RD.Space.md)
            }
        }
    }
}

/// Horizontal selector of unlocked districts.
struct DistrictSwitcher: View {
    let store: GameStore
    var body: some View {
        let unlocked = store.state.districts.filter { $0.unlocked }
        if unlocked.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RD.Space.sm) {
                    ForEach(unlocked) { d in
                        let cfg = Catalog.district(d.id)
                        let selected = d.id == store.state.activeDistrictId
                        Button { store.selectDistrict(d.id) } label: {
                            Text(cfg?.name ?? d.id)
                                .font(RD.Font.heavy(13))
                                .foregroundStyle(selected ? RD.Palette.ink : RD.Palette.textMid)
                                .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
                                .background(Capsule().fill(selected ? RD.Palette.brass : RD.Palette.panelLight))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct BuildingCard: View {
    let store: GameStore
    let district: DistrictConfig
    let node: NodeConfig
    let state: NodeState

    var body: some View {
        let now = Date()
        HStack(spacing: RD.Space.md) {
            ZStack {
                RoundedRectangle(cornerRadius: RD.Radius.md).fill(node.kind.color.opacity(0.18))
                    .frame(width: 58, height: 58)
                PixelIcon(glyph: node.kind.glyph, size: 40)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: RD.Space.xs) {
                    Text(node.name).font(RD.Font.heavy(16)).foregroundStyle(RD.Palette.textHi)
                    if state.built { PixelBadge(text: "Lv \(state.level)", tint: node.kind.color) }
                }
                Text(effectText(now: now)).font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textMid)
                    .lineLimit(2)
            }
            Spacer(minLength: RD.Space.sm)

            actionButton
        }
        .pixelPanel(fill: RD.Palette.panel)
    }

    private func effectText(now: Date) -> String {
        if !state.built { return node.kind.subtitle }
        if let kind = node.kind.produces {
            let rate = Economy.nodeProduction(state, config: node, store.state, now: now)
            return "Producing \(BigNumber.rate(rate)) of \(kind.title.lowercased())"
        }
        switch node.kind {
        case .signalTower: return "All trains +\(Int(Double(state.level) * Balance.signalSpeedPerLevel * 100))% speed"
        case .depot: return "All trains +\(Int(Double(state.level) * Balance.depotCapacityPerLevel * 100))% capacity"
        case .warehouse: return "Storage +\(BigNumber.format(Double(state.level) * Balance.warehouseStoragePerLevel))"
        default: return node.kind.subtitle
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if !state.built {
            let cost = Economy.buildCost(node, district: district)
            actionPill(title: "Build", cost: cost, kind: .primary) {
                _ = store.build(districtId: district.id, nodeId: node.id)
            }
        } else {
            let cost = Economy.upgradeCost(state, config: node, district: district)
            actionPill(title: "Upgrade", cost: cost, kind: .success) {
                _ = store.upgrade(districtId: district.id, nodeId: node.id)
            }
        }
    }

    private func actionPill(title: String, cost: Double, kind: RDButtonKind, action: @escaping () -> Void) -> some View {
        Button(action: { if store.canAfford(cost) { action() } else { Haptics.shared.warning() } }) {
            VStack(spacing: 1) {
                Text(title).font(RD.Font.heavy(13))
                HStack(spacing: 2) {
                    PixelIcon(glyph: .coin, size: 12)
                    Text(cost.bn).font(RD.Font.heavy(12))
                }
            }
            .foregroundStyle(store.canAfford(cost) ? kind.text : RD.Palette.textDim)
            .padding(.horizontal, RD.Space.md).padding(.vertical, RD.Space.sm)
            .frame(minWidth: 92)
            .background(RoundedRectangle(cornerRadius: RD.Radius.md)
                .fill(store.canAfford(cost) ? kind.fill : RD.Palette.panelLight))
            .overlay(RoundedRectangle(cornerRadius: RD.Radius.md)
                .strokeBorder(store.canAfford(cost) ? kind.stroke : RD.Palette.woodDark, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
