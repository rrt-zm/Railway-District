import SwiftUI

/// Quick build/upgrade inspector for a single map node.
struct NodeInspectorSheet: View {
    let store: GameStore
    let district: DistrictConfig
    let node: NodeConfig
    @Environment(\.dismiss) private var dismiss

    private var state: NodeState? {
        store.state.district(district.id)?.node(node.id)
    }

    var body: some View {
        let built = state?.built ?? false
        let level = state?.level ?? 0

        VStack(alignment: .leading, spacing: RD.Space.lg) {
            HStack(spacing: RD.Space.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: RD.Radius.md)
                        .fill(node.kind.color.opacity(0.2))
                        .frame(width: 64, height: 64)
                    PixelIcon(glyph: node.kind.glyph, size: 44)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.name).font(RD.Font.heavy(22)).foregroundStyle(RD.Palette.textHi)
                    Text(node.kind.subtitle).font(RD.Font.medium(13)).foregroundStyle(RD.Palette.textMid)
                    if built { PixelBadge(text: "Level \(level)", tint: node.kind.color) }
                    else { PixelBadge(text: "Empty plot", tint: RD.Palette.woodLight) }
                }
                Spacer()
            }

            statsBlock(built: built, level: level)

            Spacer(minLength: 0)

            actionButton(built: built, level: level)
        }
        .padding(RD.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RD.Palette.panel.ignoresSafeArea())
    }

    @ViewBuilder
    private func statsBlock(built: Bool, level: Int) -> some View {
        VStack(spacing: RD.Space.sm) {
            if let kind = node.kind.produces {
                let rate = built ? Economy.nodeProduction(state!, config: node, store.state, now: Date()) : node.baseProduction
                statRow(label: built ? "Producing" : "Produces at Lv1",
                        value: BigNumber.rate(rate), color: kind.color)
                statRow(label: "Resource", value: kind.title, color: kind.color)
            } else if node.kind == .signalTower {
                statRow(label: "Train speed bonus",
                        value: "+\(Int(Double(level) * Balance.signalSpeedPerLevel * 100))%",
                        color: RD.Palette.signalGreen)
            } else if node.kind == .depot {
                statRow(label: "Train capacity bonus",
                        value: "+\(Int(Double(level) * Balance.depotCapacityPerLevel * 100))%",
                        color: RD.Palette.brass)
            } else if node.kind == .warehouse {
                statRow(label: "Adds storage", value: BigNumber.format(Double(level) * Balance.warehouseStoragePerLevel),
                        color: RD.Palette.woodLight)
            }
        }
        .pixelPanel(fill: RD.Palette.panelLight)
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label).font(RD.Font.medium(13)).foregroundStyle(RD.Palette.textMid)
            Spacer()
            Text(value).font(RD.Font.heavy(15)).foregroundStyle(color)
        }
    }

    @ViewBuilder
    private func actionButton(built: Bool, level: Int) -> some View {
        if !built {
            let cost = Economy.buildCost(node, district: district)
            RDButton(title: "Build  •  \(cost.bn)", glyph: .coin, kind: .primary,
                     disabled: !store.canAfford(cost)) {
                if store.build(districtId: district.id, nodeId: node.id) { dismiss() }
            }
        } else {
            let cost = Economy.upgradeCost(state!, config: node, district: district)
            VStack(spacing: RD.Space.sm) {
                RDButton(title: "Upgrade to Lv \(level + 1)  •  \(cost.bn)", glyph: .coin,
                         kind: .success, disabled: !store.canAfford(cost)) {
                    _ = store.upgrade(districtId: district.id, nodeId: node.id)
                }
                Text("Tap the building on the map to harvest by hand.")
                    .font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textDim)
            }
        }
    }
}
