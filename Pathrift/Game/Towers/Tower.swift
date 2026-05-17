import Foundation
import CoreGraphics
import SpriteKit

enum TowerType: String, CaseIterable, Identifiable {
    case bolt      = "Bolt"
    case blast     = "Blast"
    case frost     = "Frost"
    case pierce    = "Pierce"
    case core      = "Core"
    case inferno   = "Inferno"
    case tesla     = "Tesla"
    case nova      = "Nova"
    case sniper    = "Sniper"
    case artillery = "Artillery"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var cost: Int {
        switch self {
        case .bolt:      return EconomyConstants.TowerCost.bolt
        case .blast:     return EconomyConstants.TowerCost.blast
        case .frost:     return EconomyConstants.TowerCost.frost
        case .pierce:    return EconomyConstants.TowerCost.pierce
        case .core:      return EconomyConstants.TowerCost.core
        case .inferno:   return EconomyConstants.TowerCost.inferno
        case .tesla:     return EconomyConstants.TowerCost.tesla
        case .nova:      return EconomyConstants.TowerCost.nova
        case .sniper:    return EconomyConstants.TowerCost.sniper
        case .artillery: return EconomyConstants.TowerCost.artillery
        }
    }

    var damage: CGFloat {
        switch self {
        case .bolt:      return 20
        case .blast:     return 15
        case .frost:     return 5
        case .pierce:    return 25
        case .core:      return 45
        case .inferno:   return 18
        case .tesla:     return 35
        case .nova:      return 90
        case .sniper:    return 35
        case .artillery: return 55
        }
    }

    var attackSpeed: TimeInterval {
        switch self {
        case .bolt:      return 1.0 / 1.2
        case .blast:     return 1.0 / 0.5
        case .frost:     return 1.0 / 0.8
        case .pierce:    return 1.0 / 1.0
        case .core:      return 1.0 / 0.7
        case .inferno:   return 1.0 / 1.5
        case .tesla:     return 1.0 / 0.9
        case .nova:      return 1.0 / 0.35
        case .sniper:    return 2.0          // fires every 2s (0.5/s)
        case .artillery: return 2.5          // fires every 2.5s (0.4/s)
        }
    }

    var range: CGFloat {
        switch self {
        case .bolt:      return 155
        case .blast:     return 130
        case .frost:     return 150
        case .pierce:    return 155
        case .core:      return 125
        case .inferno:   return 125
        case .tesla:     return 160
        case .nova:      return 170
        case .sniper:    return 210
        case .artillery: return 155
        }
    }

    var blastRadius: CGFloat? {
        switch self {
        case .blast:     return 96
        case .nova:      return 160
        case .artillery: return 80
        default:         return nil
        }
    }

    var slowFactor: CGFloat? {
        switch self {
        case .frost: return 0.40
        default: return nil
        }
    }

    var description: String {
        switch self {
        case .bolt:
            return "Fast single-target. Damage: 20, Speed: 1.2/s, Range: 3"
        case .blast:
            return "Area of Effect. Damage: 15, Speed: 0.5/s, Range: 2.5"
        case .frost:
            return "Slows enemies 40%. Damage: 5, Speed: 0.8/s, Range: 3"
        case .pierce:
            return "Pierces shields. Hits ALL enemies in range. Damage: 25, Speed: 1.0/s"
        case .core:
            return "Armor penetration 50%. Heavy hitter. Damage: 45, Speed: 0.7/s"
        case .inferno:
            return "Rapid fire, destroys Ghosts. Damage: 18, Speed: 1.5/s [PREMIUM]"
        case .tesla:
            return "Chain lightning hits up to 3 enemies. Damage: 35+18, Speed: 0.9/s [PREMIUM]"
        case .nova:
            return "Massive AoE burst. Damage: 90, AoE: 160, Speed: 0.35/s [PREMIUM]"
        case .sniper:
            return "Ultra long range, all layers. Damage: 35, Speed: 0.5/s, Range: 260"
        case .artillery:
            return "Bridge-only AoE mortar. Damage: 55, AoE: 80, Speed: 0.4/s, +50% vs Boss"
        }
    }

    var nodeColor: SKColor {
        switch self {
        case .bolt:      return SKColor(red: 0.0,  green: 0.78, blue: 1.0,  alpha: 1)
        case .blast:     return SKColor(red: 1.0,  green: 0.42, blue: 0.0,  alpha: 1)
        case .frost:     return SKColor(red: 0.55, green: 0.31, blue: 1.0,  alpha: 1)
        case .pierce:    return SKColor(red: 0.6,  green: 1.0,  blue: 0.2,  alpha: 1)
        case .core:      return SKColor(red: 1.0,  green: 0.27, blue: 0.0,  alpha: 1)
        case .inferno:   return SKColor(red: 1.0,  green: 0.15, blue: 0.0,  alpha: 1)
        case .tesla:     return SKColor(red: 0.4,  green: 0.8,  blue: 1.0,  alpha: 1)
        case .nova:      return SKColor(red: 1.0,  green: 0.95, blue: 0.5,  alpha: 1)
        case .sniper:    return SKColor(red: 0.4,  green: 1.0,  blue: 1.0,  alpha: 1) // cyan-white
        case .artillery: return SKColor(red: 0.8,  green: 0.53, blue: 0.0,  alpha: 1) // brass/gold
        }
    }

