import Foundation

/// Big-number formatting for the idle economy.
/// Renders values as 1.23K, 4.56M, 7.89B, T, then aa, ab, ac… for very large numbers.
enum BigNumber {

    private static let shortSuffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

    /// Formats a Double for HUD / cost display.
    static func format(_ value: Double, decimals: Int = 2) -> String {
        if value.isNaN || value.isInfinite { return "0" }
        let sign = value < 0 ? "-" : ""
        let v = abs(value)

        if v < 1000 {
            // Whole-ish numbers render without decimals; small fractions keep one.
            if v == v.rounded() { return "\(sign)\(Int(v))" }
            return "\(sign)\(trim(v, decimals: v < 10 ? 1 : 0))"
        }

        // Determine the 1000-power tier.
        let tier = Int(floor(log10(v) / 3.0))
        if tier < shortSuffixes.count {
            let scaled = v / pow(1000, Double(tier))
            return "\(sign)\(trim(scaled, decimals: decimals))\(shortSuffixes[tier])"
        }

        // Beyond the named suffixes: alphabetic aa, ab, ac…
        let alphaTier = tier - shortSuffixes.count
        let scaled = v / pow(1000, Double(tier))
        return "\(sign)\(trim(scaled, decimals: decimals))\(alphaSuffix(alphaTier))"
    }

    /// Compact integer formatting (no decimals) — used for counts.
    static func formatInt(_ value: Double) -> String {
        format(value, decimals: 1)
    }

    /// Per-second rate formatting.
    static func rate(_ value: Double) -> String {
        "\(format(value, decimals: 1))/s"
    }

    private static func trim(_ value: Double, decimals: Int) -> String {
        let s = String(format: "%.\(decimals)f", value)
        if s.contains(".") {
            var trimmed = s
            while trimmed.hasSuffix("0") { trimmed.removeLast() }
            if trimmed.hasSuffix(".") { trimmed.removeLast() }
            return trimmed
        }
        return s
    }

    private static func alphaSuffix(_ index: Int) -> String {
        // 0 -> aa, 1 -> ab … 25 -> az, 26 -> ba …
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        let first = index / 26
        let second = index % 26
        return "\(letters[min(first, 25)])\(letters[second])"
    }
}

extension Double {
    var bn: String { BigNumber.format(self) }
    var bnRate: String { BigNumber.rate(self) }
}

/// Time-interval formatting for offline summaries and play time.
enum TimeFormat {
    static func duration(_ seconds: Double) -> String {
        let s = Int(max(0, seconds))
        let d = s / 86400
        let h = (s % 86400) / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if d > 0 { return "\(d)d \(h)h \(m)m" }
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(sec)s" }
        return "\(sec)s"
    }

    static func compact(_ seconds: Double) -> String {
        let s = Int(max(0, seconds))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }
}
