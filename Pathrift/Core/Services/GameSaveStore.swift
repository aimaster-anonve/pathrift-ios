import Foundation

// MARK: - SavedTower (Build 8 — DEC-032)
// Position stored as fractions of scene size for device independence.
// Old slotId-based saves (version 1) will not decode — towers are skipped,
// wave/gold/lives still restore correctly.
struct SavedTower: Codable {
    let xFrac: Double    // position.x / scene.width
    let yFrac: Double    // position.y / scene.height
    let type: String
    let level: Int
    let totalInvested: Int
}

struct GameSaveState: Codable {
    let version: Int
    let savedAt: Double
    let wave: Int
    let lives: Int
    let gold: Int
    let enemyKills: Int
    let layoutIndex: Int
    let towers: [SavedTower]
}

final class GameSaveStore {
    static let shared = GameSaveStore()
    private let key = "pathrift_game_save"
    private let currentVersion = 2   // bumped from 1 → 2 for free-form placement (DEC-032)
    private init() {}

    func save(wave: Int, lives: Int, gold: Int, kills: Int, layoutIndex: Int, towers: [SavedTower]) {
        let state = GameSaveState(
            version: currentVersion,
            savedAt: Date().timeIntervalSince1970,
            wave: wave,
            lives: lives,
            gold: gold,
            enemyKills: kills,
            layoutIndex: layoutIndex,
            towers: towers
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> GameSaveState? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(GameSaveState.self, from: data),
              state.version == currentVersion else { return nil }
        return state
    }

    func hasSave() -> Bool { load() != nil }

    func clear() { UserDefaults.standard.removeObject(forKey: key) }

    var savedWave: Int { load()?.wave ?? 0 }
}
