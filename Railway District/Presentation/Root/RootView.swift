import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case map, build, trains, upgrades, districts, more
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .map: return "Map"
        case .build: return "Stations"
        case .trains: return "Trains"
        case .upgrades: return "Upgrades"
        case .districts: return "Districts"
        case .more: return "More"
        }
    }
    var glyph: PixelGlyph {
        switch self {
        case .map: return .map
        case .build: return .warehouse
        case .trains: return .train
        case .upgrades: return .gear
        case .districts: return .signal
        case .more: return .star
        }
    }
}

enum MoreRoute: Int, Identifiable {
    case quests, achievements, stats, prestige, settings
    var id: Int { rawValue }
}

/// App composition root: owns the store, the custom tab bar and all overlays.
struct RootView: View {
    @State private var store = GameStore()
    @State private var tab: AppTab = .map
    @State private var moreRoute: MoreRoute?
    @State private var showOnboarding = false
    @State private var didBegin = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            RD.Palette.panel.ignoresSafeArea()

            VStack(spacing: 0) {
                screen
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                CustomTabBar(selected: $tab)
            }

            // Achievement toast.
            if let toast = store.achievementToast {
                AchievementToast(config: toast)
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Offline summary.
            if let report = store.offlineReport {
                OfflineSummaryView(report: report) {
                    withAnimation(RD.Anim.snappy) { store.offlineReport = nil }
                }
                .transition(.opacity)
                .zIndex(10)
            }

            // First-run / replayable tutorial (overlay avoids multi-cover conflicts).
            if showOnboarding {
                OnboardingView {
                    store.completeTutorial()
                    withAnimation(RD.Anim.smooth) { showOnboarding = false }
                }
                .zIndex(20)
                .transition(.opacity)
            }
        }
        .animation(RD.Anim.snappy, value: store.achievementToast?.id)
        .fullScreenCover(item: $moreRoute) { route in
            secondaryScreen(route)
        }
        .onAppear {
            if !didBegin {
                didBegin = true
                store.begin()
                if !store.state.settings.tutorialCompleted {
                    showOnboarding = true
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive: store.handleBackground()
            case .active: if didBegin { store.handleForeground() }
            @unknown default: break
            }
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch tab {
        case .map: GameView(store: store) { tab = .more; moreRoute = .quests }
        case .build: BuildScreen(store: store)
        case .trains: TrainsScreen(store: store)
        case .upgrades: UpgradesScreen(store: store)
        case .districts: DistrictsScreen(store: store)
        case .more: MoreMenuScreen(store: store) { moreRoute = $0 }
        }
    }

    @ViewBuilder
    private func secondaryScreen(_ route: MoreRoute) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch route {
                case .quests: QuestsScreen(store: store)
                case .achievements: AchievementsScreen(store: store)
                case .stats: StatsScreen(store: store)
                case .prestige: PrestigeScreen(store: store)
                case .settings: SettingsScreen(store: store) {
                    moreRoute = nil
                    showOnboarding = true
                }
                }
            }
            CloseButton { moreRoute = nil }
                .padding(.top, RD.Space.sm)
                .padding(.trailing, RD.Space.lg)
        }
    }
}

struct CloseButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: { Haptics.shared.select(); action() }) {
            ZStack {
                Circle().fill(RD.Palette.panelLight)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().strokeBorder(RD.Palette.woodDark, lineWidth: 1.5))
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(RD.Palette.textHi)
            }
        }
        .buttonStyle(.plain)
    }
}

/// The custom, control-panel styled bottom navigation.
struct CustomTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { t in
                Button {
                    Haptics.shared.select()
                    withAnimation(RD.Anim.snappy) { selected = t }
                } label: {
                    VStack(spacing: 3) {
                        PixelIcon(glyph: t.glyph, size: 24)
                            .opacity(selected == t ? 1 : 0.55)
                            .scaleEffect(selected == t ? 1.1 : 1)
                        Text(t.title)
                            .font(RD.Font.heavy(9))
                            .foregroundStyle(selected == t ? RD.Palette.brass : RD.Palette.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RD.Space.sm)
                    .background(
                        selected == t
                        ? RoundedRectangle(cornerRadius: RD.Radius.sm).fill(RD.Palette.panelLight).padding(.horizontal, 4)
                        : RoundedRectangle(cornerRadius: RD.Radius.sm).fill(.clear).padding(.horizontal, 4)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, RD.Space.xs)
        .padding(.top, RD.Space.xs)
        .background(
            RD.Palette.wood
                .overlay(Rectangle().fill(RD.Palette.brassDark).frame(height: 3), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// Grid of secondary destinations.
struct MoreMenuScreen: View {
    let store: GameStore
    var onSelect: (MoreRoute) -> Void

    private let items: [(MoreRoute, PixelGlyph, String, String)] = [
        (.quests, .star, "Quests", "Objectives & rewards"),
        (.achievements, .star, "Achievements", "Milestones to unlock"),
        (.stats, .signal, "Statistics", "Your lifetime record"),
        (.prestige, .blueprint, "Restructure", "Prestige for blueprints"),
        (.settings, .gear, "Settings", "Sound, haptics & more"),
    ]

    var body: some View {
        ScreenScaffold(title: "More", subtitle: "Everything else", glyph: .star) {
            ScrollView {
                VStack(spacing: RD.Space.md) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        Button { onSelect(item.0) } label: {
                            HStack(spacing: RD.Space.md) {
                                PixelIcon(glyph: item.1, size: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.2).font(RD.Font.heavy(17)).foregroundStyle(RD.Palette.textHi)
                                    Text(item.3).font(RD.Font.medium(12)).foregroundStyle(RD.Palette.textMid)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundStyle(RD.Palette.textDim)
                            }
                            .pixelPanel(fill: RD.Palette.panel)
                        }
                        .buttonStyle(.plain)
                    }
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, RD.Space.md)
            }
        }
    }
}

/// Unlock toast shown when an achievement is earned.
struct AchievementToast: View {
    let config: AchievementConfig
    var body: some View {
        HStack(spacing: RD.Space.md) {
            PixelIcon(glyph: config.glyph, size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text("Achievement Unlocked!").font(RD.Font.heavy(11)).foregroundStyle(RD.Palette.coins)
                Text(config.title).font(RD.Font.heavy(15)).foregroundStyle(RD.Palette.textHi)
            }
        }
        .padding(.horizontal, RD.Space.lg).padding(.vertical, RD.Space.md)
        .background(
            Capsule().fill(RD.Palette.panel)
                .overlay(Capsule().strokeBorder(RD.Palette.brass, lineWidth: 2))
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        )
    }
}
