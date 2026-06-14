import SwiftUI

/// A tiny pixel sprite: rows of characters mapped to colors via a palette.
/// '.' (or any unmapped char) is transparent.
struct PixelSprite {
    let rows: [String]
    let palette: [Character: Color]

    var height: Int { rows.count }
    var width: Int { rows.map { $0.count }.max() ?? 0 }

    func color(col: Int, row: Int) -> Color? {
        guard row >= 0, row < rows.count else { return nil }
        let r = Array(rows[row])
        guard col >= 0, col < r.count else { return nil }
        return palette[r[col]]
    }
}

/// Catalogue of named pixel glyphs used across the UI and the map.
enum PixelGlyph {
    case coal, steel, passenger, crate
    case mine, foundry, platform, warehouse, signal, depot
    case coin, blueprint, bolt, train, wagon, gear, hand, map, moon, star
    case smoke, tree, cloud, lamp

    var sprite: PixelSprite { PixelArtLibrary.sprite(for: self) }
}

/// Renders a `PixelGlyph` as crisp pixel art (rectangles = inherently nearest-neighbor).
struct PixelIcon: View {
    let glyph: PixelGlyph
    var size: CGFloat = 24
    var body: some View {
        Canvas { ctx, canvasSize in
            PixelArtLibrary.draw(glyph.sprite, in: ctx,
                                 rect: CGRect(origin: .zero, size: canvasSize))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

enum PixelArtLibrary {

    /// Draws a sprite filling `rect` with square pixels (aspect-fit, centered).
    static func draw(_ sprite: PixelSprite, in ctx: GraphicsContext, rect: CGRect) {
        let cols = max(sprite.width, 1)
        let rows = max(sprite.height, 1)
        let cell = min(rect.width / CGFloat(cols), rect.height / CGFloat(rows))
        let originX = rect.minX + (rect.width - cell * CGFloat(cols)) / 2
        let originY = rect.minY + (rect.height - cell * CGFloat(rows)) / 2
        // Slight overdraw removes hairline seams between cells.
        let pad: CGFloat = 0.5
        for r in 0..<rows {
            for c in 0..<cols {
                guard let color = sprite.color(col: c, row: r) else { continue }
                let cellRect = CGRect(x: originX + CGFloat(c) * cell - pad,
                                      y: originY + CGFloat(r) * cell - pad,
                                      width: cell + pad * 2,
                                      height: cell + pad * 2)
                ctx.fill(Path(cellRect), with: .color(color))
            }
        }
    }

    static func sprite(for glyph: PixelGlyph) -> PixelSprite {
        switch glyph {
        case .coin:        return coin
        case .blueprint:   return blueprint
        case .coal:        return coal
        case .steel:       return steel
        case .passenger:   return passenger
        case .crate:       return crate
        case .mine:        return mine
        case .foundry:     return foundry
        case .platform:    return platform
        case .warehouse:   return warehouse
        case .signal:      return signal
        case .depot:       return depot
        case .bolt:        return bolt
        case .train:       return train
        case .wagon:       return wagon
        case .gear:        return gear
        case .hand:        return hand
        case .map:         return mapSprite
        case .moon:        return moon
        case .star:        return star
        case .smoke:       return smoke
        case .tree:        return tree
        case .cloud:       return cloud
        case .lamp:        return lamp
        }
    }

    // MARK: - Sprite definitions

    private static let coin = PixelSprite(rows: [
        "..ggg..",
        ".gyyyg.",
        "gyywyyg",
        "gyywyyg",
        "gyyyyyg",
        ".gyyyg.",
        "..ggg..",
    ], palette: ["g": RD.Palette.brassDark, "y": RD.Palette.coins, "w": RD.Palette.textHi])

    private static let blueprint = PixelSprite(rows: [
        "ddddddd",
        "dwwwwwd",
        "dwLwLwd",
        "dwwLwwd",
        "dwLwLwd",
        "dwwwwwd",
        "ddddddd",
    ], palette: ["d": RD.Palette.brassDark, "w": RD.Palette.blueprints, "L": RD.Palette.panel])

    private static let coal = PixelSprite(rows: [
        "..ggg..",
        ".gkkkg.",
        "gkkwkkg",
        "gkkkkkg",
        ".gkkkg.",
        "..ggg..",
    ], palette: ["g": Color(hex: 0x33333C), "k": RD.Palette.coal, "w": Color(hex: 0x6E6A78)])

    private static let steel = PixelSprite(rows: [
        ".......",
        ".sssss.",
        "sShwwSs",
        "ssssSss",
        ".sssss.",
        ".......",
    ], palette: ["s": RD.Palette.steel, "S": RD.Palette.stone, "h": RD.Palette.textHi, "w": Color(hex: 0xE8EDF2)])

    private static let passenger = PixelSprite(rows: [
        "..ccc..",
        "..ccc..",
        "...c...",
        "..bbb..",
        ".bbbbb.",
        ".b...b.",
    ], palette: ["c": RD.Palette.ticket, "b": RD.Palette.passengers])

    private static let crate = PixelSprite(rows: [
        "ddddddd",
        "dLbbbLd",
        "dbLbLbd",
        "dbbLbbd",
        "dLbbbLd",
        "ddddddd",
    ], palette: ["d": RD.Palette.woodDark, "b": RD.Palette.cargo, "L": RD.Palette.woodLight])

    private static let mine = PixelSprite(rows: [
        "...d...",
        "..ddd..",
        ".ddddd.",
        "ddkkkdd",
        "ddkwkdd",
        "ddddddd",
    ], palette: ["d": RD.Palette.dirt, "k": RD.Palette.ink, "w": RD.Palette.brass])

    private static let foundry = PixelSprite(rows: [
        "g..C...",
        "gg.C...",
        "..bbbbb",
        "..bobob",
        "..bbbbb",
        "..bbbbb",
    ], palette: ["g": RD.Palette.textMid, "C": RD.Palette.woodDark, "b": RD.Palette.woodLight, "o": RD.Palette.signalRed])

    private static let platform = PixelSprite(rows: [
        ".rrrrr.",
        "rrrrrrr",
        ".ccccc.",
        ".cwbwc.",
        ".cwbwc.",
        ".ccccc.",
    ], palette: ["r": RD.Palette.signalRed, "c": RD.Palette.ticket, "w": RD.Palette.passengers, "b": RD.Palette.woodDark])

    private static let warehouse = PixelSprite(rows: [
        "ddddddd",
        "dddddd d",
        "bbbbbbb",
        "bpppppb",
        "bp p pb",
        "bbbbbbb",
    ], palette: ["d": RD.Palette.woodDark, "b": RD.Palette.woodLight, "p": RD.Palette.brassDark])

    private static let signal = PixelSprite(rows: [
        "..ggg..",
        ".gGGGg.",
        "gGGwGGg",
        "gGGGGGg",
        ".gGGGg.",
        "..ggg..",
    ], palette: ["g": Color(hex: 0x2E6B3A), "G": RD.Palette.signalGreen, "w": RD.Palette.textHi])

    private static let depot = PixelSprite(rows: [
        "ddddddd",
        "daaaaad",
        "baaaaab",
        "baLLLab",
        "baLLLab",
        "bbbbbbb",
    ], palette: ["d": RD.Palette.brassDark, "a": RD.Palette.brass, "b": RD.Palette.woodDark, "L": RD.Palette.ink])

    private static let bolt = PixelSprite(rows: [
        "...yy..",
        "..yy...",
        ".yyyy..",
        "...yy..",
        "..yy...",
        ".yy....",
    ], palette: ["y": RD.Palette.warning])

    private static let train = PixelSprite(rows: [
        "...ss....",
        ".bbbbbc..",
        ".bwwwbc..",
        ".bbbbbb..",
        "..o..o...",
    ], palette: ["s": RD.Palette.textMid, "b": RD.Palette.signalRed, "c": RD.Palette.woodDark, "w": RD.Palette.passengers, "o": RD.Palette.ink])

    private static let wagon = PixelSprite(rows: [
        ".dddddd.",
        "dccccccd",
        "dccccccd",
        "dddddddd",
        "..o..o..",
    ], palette: ["d": RD.Palette.woodDark, "c": RD.Palette.cargo, "o": RD.Palette.ink])

    private static let gear = PixelSprite(rows: [
        "..sss..",
        ".sssss.",
        "sshhhss",
        "ssh.hss",
        "sshhhss",
        ".sssss.",
        "..sss..",
    ], palette: ["s": RD.Palette.stone, "h": RD.Palette.panel])

    private static let hand = PixelSprite(rows: [
        "...k...",
        "..kwk..",
        "..kwk..",
        ".kwwwk.",
        ".kwwwk.",
        "..www..",
    ], palette: ["k": RD.Palette.ink, "w": RD.Palette.ticket])

    private static let mapSprite = PixelSprite(rows: [
        "ccccccc",
        "cLccLcc",
        "ccLccLc",
        "cLccLcc",
        "ccLccLc",
        "ccccccc",
    ], palette: ["c": RD.Palette.ticket, "L": RD.Palette.passengers])

    private static let moon = PixelSprite(rows: [
        "..www..",
        ".ww....",
        "ww.....",
        "ww.....",
        ".ww....",
        "..www..",
    ], palette: ["w": RD.Palette.textHi])

    private static let star = PixelSprite(rows: [
        "...y...",
        "...y...",
        "yyyyyyy",
        ".yyyyy.",
        "..y.y..",
        ".y...y.",
    ], palette: ["y": RD.Palette.coins])

    private static let smoke = PixelSprite(rows: [
        ".ww.",
        "wwww",
        "wwww",
        ".ww.",
    ], palette: ["w": RD.Palette.textMid])

    private static let tree = PixelSprite(rows: [
        "..ggg..",
        ".ggggg.",
        "ggggggg",
        ".ggggg.",
        "...d...",
        "...d...",
    ], palette: ["g": RD.Palette.grassDark, "d": RD.Palette.woodDark])

    private static let cloud = PixelSprite(rows: [
        "..wwww..",
        ".wwwwww.",
        "wwwwwwww",
        ".wwwwww.",
    ], palette: ["w": RD.Palette.textHi])

    private static let lamp = PixelSprite(rows: [
        "..y..",
        ".yyy.",
        "..p..",
        "..p..",
        "..p..",
    ], palette: ["y": RD.Palette.coins, "p": RD.Palette.ink])
}
