import Foundation

struct SavedTower: Codable {
    let slotId: Int
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
    private let currentVersion = 1
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
