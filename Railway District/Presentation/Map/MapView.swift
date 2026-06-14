import SwiftUI

/// The interactive, continuously-animated district map — the heart of the game.
struct MapView: View {
    let store: GameStore
    @State private var inspectNodeId: String?

    private var district: DistrictState? { store.state.activeDistrict }
    private var cfg: DistrictConfig? { district.flatMap { Catalog.district($0.id) } }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // Continuously-redrawing pixel canvas.
                TimelineView(.animation) { timeline in
                    Canvas { ctx, canvasSize in
                        drawScene(ctx: ctx, size: canvasSize,
                                  date: timeline.date)
                    }
                }
                .drawingGroup(opaque: false)

                // Tap surface (generic production + drives trains).
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let p = CGPoint(x: value.location.x / size.width,
                                                y: value.location.y / size.height)
                                store.tap(at: p, nodeId: nil)
                            }
                    )

                // Node tap targets + labels.
                if let cfg {
                    ForEach(cfg.nodes) { nc in
                        nodeTarget(nc: nc, size: size)
                    }
                }

                // Juice overlays.
                EffectsOverlay(store: store, size: size)
                    .allowsHitTesting(false)
            }
        }
        .sheet(item: Binding(get: { inspectNodeId.map { IdentifiedString($0) } },
                             set: { inspectNodeId = $0?.value })) { wrapped in
            if let cfg, let nc = cfg.node(wrapped.value) {
                NodeInspectorSheet(store: store, district: cfg, node: nc)
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Node interaction

    @ViewBuilder
    private func nodeTarget(nc: NodeConfig, size: CGSize) -> some View {
        let center = CGPoint(x: nc.x * size.width, y: nc.y * size.height)
        let node = district?.node(nc.id)
        let built = node?.built ?? false
        VStack(spacing: 3) {
            Color.clear.frame(width: 54, height: 46)
            nodeLabel(nc: nc, node: node, built: built)
        }
        .position(x: center.x, y: center.y + 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if built, let kind = nc.kind.produces {
                store.tap(at: CGPoint(x: nc.x, y: nc.y), nodeId: nc.id)
            } else if built {
                store.tap(at: CGPoint(x: nc.x, y: nc.y), nodeId: nil)
            } else {
                inspectNodeId = nc.id
            }
        }
        .onLongPressGesture(minimumDuration: 0.25) {
            inspectNodeId = nc.id
        }
    }

    @ViewBuilder
    private func nodeLabel(nc: NodeConfig, node: NodeState?, built: Bool) -> some View {
        if built {
            Text("Lv \(node?.level ?? 1)")
                .font(RD.Font.heavy(10))
                .foregroundStyle(RD.Palette.ink)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(nc.kind.color.mix(.white, 0.2)))
        } else {
            let cost = cfg.map { Economy.buildCost(nc, district: $0) } ?? nc.buildCost
            HStack(spacing: 2) {
                PixelIcon(glyph: .coin, size: 11)
                Text(cost.bn).font(RD.Font.heavy(10))
                    .foregroundStyle(store.canAfford(cost) ? RD.Palette.textHi : RD.Palette.textDim)
            }
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(RD.Palette.panel.opacity(0.92)))
            .overlay(Capsule().strokeBorder(store.canAfford(cost) ? RD.Palette.brass : RD.Palette.woodDark, lineWidth: 1))
        }
    }

    // MARK: - Scene drawing

    private func drawScene(ctx: GraphicsContext, size: CGSize, date: Date) {
        guard let cfg, let district else { return }
        let theme = cfg.theme
        let t = date.timeIntervalSince1970
        let dayT = (t / 90).truncatingRemainder(dividingBy: 1) // 90s day/night cycle

        MapRenderer.drawSky(ctx: ctx, size: size, theme: theme, dayT: dayT)
        MapRenderer.drawGround(ctx: ctx, size: size, theme: theme)
        MapRenderer.drawDecorations(ctx: ctx, size: size, theme: theme, t: t)

        // Track.
        let points = cfg.trackPath.compactMap { id in
            cfg.node(id).map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
        }
        let track = TrackGeometry(points: points)
        MapRenderer.drawTrack(ctx: ctx, path: track.path)

        // Buildings.
        for nc in cfg.nodes {
            let node = district.node(nc.id)
            let center = CGPoint(x: nc.x * size.width, y: nc.y * size.height)
            MapRenderer.drawBuilding(ctx: ctx, center: center, kind: nc.kind,
                                     built: node?.built ?? false, t: t)
        }

        // Trains.
        let autoDispatch = store.state.automation.contains("autoDispatch")
        for train in district.trains {
            let pos = track.point(atFraction: CGFloat(train.phase))
            MapRenderer.drawTrain(ctx: ctx, center: pos, kind: train.kind, t: t,
                                  moving: autoDispatch)
        }
    }
}

/// Wrapper so an optional String can drive a `.sheet(item:)`.
struct IdentifiedString: Identifiable {
    let value: String
    var id: String { value }
    init(_ v: String) { value = v }
}
