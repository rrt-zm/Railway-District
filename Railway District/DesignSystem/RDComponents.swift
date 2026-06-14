import SwiftUI

// MARK: - Beveled panel (wood/metal chunky surface)

struct PixelPanel: ViewModifier {
    var fill: Color = RD.Palette.panel
    var stroke: Color = RD.Palette.woodDark
    var radius: CGFloat = RD.Radius.md
    var padding: CGFloat? = RD.Space.md

    func body(content: Content) -> some View {
        content
            .padding(padding ?? 0)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(fill)
                    // Top inner highlight.
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(colors: [Color.white.opacity(0.10), .clear],
                                           startPoint: .top, endPoint: .center)
                        )
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(stroke, lineWidth: 2)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
                    .blendMode(.multiply)
            )
    }
}

extension View {
    func pixelPanel(fill: Color = RD.Palette.panel,
                    stroke: Color = RD.Palette.woodDark,
                    radius: CGFloat = RD.Radius.md,
                    padding: CGFloat? = RD.Space.md) -> some View {
        modifier(PixelPanel(fill: fill, stroke: stroke, radius: radius, padding: padding))
    }
}

// MARK: - Game button

enum RDButtonKind {
    case primary, secondary, success, danger, ghost

    var fill: Color {
        switch self {
        case .primary: return RD.Palette.brass
        case .secondary: return RD.Palette.panelLight
        case .success: return RD.Palette.success
        case .danger: return RD.Palette.danger
        case .ghost: return Color.white.opacity(0.06)
        }
    }
    var stroke: Color {
        switch self {
        case .primary: return RD.Palette.brassDark
        case .secondary: return RD.Palette.woodDark
        case .success: return Color(hex: 0x3E8E4E)
        case .danger: return Color(hex: 0xB23B3B)
        case .ghost: return Color.white.opacity(0.15)
        }
    }
    var text: Color {
        switch self {
        case .primary: return RD.Palette.ink
        case .success: return RD.Palette.ink
        default: return RD.Palette.textHi
        }
    }
}

struct RDButtonStyle: ButtonStyle {
    var kind: RDButtonKind = .primary
    var disabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(RD.Font.heavy(16))
            .foregroundStyle(kind.text)
            .opacity(disabled ? 0.5 : 1)
            .padding(.horizontal, RD.Space.lg)
            .padding(.vertical, RD.Space.md)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: RD.Radius.md, style: .continuous)
                        .fill(kind.stroke)
                        .offset(y: pressed ? 0 : 3)
                    RoundedRectangle(cornerRadius: RD.Radius.md, style: .continuous)
                        .fill(kind.fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: RD.Radius.md, style: .continuous)
                                .fill(LinearGradient(colors: [Color.white.opacity(0.22), .clear],
                                                     startPoint: .top, endPoint: .center))
                        )
                        .offset(y: pressed ? 3 : 0)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: RD.Radius.md, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                    .offset(y: pressed ? 3 : 0)
            )
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(RD.Anim.pop, value: pressed)
    }
}

/// Convenience button with built-in label and pixel glyph.
struct RDButton: View {
    var title: String
    var glyph: PixelGlyph?
    var kind: RDButtonKind = .primary
    var disabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            guard !disabled else { Haptics.shared.warning(); return }
            action()
        }) {
            HStack(spacing: RD.Space.sm) {
                if let glyph { PixelIcon(glyph: glyph, size: 18) }
                Text(title)
            }
        }
        .buttonStyle(RDButtonStyle(kind: kind, disabled: disabled))
        .disabled(false) // keep tap to allow warning feedback
        .allowsHitTesting(true)
    }
}

// MARK: - Rolling number (odometer feel)

struct RollingNumber: View {
    var value: Double
    var font: Font = RD.Font.heavy(18)
    var color: Color = RD.Palette.textHi
    var prefix: String = ""

    var body: some View {
        Text(prefix + value.bn)
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: value))
            .animation(RD.Anim.smooth, value: value)
            .monospacedDigit()
    }
}

// MARK: - Resource / currency chip

struct CurrencyChip: View {
    var glyph: PixelGlyph
    var value: Double
    var tint: Color
    var compact: Bool = false

    var body: some View {
        HStack(spacing: RD.Space.xs) {
            PixelIcon(glyph: glyph, size: compact ? 16 : 20)
            RollingNumber(value: value, font: RD.Font.heavy(compact ? 13 : 16), color: RD.Palette.textHi)
        }
        .padding(.horizontal, RD.Space.sm + 2)
        .padding(.vertical, RD.Space.xs + 2)
        .background(
            Capsule(style: .continuous)
                .fill(RD.Palette.panel.opacity(0.92))
                .overlay(Capsule().strokeBorder(tint.opacity(0.55), lineWidth: 1.5))
        )
    }
}

// MARK: - Progress bar

struct PixelProgressBar: View {
    var progress: Double           // 0..1
    var tint: Color = RD.Palette.success
    var height: CGFloat = 12
    var showStripes: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(RD.Palette.panel.opacity(0.9))
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.mix(.white, 0.25)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
                    .animation(RD.Anim.smooth, value: progress)
            }
            .overlay(Capsule().strokeBorder(Color.black.opacity(0.25), lineWidth: 1))
        }
        .frame(height: height)
    }
}

// MARK: - Progress ring

struct PixelProgressRing: View {
    var progress: Double
    var tint: Color = RD.Palette.success
    var lineWidth: CGFloat = 7
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle().stroke(RD.Palette.panel, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(RD.Anim.smooth, value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    var title: String
    var subtitle: String?
    var glyph: PixelGlyph?

    init(_ title: String, subtitle: String? = nil, glyph: PixelGlyph? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.glyph = glyph
    }

    var body: some View {
        HStack(spacing: RD.Space.sm) {
            if let glyph { PixelIcon(glyph: glyph, size: 22) }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(RD.Font.heavy(20)).foregroundStyle(RD.Palette.textHi)
                if let subtitle {
                    Text(subtitle).font(RD.Font.medium(12)).foregroundStyle(RD.Palette.textMid)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Pixel badge / pill

struct PixelBadge: View {
    var text: String
    var tint: Color = RD.Palette.brass
    var body: some View {
        Text(text)
            .font(RD.Font.heavy(11))
            .foregroundStyle(RD.Palette.ink)
            .padding(.horizontal, RD.Space.sm)
            .padding(.vertical, 3)
            .background(Capsule().fill(tint))
    }
}

// MARK: - Empty state

struct PixelEmptyState: View {
    var glyph: PixelGlyph
    var title: String
    var message: String
    var body: some View {
        VStack(spacing: RD.Space.md) {
            PixelIcon(glyph: glyph, size: 64).opacity(0.8)
            Text(title).font(RD.Font.heavy(18)).foregroundStyle(RD.Palette.textHi)
            Text(message).font(RD.Font.medium(13)).foregroundStyle(RD.Palette.textMid)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 300)
        .padding(RD.Space.xl)
    }
}
