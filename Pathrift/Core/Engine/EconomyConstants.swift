import Foundation

enum EconomyConstants {
    static let startingGold: Int = 250       // 2 towers at game start
    static let startingLives: Int = 5         // more forgiving for new players

    static func goldRewardForWave(_ wave: Int) -> Int {
        // Tighter income curve — cap reduced from 135 to 115 to restore economic tension
        let base = 55
        let waveBonus = min(wave * 3, 60)   // was min(wave*4, 80); new cap: 115 at wave 20+
        return base + waveBonus
    }

    static func killGoldMultiplier(forCycle cycle: Int) -> Double {
        switch cycle {
        case 0, 1: return 1.00   // Cycle 1: full reward
        case 2:    return 0.85   // Cycle 2 (wave 19+): -15%
        case 3:    return 0.75   // Cycle 3 (wave 28+): -25%
        default:   return 0.65   // Cycle 4+ (wave 37+): -35%
        }
    }

    enum TowerCost {
        static let bolt: Int    = 80           // cheaper to encourage building
        static let blast: Int   = 130
        static let frost: Int   = 100
        static let pierce: Int  = 130
        static let core: Int    = 180
        static let inferno: Int = 200
        static let tesla: Int   = 300
        static let nova: Int    = 500
    }

    enum EnemyGoldReward {
        static let runner: Int  = 6
        static let tank: Int    = 18
        static let healer: Int  = 14
        static let phantom: Int = 10
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
