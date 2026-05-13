import Foundation

struct ScoreCalculator {
    static func calculate(wavesReached: Int, enemyKills: Int) -> Int {
        return wavesReached * 1000 + enemyKills * 5
    }

    static func formatScore(_ score: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: score)) ?? "\(score)"
    }
}
