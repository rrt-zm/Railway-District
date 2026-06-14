import UIKit

/// Lightweight haptics + (visual) sound-cue service. Respects user settings.
/// No audio files are bundled — "sound" is expressed as on-screen cues; this keeps
/// the app fully offline and dependency-free while honouring the sound toggle.
final class Haptics {
    static let shared = Haptics()

    var hapticsEnabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        light.prepare()
        medium.prepare()
    }

    func tap() {
        guard hapticsEnabled else { return }
        light.impactOccurred(intensity: 0.7)
    }

    func build() {
        guard hapticsEnabled else { return }
        medium.impactOccurred()
    }

    func deliver() {
        guard hapticsEnabled else { return }
        rigid.impactOccurred(intensity: 0.5)
    }

    func success() {
        guard hapticsEnabled else { return }
        notify.notificationOccurred(.success)
    }

    func warning() {
        guard hapticsEnabled else { return }
        notify.notificationOccurred(.warning)
    }

    func select() {
        guard hapticsEnabled else { return }
        selection.selectionChanged()
    }
}
