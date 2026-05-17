import Foundation

enum EconomyConstants {
    static let startingGold: Int = 300        // was 250 — better early placement options
    static let startingLives: Int = 5          // was 8 — reverted to original

    static func goldRewardForWave(_ wave: Int) -> Int {
        let base = 55
        let waveBonus = min(wave * 3, 75)   // cap raised: 130 at wave 25+ (was 115 at wave 20+)
        return base + waveBonus
    }

    static func killGoldMultiplier(forCycle cycle: Int) -> Double {
        switch cycle {
        case 0, 1: return 1.00
        case 2:    return 0.90   // was 0.85
        case 3:    return 0.82   // was 0.75
        default:   return 0.72   // was 0.65
        }
    }

    enum TowerCost {
        static let bolt: Int      = 80     // Tier 1 starter — affordable from wave 1
        static let blast: Int     = 100    // was 130 — Tier 1 AoE generalist
        static let frost: Int     = 100    // Tier 1 utility/support
        static let pierce: Int    = 140    // was 130 — Tier 2 anti-Shield
        static let core: Int      = 170    // was 180 — Tier 2 armor pen
        static let sniper: Int    = 190    // was 220 — Tier 2 all-layer
        static let artillery: Int = 160    // Tier 2 bridge AoE (unchanged)
        static let inferno: Int   = 210    // was 200 — Tier 3 premium opener
        static let tesla: Int     = 300    // Tier 3 chain lightning (unchanged)
        static let nova: Int      = 500    // Tier 3 prestige AoE (unchanged)
    }

    enum MoveCost {
        static let percent: Double = 0.30  // ceil(totalInvested * 0.30)
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
