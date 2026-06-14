import Foundation

/// Crash-safe local persistence of the full game state as a Codable JSON snapshot.
final class SaveService {
    static let shared = SaveService()

    private let filename = "railway_district_save.json"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
    }

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(filename)
    }

    func save(_ state: GameState) {
        do {
            let data = try encoder.encode(state)
            // Atomic write avoids corruption if the app is killed mid-write.
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Persistence failures must never crash the game.
            print("SaveService: save failed — \(error)")
        }
    }

    func load() -> GameState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            var state = try decoder.decode(GameState.self, from: data)
            state = Migration.migrate(state)
            return state
        } catch {
            print("SaveService: load failed — \(error)")
            return nil
        }
    }

    func deleteSave() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    var hasSave: Bool { FileManager.default.fileExists(atPath: fileURL.path) }
}

/// Safe forward-migration of older save schemas.
enum Migration {
    static let currentVersion = 1

    static func migrate(_ state: GameState) -> GameState {
        var s = state
        // Ensure every catalogue district exists in the save (content may have grown).
        for cfg in Catalog.districts where s.district(cfg.id) == nil {
            s.districts.append(NewGame.emptyDistrict(cfg))
        }
        // Ensure every node slot exists for each district.
        for i in s.districts.indices {
            guard let cfg = Catalog.district(s.districts[i].id) else { continue }
            for nc in cfg.nodes where s.districts[i].node(nc.id) == nil {
                s.districts[i].nodes.append(NodeState(id: nc.id))
            }
        }
        if s.activeDistrictId.isEmpty || s.district(s.activeDistrictId) == nil {
            s.activeDistrictId = Catalog.first.id
        }
        s.version = currentVersion
        return s
    }
}