    var projectileColor: SKColor {
        switch self {
        case .bolt:      return SKColor.yellow
        case .blast:     return SKColor.orange
        case .frost:     return SKColor.cyan
        case .pierce:    return SKColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 1)
        case .core:      return SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1)
        case .inferno:   return SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 1)
        case .tesla:     return SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1)
        case .nova:      return SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1)
        case .sniper:    return SKColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1)
        case .artillery: return SKColor(red: 0.9, green: 0.6, blue: 0.0, alpha: 1)
        }
    }

    var diamondCost: Int {
        switch self {
        case .bolt:      return 0    // FREE — starter, always unlocked
        case .blast:     return 10   // BASIC
        case .frost:     return 15   // BASIC
        case .pierce:    return 30   // ADVANCED
        case .core:      return 50   // ADVANCED
        case .inferno:   return 80   // ELITE
        case .tesla:     return 150  // ELITE
        case .nova:      return 300  // ELITE
        case .sniper:    return 0    // FREE — second starter for new players
        case .artillery: return 20   // BASIC — was 0, now requires diamond (Build 7)
        }
    }

    var isPremium: Bool { diamondCost > 0 }

    var tier: Int {
        switch self {
        case .bolt, .blast, .frost:                  return 1
        case .pierce, .core, .sniper, .artillery:    return 2
        case .inferno, .tesla, .nova:                return 3
        }
    }

    var typeAdvantageHint: String? {
        switch self {
        case .bolt:      return "+50% vs Runners"
        case .blast:     return "+60% vs Swarms"
        case .frost:     return nil
        case .pierce:    return "+100% vs Shields"
        case .core:      return "+60% vs Tanks"
        case .inferno:   return "+75% vs Ghosts"
        case .tesla:     return "+75% vs Swarms"
        case .nova:      return "+50% vs Boss"
        case .sniper:    return nil
        case .artillery: return "+50% vs Boss"
        }
    }

    // MARK: - Z-Layer Targeting Mode

    enum TargetingMode {
        case allLayers
        case groundOnly
        case bridgeOnly
    }

    var targetingMode: TargetingMode {
        switch self {
        case .sniper:    return .allLayers
        case .artillery: return .bridgeOnly
        default:         return .groundOnly
        }
    }

    func damageMultiplier(against enemyType: EnemyType) -> CGFloat {
        switch self {
        case .bolt:      return (enemyType == .runner || enemyType == .splitter) ? 1.5 : 1.0
        case .blast:     return enemyType == .swarm ? 1.6 : 1.0
        case .frost:     return 1.0
        case .pierce:    return enemyType == .shield ? 2.0 : 1.0
        case .core:      return enemyType == .tank ? 1.6 : 1.0
        case .inferno:   return enemyType == .ghost ? 1.75 : 1.0
        case .tesla:     return enemyType == .swarm ? 1.75 : 1.0
        case .nova:      return enemyType == .boss ? 1.5 : 1.0
        case .sniper:    return 1.0
        case .artillery: return enemyType == .boss ? 1.5 : 1.0
        }
    }
}

protocol Tower: AnyObject {
    var type: TowerType { get }
    var position: CGPoint { get set }
    var slotId: Int { get set }
    var lastFiredTime: TimeInterval { get set }
    var node: SKNode { get }
    var level: Int { get set }
    var totalInvested: Int { get set }

    func canFire(at currentTime: TimeInterval) -> Bool
    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval)
    func buildNode() -> SKNode
}

extension Tower {
    func permDamageBonus() -> CGFloat {
        ArsenalStore.shared.permDamageBonus(for: type)
    }

    func permSpeedBonus() -> CGFloat {
        ArsenalStore.shared.permSpeedBonus(for: type)
    }

    func scaledDamage() -> CGFloat {
        return type.damage * (1.0 + 0.25 * CGFloat(level - 1)) * (1.0 + permDamageBonus())
    }

    func effectiveAttackInterval() -> TimeInterval {
        let inRunSpeedMult = 1.0 + 0.08 * Double(level - 1)
        let permSpeedMult  = 1.0 + Double(permSpeedBonus())
        return type.attackSpeed / (inRunSpeedMult * permSpeedMult)
    }

    func canFire(at currentTime: TimeInterval) -> Bool {
        return currentTime - lastFiredTime >= effectiveAttackInterval()
    }

    func isInRange(_ enemy: EnemyNode) -> Bool {
        let dx = enemy.node.position.x - position.x
        let dy = enemy.node.position.y - position.y
        return sqrt(dx * dx + dy * dy) <= type.range
    }
}
