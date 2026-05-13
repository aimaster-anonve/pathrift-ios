import Foundation

enum EconomyConstants {
    static let startingGold: Int = 150
    static let startingLives: Int = 3

    static func goldRewardForWave(_ wave: Int) -> Int {
        return 50 + (wave * 5)
    }

    enum TowerCost {
        static let bolt: Int = 100
        static let blast: Int = 150
        static let frost: Int = 120
    }

    enum EnemyGoldReward {
        static let runner: Int = 5
        static let tank: Int = 15
    }
}
