import Foundation

/// Builds fresh game states and freshly-unlocked districts.
enum NewGame {

    /// A district with every node slot present but unbuilt, and no trains.
    static func emptyDistrict(_ cfg: DistrictConfig) -> DistrictState {
        DistrictState(
            id: cfg.id,
            unlocked: false,
            nodes: cfg.nodes.map { NodeState(id: $0.id, built: false, level: 0) },
            trains: []
        )
    }

    /// Prepares a district for play: builds its platform and gives a starter train.
    static func activate(_ district: inout DistrictState, cfg: DistrictConfig) {
        district.unlocked = true
        let platformId = "\(cfg.id).platform"
        for i in district.nodes.indices where district.nodes[i].id == platformId {
            district.nodes[i].built = true
            district.nodes[i].level = max(district.nodes[i].level, 1)
        }
        if district.trains.isEmpty {
            let kind = cfg.trainKinds.first ?? .handcar
            district.trains.append(TrainState(id: "\(cfg.id).t0", kind: kind,
                                              capacityLevel: 1, speedLevel: 1, phase: 0))
        }
    }

    /// A brand-new game: only Old Town is active.
    static func freshState(now: Date) -> GameState {
        var s = GameState()
        s.version = Migration.currentVersion
        s.coins = 25
        s.createdAt = now
        s.lastSaved = now
        s.districts = Catalog.districts.map { emptyDistrict($0) }
        if let idx = s.districts.firstIndex(where: { $0.id == Catalog.first.id }) {
            activate(&s.districts[idx], cfg: Catalog.first)
        }
        s.activeDistrictId = Catalog.first.id
        s.stats.districtsUnlocked = 1
        return s
    }
}
