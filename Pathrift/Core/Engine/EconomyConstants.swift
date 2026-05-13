import Foundation

enum EconomyConstants {
    static let startingGold: Int = 250       // 2 towers at game start
    static let startingLives: Int = 5         // more forgiving for new players

    static func goldRewardForWave(_ wave: Int) -> Int {
        // Less passive income at higher waves — spending more keeps engagement up
        let base = 55
        let waveBonus = min(wave * 4, 80)    // capped so gold doesn't balloon endlessly
        return base + waveBonus
    }

    enum TowerCost {
        static let bolt: Int  = 80            // cheaper to encourage building
        static let blast: Int = 130
        static let frost: Int = 100
    }

    enum EnemyGoldReward {
        static let runner: Int = 6
        static let tank: Int   = 18
    }

    enum TowerSellRefund {
        static let manualPercent: Double   = 0.70
        static let riftForcedPercent: Double = 0.50
    }

    enum TowerUpgrade {
        static let baseCost: Int      = 80
        static let growthRate: Double = 1.45  // cost per level
    }
}
