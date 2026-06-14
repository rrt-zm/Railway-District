import SwiftUI

/// Illustrated, interactive first-run tutorial. Persisted; replayable from settings.
struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var step = 0

    private struct Page {
        let glyph: PixelGlyph
        let title: String
        let body: String
        let accent: Color
    }

    private let pages: [Page] = [
        Page(glyph: .hand, title: "Welcome to Railway District",
             body: "You've inherited a sleepy little depot. Tap anywhere on the map to crank out resources and push your trains around the loop.",
             accent: RD.Palette.accent),
        Page(glyph: .warehouse, title: "Build Your Stations",
             body: "Open Stations to build mines, foundries, platforms and warehouses. Each one produces a resource and can be upgraded through many levels.",
             accent: RD.Palette.woodLight),
        Page(glyph: .train, title: "Run the Trains",
             body: "Trains haul your resources and turn them into coins every loop. Buy more trains, upgrade their speed and cargo, and watch the network come alive.",
             accent: RD.Palette.signalRed),
        Page(glyph: .gear, title: "Automate Everything",
             body: "Unlock Auto-Dispatch so trains loop on their own, then buy upgrades and managers. Soon the whole railway runs itself while you plan your next district.",
             accent: RD.Palette.success),
        Page(glyph: .star, title: "Grow & Restructure",
             body: "Unlock new districts, complete quests, earn achievements, and Restructure to gain permanent blueprints. There's always another track to lay!",
             accent: RD.Palette.blueprints),
    ]

    var body: some View {
        ZStack {
            RDScreenBackground(tint: RD.Palette.panel)
            VStack(spacing: RD.Space.xl) {
                Spacer()
                illustration(page: pages[step])
                VStack(spacing: RD.Space.md) {
                    Text(pages[step].title)
                        .font(RD.Font.display(26)).foregroundStyle(RD.Palette.textHi)
                        .multilineTextAlignment(.center)
                    Text(pages[step].body)
                        .font(RD.Font.medium(14)).foregroundStyle(RD.Palette.textMid)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                }
                .padding(.horizontal, RD.Space.xl)

                Spacer()

                progressDots
                HStack(spacing: RD.Space.md) {
                    if step > 0 {
                        RDButton(title: "Back", kind: .secondary) {
                            withAnimation(RD.Anim.snappy) { step -= 1 }
                        }
                    }
                    RDButton(title: step == pages.count - 1 ? "Start Playing" : "Next",
                             glyph: step == pages.count - 1 ? .train : nil, kind: .primary) {
                        if step == pages.count - 1 { onFinish() }
                        else { withAnimation(RD.Anim.snappy) { step += 1 } }
                    }
                }
                .padding(.horizontal, RD.Space.xl)
                .padding(.bottom, RD.Space.xl)
            }
        }
        .transition(.opacity)
    }

    private func illustration(page: Page) -> some View {
        ZStack {
            Circle().fill(page.accent.opacity(0.18)).frame(width: 180, height: 180)
            Circle().strokeBorder(page.accent.opacity(0.4), lineWidth: 3).frame(width: 180, height: 180)
            PixelIcon(glyph: page.glyph, size: 110)
        }
        .scaleEffect(1)
        .id(step)
        .transition(.scale.combined(with: .opacity))
        .animation(RD.Anim.bouncy, value: step)
    }

    private var progressDots: some View {
        HStack(spacing: RD.Space.sm) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == step ? RD.Palette.brass : RD.Palette.panelLight)
                    .frame(width: i == step ? 22 : 8, height: 8)
                    .animation(RD.Anim.snappy, value: step)
            }
        }
    }
}
