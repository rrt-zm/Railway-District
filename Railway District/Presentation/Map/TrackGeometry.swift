import SwiftUI

/// A smooth closed track built from node points, with arc-length sampling so trains
/// move at a constant visual speed and can be oriented along the rails.
struct TrackGeometry {
    private let samples: [CGPoint]
    private let cumulative: [CGFloat]
    let totalLength: CGFloat
    let path: Path

    init(points: [CGPoint], samplesPerSegment: Int = 24) {
        guard points.count >= 2 else {
            samples = points
            cumulative = [0]
            totalLength = 0
            path = Path()
            return
        }

        let n = points.count
        var pts: [CGPoint] = []
        for i in 0..<n {
            let p0 = points[(i - 1 + n) % n]
            let p1 = points[i]
            let p2 = points[(i + 1) % n]
            let p3 = points[(i + 2) % n]
            for s in 0..<samplesPerSegment {
                let t = CGFloat(s) / CGFloat(samplesPerSegment)
                pts.append(TrackGeometry.catmullRom(p0, p1, p2, p3, t))
            }
        }

        samples = pts

        // Cumulative arc length around the closed loop.
        var cum: [CGFloat] = [0]
        var total: CGFloat = 0
        for i in 1..<pts.count {
            total += TrackGeometry.dist(pts[i - 1], pts[i])
            cum.append(total)
        }
        // Close the loop.
        total += TrackGeometry.dist(pts[pts.count - 1], pts[0])
        cumulative = cum
        totalLength = max(total, 0.0001)

        var p = Path()
        p.move(to: pts[0])
        for i in 1..<pts.count { p.addLine(to: pts[i]) }
        p.closeSubpath()
        path = p
    }

    /// Point at a fraction 0..1 around the loop.
    func point(atFraction f: CGFloat) -> CGPoint {
        guard samples.count > 1 else { return samples.first ?? .zero }
        let target = (f.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1) * totalLength
        // Binary-ish linear search through cumulative lengths.
        for i in 1..<cumulative.count {
            if cumulative[i] >= target {
                let segLen = cumulative[i] - cumulative[i - 1]
                let t = segLen > 0 ? (target - cumulative[i - 1]) / segLen : 0
                return TrackGeometry.lerp(samples[i - 1], samples[i], t)
            }
        }
        // Wrap segment between last sample and first.
        let segLen = totalLength - cumulative[cumulative.count - 1]
        let t = segLen > 0 ? (target - cumulative[cumulative.count - 1]) / segLen : 0
        return TrackGeometry.lerp(samples[samples.count - 1], samples[0], t)
    }

    func heading(atFraction f: CGFloat) -> CGFloat {
        let a = point(atFraction: f)
        let b = point(atFraction: f + 0.01)
        return atan2(b.y - a.y, b.x - a.x)
    }

    // MARK: - Math

    private static func catmullRom(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ t: CGFloat) -> CGPoint {
        let t2 = t * t
        let t3 = t2 * t
        func comp(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
            0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
        }
        return CGPoint(x: comp(p0.x, p1.x, p2.x, p3.x), y: comp(p0.y, p1.y, p2.y, p3.y))
    }

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
