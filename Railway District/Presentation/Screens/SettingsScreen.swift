import SwiftUI

/// Settings: toggles, tutorial, reset — all persisted locally.
struct SettingsScreen: View {
    let store: GameStore
    var replayTutorial: () -> Void
    @State private var confirmReset = false
    @State private var showPrivacy = false

    var body: some View {
        let s = store.state.settings
        ScreenScaffold(title: "Settings", subtitle: "Tune your experience", glyph: .gear) {
            ScrollView {
                VStack(spacing: RD.Space.md) {
                    VStack(spacing: RD.Space.sm) {
                        ToggleRow(glyph: .signal, title: "Sound cues",
                                  subtitle: "On-screen audio-style feedback", isOn: s.soundEnabled) {
                            store.setSound($0)
                        }
                        ToggleRow(glyph: .bolt, title: "Music ambiance",
                                  subtitle: "Animated background mood", isOn: s.musicEnabled) {
                            store.setMusic($0)
                        }
                        ToggleRow(glyph: .hand, title: "Haptics",
                                  subtitle: "Vibration feedback on taps", isOn: s.hapticsEnabled) {
                            store.setHaptics($0)
                        }
                        ToggleRow(glyph: .star, title: "High quality",
                                  subtitle: "Particles & extra effects", isOn: s.highQuality) {
                            store.setQuality($0)
                        }
                    }
                    .pixelPanel(fill: RD.Palette.panel)

                    VStack(spacing: RD.Space.sm) {
                        SectionHeader("Game", glyph: .train)
                        RDButton(title: "Replay Tutorial", glyph: .map, kind: .secondary) {
                            store.resetTutorial()
                            replayTutorial()
                        }
                        RDButton(title: "Privacy Policy", glyph: .map, kind: .secondary) {
                            showPrivacy = true
                        }
                        RDButton(title: "Reset All Progress", glyph: .gear, kind: .danger) {
                            confirmReset = true
                        }
                    }
                    .pixelPanel(fill: RD.Palette.panel)

                    aboutPanel
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, RD.Space.md)
            }
        }
        .alert("Reset all progress?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) { store.resetProgress() }
        } message: {
            Text("This permanently erases your railway, districts, upgrades, prestige and stats. This cannot be undone.")
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    private var aboutPanel: some View {
        VStack(alignment: .leading, spacing: RD.Space.sm) {
            SectionHeader("About", glyph: .star)
            Text("Railway District")
                .font(RD.Font.heavy(16)).foregroundStyle(RD.Palette.textHi)
            Text("A cozy pixel-art clicker tycoon. Tap to power your trains, build stations, automate routes and grow a sleepy depot into a sprawling transport empire — fully offline, no ads, no notifications.")
                .font(RD.Font.medium(12)).foregroundStyle(RD.Palette.textMid)
            Text("Your progress saves automatically on this device.")
                .font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel(fill: RD.Palette.panel)
    }
}

/// Custom pixel toggle (no default SwiftUI Toggle styling).
struct ToggleRow: View {
    let glyph: PixelGlyph
    let title: String
    let subtitle: String
    let isOn: Bool
    var onChange: (Bool) -> Void

    var body: some View {
        Button {
            Haptics.shared.select()
            onChange(!isOn)
        } label: {
            HStack(spacing: RD.Space.md) {
                PixelIcon(glyph: glyph, size: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(RD.Font.heavy(15)).foregroundStyle(RD.Palette.textHi)
                    Text(subtitle).font(RD.Font.medium(11)).foregroundStyle(RD.Palette.textMid)
                }
                Spacer()
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule().fill(isOn ? RD.Palette.success : RD.Palette.panelLight)
                        .frame(width: 50, height: 28)
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.2), lineWidth: 1))
                    Circle().fill(RD.Palette.textHi)
                        .frame(width: 22, height: 22).padding(3)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                }
                .animation(RD.Anim.snappy, value: isOn)
            }
        }
        .buttonStyle(.plain)
    }
}
