import SwiftUI

/// Renders transient juice — floating numbers, tap particles and coin pops — over the map.
struct EffectsOverlay: View {
    let store: GameStore
    let size: CGSize

    var body: some View {
        TimelineView(.animation) { _ in
            ZStack(alignment: .topLeading) {
                ForEach(store.particles) { p in
                    particleView(p)
                }
                ForEach(store.coinPops) { c in
                    coinPopView(c)
                }
                ForEach(store.floatingTexts) { f in
                    floatingView(f)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }

    private func floatingView(_ f: FloatingText) -> some View {
        let age: CGFloat = CGFloat(store.clock - f.bornAt)
        let progress: CGFloat = min(1, age / 1.1)
        let x: CGFloat = f.point.x * size.width
        let y: CGFloat = f.point.y * size.height - progress * f.rise
        let pop: CGFloat = progress < 0.18 ? 0.7 + (progress / 0.18) * 0.4 : 1.0
        let fade: CGFloat = 1 - max(0, (progress - 0.5) / 0.5)
        return Text(f.text)
            .font(RD.Font.heavy(f.fontSize))
            .foregroundStyle(f.color)
            .shadow(color: .black.opacity(0.5), radius: 0, x: 1, y: 1)
            .scaleEffect(pop)
            .opacity(Double(fade))
            .position(x: x, y: y)
    }

    private func particleView(_ p: TapParticle) -> some View {
        let age: CGFloat = CGFloat(store.clock - p.bornAt)
        let progress: CGFloat = min(1, age / 0.8)
        let x: CGFloat = (p.point.x + p.velocity.dx * age) * size.width
        let y: CGFloat = (p.point.y + p.velocity.dy * age + 0.5 * age * age) * size.height
        return RoundedRectangle(cornerRadius: 1)
            .fill(p.color)
            .frame(width: p.size, height: p.size)
            .opacity(Double(1 - progress))
            .position(x: x, y: y)
    }

    private func coinPopView(_ c: CoinPop) -> some View {
        let age: CGFloat = CGFloat(store.clock - c.bornAt)
        let progress: CGFloat = min(1, age / 0.9)
        let x: CGFloat = c.point.x * size.width
        let y: CGFloat = c.point.y * size.height - progress * 30
        let scale: CGFloat = 0.6 + min(progress * 3, 1) * 0.6
        let fade: CGFloat = 1 - max(0, (progress - 0.5) / 0.5)
        return PixelIcon(glyph: .coin, size: 18)
            .scaleEffect(scale)
            .opacity(Double(fade))
            .position(x: x, y: y)
    }
}
