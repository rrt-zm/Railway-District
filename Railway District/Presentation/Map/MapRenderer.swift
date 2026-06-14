import SwiftUI

/// Stateless drawing routines for the district map.
enum MapRenderer {

    private static func rect(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                             _ w: CGFloat, _ h: CGFloat, _ color: Color) {
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
    }

    // MARK: - Sky

    static func drawSky(ctx: GraphicsContext, size: CGSize, theme: DistrictTheme, dayT: Double) {
        let brightness = 0.5 + 0.5 * CoreGraphics.cos(dayT * 2 * .pi) // 1 = noon, 0 = midnight
        let night = Color(hex: 0x1A2238)
        let top = theme.skyTop.mix(night, 1 - brightness)
        let bottom = theme.skyBottom.mix(night, 1 - brightness)

        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [top, bottom]),
                                       startPoint: .zero,
                                       endPoint: CGPoint(x: 0, y: size.height)))

        // Stars at night.
        if brightness < 0.45 {
            let starAlpha = (0.45 - brightness) / 0.45
            for i in 0..<26 {
                let fx = CGFloat((i * 97) % 100) / 100
                let fy = CGFloat((i * 53) % 60) / 100
                let s: CGFloat = (i % 3 == 0) ? 2.5 : 1.5
                rect(ctx, fx * size.width, fy * size.height * 0.7, s, s,
                     RD.Palette.textHi.opacity(starAlpha))
            }
        }

        // Sun / moon arc.
        let bodyX = size.width * CGFloat(dayT)
        let bodyY = size.height * (0.62 - 0.42 * CGFloat(CoreGraphics.sin(dayT * .pi)))
        if brightness > 0.4 {
            ctx.fill(Path(ellipseIn: CGRect(x: bodyX - 16, y: bodyY - 16, width: 32, height: 32)),
                     with: .color(RD.Palette.coins.opacity(0.95)))
            ctx.fill(Path(ellipseIn: CGRect(x: bodyX - 22, y: bodyY - 22, width: 44, height: 44)),
                     with: .color(RD.Palette.coins.opacity(0.18)))
        } else {
            let moonX = size.width * CGFloat((dayT + 0.5).truncatingRemainder(dividingBy: 1))
            ctx.fill(Path(ellipseIn: CGRect(x: moonX - 13, y: bodyY - 13, width: 26, height: 26)),
                     with: .color(RD.Palette.textHi.opacity(0.92)))
            ctx.fill(Path(ellipseIn: CGRect(x: moonX - 7, y: bodyY - 16, width: 22, height: 22)),
                     with: .color(theme.skyTop.mix(Color(hex: 0x1A2238), 1 - brightness)))
        }
    }

    // MARK: - Ground

    static func drawGround(ctx: GraphicsContext, size: CGSize, theme: DistrictTheme) {
        let groundTop = size.height * 0.46
        rect(ctx, 0, groundTop, size.width, size.height - groundTop, theme.ground)
        // Darker horizon band.
        rect(ctx, 0, groundTop, size.width, 8, theme.groundDark)
        // Foreground shading.
        ctx.fill(Path(CGRect(x: 0, y: size.height * 0.8, width: size.width, height: size.height * 0.2)),
                 with: .color(theme.groundDark.opacity(0.35)))

        if theme.hasWater {
            let waterTop = size.height * 0.46
            rect(ctx, 0, waterTop, size.width, 26, RD.Palette.water)
            rect(ctx, 0, waterTop + 26, size.width, 6, RD.Palette.waterLight.opacity(0.7))
        }
    }

    // MARK: - Decorations

    static func drawDecorations(ctx: GraphicsContext, size: CGSize, theme: DistrictTheme, t: Double) {
        // Drifting clouds (parallax).
        let cloud = PixelGlyph.cloud.sprite
        for i in 0..<3 {
            let speed = 14.0 + Double(i) * 6
            let baseX = (t * speed).truncatingRemainder(dividingBy: Double(size.width + 120)) - 60
            let x = CGFloat(baseX) + CGFloat(i * 90)
            let y = size.height * (0.10 + 0.07 * Double(i))
            PixelArtLibrary.draw(cloud, in: ctx,
                                 rect: CGRect(x: x, y: y, width: 56, height: 28))
        }

        // Trees on grassy ground.
        if !theme.hasSnow && !theme.hasWater {
            let tree = PixelGlyph.tree.sprite
            let positions: [(CGFloat, CGFloat)] = [(0.07, 0.55), (0.93, 0.6), (0.5, 0.93), (0.28, 0.95)]
            for (fx, fy) in positions {
                PixelArtLibrary.draw(tree, in: ctx,
                                     rect: CGRect(x: fx * size.width - 14, y: fy * size.height - 14,
                                                  width: 28, height: 28))
            }
        }

        // Snow drifts.
        if theme.hasSnow {
            for i in 0..<30 {
                let fx = CGFloat((i * 61) % 100) / 100
                let drift = CGFloat((t * 18).truncatingRemainder(dividingBy: Double(size.height)))
                let fy = (CGFloat((i * 37) % 100) / 100 * size.height + drift).truncatingRemainder(dividingBy: size.height)
                rect(ctx, fx * size.width, fy, 2.5, 2.5, RD.Palette.textHi.opacity(0.8))
            }
        }

        // Street lamps for the neon metro.
        if theme.skyTop == Color(hex: 0x2B2342) {
            let lamp = PixelGlyph.lamp.sprite
            for fx in [0.12, 0.88] {
                PixelArtLibrary.draw(lamp, in: ctx,
                                     rect: CGRect(x: CGFloat(fx) * size.width - 8,
                                                  y: size.height * 0.5, width: 16, height: 32))
            }
        }
    }

    // MARK: - Track

    static func drawTrack(ctx: GraphicsContext, path: Path) {
        ctx.stroke(path, with: .color(RD.Palette.railTie), lineWidth: 13)
        ctx.stroke(path, with: .color(RD.Palette.rail), lineWidth: 8)
        ctx.stroke(path, with: .color(RD.Palette.stone.opacity(0.8)),
                   style: StrokeStyle(lineWidth: 2.5, dash: [3, 7]))
    }

    // MARK: - Buildings

    static func drawBuilding(ctx: GraphicsContext, center: CGPoint, kind: BuildingKind,
                             built: Bool, t: Double) {
        let s: CGFloat = 46
        // Ground shadow.
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - s * 0.42, y: center.y + s * 0.28,
                                        width: s * 0.84, height: s * 0.26)),
                 with: .color(Color.black.opacity(0.18)))

        if !built {
            // Empty plot: dashed square + faded sprite.
            let plot = CGRect(x: center.x - s * 0.42, y: center.y - s * 0.42, width: s * 0.84, height: s * 0.84)
            ctx.stroke(Path(roundedRect: plot, cornerRadius: 5),
                       with: .color(RD.Palette.textHi.opacity(0.35)),
                       style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
            var faded = ctx
            faded.opacity = 0.28
            PixelArtLibrary.draw(kind.glyph.sprite, in: faded,
                                 rect: CGRect(x: center.x - s * 0.33, y: center.y - s * 0.33,
                                              width: s * 0.66, height: s * 0.66))
            return
        }

        // Built: bob slightly for life.
        let bob = CGFloat(CoreGraphics.sin(t * 2 + Double(center.x))) * 1.0
        let rectFrame = CGRect(x: center.x - s / 2, y: center.y - s / 2 + bob, width: s, height: s)
        PixelArtLibrary.draw(kind.glyph.sprite, in: ctx, rect: rectFrame)

        // Foundry & mine emit smoke.
        if kind == .foundry || kind == .mine {
            drawSmoke(ctx: ctx, base: CGPoint(x: center.x - 6, y: center.y - s * 0.5), t: t, seed: center.x)
        }
        // Signal tower blinks.
        if kind == .signalTower {
            let on = Int(t * 2) % 2 == 0
            rect(ctx, center.x - 3, center.y - s * 0.5, 6, 6,
                 on ? RD.Palette.signalGreen : RD.Palette.signalRed)
        }
    }

    static func drawSmoke(ctx: GraphicsContext, base: CGPoint, t: Double, seed: CGFloat) {
        for i in 0..<3 {
            let phase = (t * 0.8 + Double(i) * 0.4).truncatingRemainder(dividingBy: 1)
            let y = base.y - CGFloat(phase) * 26
            let drift = CGFloat(CoreGraphics.sin(phase * 4 + Double(seed))) * 4
            let sz = 4 + CGFloat(phase) * 6
            let alpha = (1 - phase) * 0.5
            ctx.fill(Path(ellipseIn: CGRect(x: base.x + drift - sz / 2, y: y - sz / 2, width: sz, height: sz)),
                     with: .color(RD.Palette.textMid.opacity(alpha)))
        }
    }

    // MARK: - Trains

    static func drawTrain(ctx: GraphicsContext, center: CGPoint, kind: TrainKind, t: Double, moving: Bool) {
        let bob = CGFloat(CoreGraphics.sin(t * 8 + Double(center.x))) * 0.8
        let cx = center.x
        let cy = center.y + bob
        let w: CGFloat = 26
        let h: CGFloat = 15

        // Body.
        let body = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
        ctx.fill(Path(roundedRect: body, cornerRadius: 3), with: .color(kind.bodyColor))
        // Cab (front third) darker.
        rect(ctx, cx + w / 2 - 8, cy - h / 2, 8, h, kind.bodyColor.mix(.black, 0.25))
        // Window.
        rect(ctx, cx + w / 2 - 6, cy - h / 2 + 3, 4, 4, RD.Palette.passengers)
        // Side stripe.
        rect(ctx, cx - w / 2, cy + 1, w, 2, RD.Palette.textHi.opacity(0.6))
        // Wheels.
        let wheelY = cy + h / 2 - 1
        for wx in [cx - 7, cx + 1, cx + 8] {
            ctx.fill(Path(ellipseIn: CGRect(x: wx - 2.5, y: wheelY - 2.5, width: 5, height: 5)),
                     with: .color(RD.Palette.ink))
        }
        // Chimney + smoke for steamer/handcar.
        if kind == .handcar || kind == .steamer {
            rect(ctx, cx - w / 2 + 3, cy - h / 2 - 4, 4, 4, RD.Palette.ink)
            if moving {
                drawSmoke(ctx: ctx, base: CGPoint(x: cx - w / 2 + 5, y: cy - h / 2 - 4), t: t, seed: center.y)
            }
        } else if moving {
            // Headlight glow for modern trains.
            ctx.fill(Path(ellipseIn: CGRect(x: cx + w / 2 - 4, y: cy - 2, width: 10, height: 6)),
                     with: .color(RD.Palette.coins.opacity(0.5)))
        }
    }
}
