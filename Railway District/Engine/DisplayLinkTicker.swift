import QuartzCore

/// A CADisplayLink wrapper that calls a per-frame callback with the elapsed time.
/// Drives the simulation independently of which screen is visible.
final class DisplayLinkTicker {
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private let onTick: (Double) -> Void

    init(onTick: @escaping (Double) -> Void) {
        self.onTick = onTick
    }

    func start() {
        guard link == nil else { return }
        lastTimestamp = 0
        let l = CADisplayLink(target: self, selector: #selector(step))
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        let dt = link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        onTick(dt)
    }
}
