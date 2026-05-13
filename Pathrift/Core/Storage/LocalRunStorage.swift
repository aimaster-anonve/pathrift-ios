import Foundation

struct StoredRun: Codable {
    let score: Int
    let wavesReached: Int
    let enemyKills: Int
    let isVictory: Bool
    let date: Date

    init(from result: RunResult) {
        self.score = result.score
        self.wavesReached = result.wavesReached
        self.enemyKills = result.enemyKills
        self.isVictory = result.isVictory
        self.date = Date()
    }
}

final class LocalRunStorage {
    static let shared = LocalRunStorage()
    private init() {}

    private let highScoreKey = "pathrift_high_score"
    private let runHistoryKey = "pathrift_run_history"
    private let maxStoredRuns = 20

    func saveRun(result: RunResult) {
        var history = loadRunHistory()
        let stored = StoredRun(from: result)
        history.insert(stored, at: 0)
        if history.count > maxStoredRuns {
            history = Array(history.prefix(maxStoredRuns))
        }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: runHistoryKey)
        }

        let current = loadHighScore()
        if result.score > current {
            saveHighScore(result.score)
        }
    }

    func loadHighScore() -> Int {
        return UserDefaults.standard.integer(forKey: highScoreKey)
    }

    func saveHighScore(_ score: Int) {
        UserDefaults.standard.set(score, forKey: highScoreKey)
    }

    func loadRunHistory() -> [StoredRun] {
        guard let data = UserDefaults.standard.data(forKey: runHistoryKey),
              let history = try? JSONDecoder().decode([StoredRun].self, from: data) else {
            return []
        }
        return history
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: runHistoryKey)
        UserDefaults.standard.removeObject(forKey: highScoreKey)
    }
}
