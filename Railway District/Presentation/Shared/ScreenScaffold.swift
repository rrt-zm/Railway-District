import SwiftUI

/// A subtly-animated pixel background reused by all non-map screens (never static).
struct RDScreenBackground: View {
    var tint: Color = RD.Palette.panel
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince1970
                ctx.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .linearGradient(Gradient(colors: [tint.mix(.black, 0.15), tint]),
                                               startPoint: .zero,
                                               endPoint: CGPoint(x: 0, y: size.height)))
                // Drifting pixel "tracks" in the background.
                for i in 0..<8 {
                    let y = size.height * CGFloat(i) / 8 + 12
                    let offset = CGFloat((t * (10 + Double(i) * 3)).truncatingRemainder(dividingBy: 40))
                    var x = -CGFloat(40) + offset
                    while x < size.width {
                        ctx.fill(Path(CGRect(x: x, y: y, width: 14, height: 3)),
                                 with: .color(Color.white.opacity(0.03)))
                        x += 40
                    }
                }
                // Faint drifting stars.
                for i in 0..<18 {
                    let fx = CGFloat((i * 71) % 100) / 100
                    let baseY = CGFloat((i * 47) % 100) / 100
                    let drift = CGFloat((t * 6).truncatingRemainder(dividingBy: Double(size.height)))
                    let y = (baseY * size.height + drift).truncatingRemainder(dividingBy: size.height)
                    ctx.fill(Path(ellipseIn: CGRect(x: fx * size.width, y: y, width: 2, height: 2)),
                             with: .color(Color.white.opacity(0.05)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Standard themed screen frame with a custom header (no system navigation chrome).
struct ScreenScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    var glyph: PixelGlyph?
    var trailing: AnyView?
    @ViewBuilder var content: () -> Content

    init(title: String, subtitle: String? = nil, glyph: PixelGlyph? = nil,
         trailing: AnyView? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.glyph = glyph
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        ZStack {
            RDScreenBackground()
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: RD.Space.sm) {
                    if let glyph { PixelIcon(glyph: glyph, size: 30) }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).font(RD.Font.display(24)).foregroundStyle(RD.Palette.textHi)
                        if let subtitle {
                            Text(subtitle).font(RD.Font.medium(12)).foregroundStyle(RD.Palette.textMid)
                        }
                    }
                    Spacer()
                    if let trailing { trailing }
                }
                .padding(.horizontal, RD.Space.lg)
                .padding(.top, RD.Space.sm)
                .padding(.bottom, RD.Space.md)

                content()
            }
        }
    }
}
