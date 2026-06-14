import SwiftUI
import UIKit

/// Central design tokens for Railway District.
/// A cozy pixel-art railway identity: warm woods, brass/metal, ticket paper, signal lights.
enum RD {

    // MARK: - Palette

    enum Palette {
        // Sky / ambiance (day -> dusk -> night handled by DayNight)
        static let skyDay      = Color(hex: 0x8FD3E8)
        static let skyDusk     = Color(hex: 0xF2A65A)
        static let skyNight    = Color(hex: 0x223A5E)

        // Surfaces — wood & metal panels
        static let panel       = Color(hex: 0x2B2233)   // dark plum panel
        static let panelLight  = Color(hex: 0x3A2E47)
        static let wood        = Color(hex: 0x7A4E2D)
        static let woodDark    = Color(hex: 0x5A3820)
        static let woodLight   = Color(hex: 0xA9713F)
        static let brass       = Color(hex: 0xD9A441)
        static let brassDark   = Color(hex: 0xA9761E)
        static let ticket      = Color(hex: 0xF4E4C1)   // ticket paper
        static let ticketEdge  = Color(hex: 0xD8C193)

        // Ground / map
        static let grass       = Color(hex: 0x6FB36B)
        static let grassDark   = Color(hex: 0x4E8E4E)
        static let dirt        = Color(hex: 0x8C6B47)
        static let rail        = Color(hex: 0x6E6A78)
        static let railTie     = Color(hex: 0x4A3526)
        static let water       = Color(hex: 0x3E8FB0)
        static let waterLight  = Color(hex: 0x5FB8D6)
        static let stone       = Color(hex: 0x9AA0AE)

        // Text
        static let ink         = Color(hex: 0x2A2030)
        static let textHi      = Color(hex: 0xFDF6E3)
        static let textMid     = Color(hex: 0xC9BBD6)
        static let textDim     = Color(hex: 0x8E7FA0)

        // Semantic / signals
        static let coal        = Color(hex: 0x4A4A55)
        static let steel       = Color(hex: 0xB8C0CC)
        static let passengers  = Color(hex: 0x6EC1E4)
        static let cargo       = Color(hex: 0xE2A45C)
        static let coins       = Color(hex: 0xF2C94C)
        static let blueprints  = Color(hex: 0x7CE0C9)

        static let success     = Color(hex: 0x6FCF6F)
        static let warning     = Color(hex: 0xF2C94C)
        static let danger      = Color(hex: 0xEB5757)
        static let signalRed   = Color(hex: 0xE8503A)
        static let signalGreen = Color(hex: 0x4FD16B)

        static let accent      = Color(hex: 0xF2A65A)
        static let accent2     = Color(hex: 0xE86A92)
    }

    // MARK: - Spacing (8pt-ish grid, pixel friendly)

    enum Space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Animation

    enum Anim {
        static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.62)
        static let bouncy = Animation.spring(response: 0.42, dampingFraction: 0.55)
        static let smooth = Animation.easeInOut(duration: 0.25)
        static let slow   = Animation.easeInOut(duration: 0.55)
        static let pop    = Animation.spring(response: 0.22, dampingFraction: 0.5)
    }

    // MARK: - Typography (rounded, chunky, game-grade)

    enum Font {
        static func display(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .black, design: .rounded)
        }
        static func heavy(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .heavy, design: .rounded)
        }
        static func bold(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        static func medium(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static func mono(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .heavy, design: .monospaced)
        }
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    func mix(_ other: Color, _ t: Double) -> Color {
        let a = UIColor(self)
        let b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let tt = CGFloat(max(0, min(1, t)))
        return Color(.sRGB,
                     red: Double(ar + (br - ar) * tt),
                     green: Double(ag + (bg - ag) * tt),
                     blue: Double(ab + (bb - ab) * tt),
                     opacity: Double(aa + (ba - aa) * tt))
    }
}
