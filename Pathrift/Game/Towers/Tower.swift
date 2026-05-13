import Foundation
import CoreGraphics
import SpriteKit

enum TowerType: String, CaseIterable, Identifiable {
    case bolt    = "Bolt"
    case blast   = "Blast"
    case frost   = "Frost"
    case pierce  = "Pierce"
    case core    = "Core"
    case inferno = "Inferno"
    case tesla   = "Tesla"
    case nova    = "Nova"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var cost: Int {
        switch self {
        case .bolt:    return EconomyConstants.TowerCost.bolt
        case .blast:   return EconomyConstants.TowerCost.blast
        case .frost:   return EconomyConstants.TowerCost.frost
        case .pierce:  return 130
        case .core:    return 180
        case .inferno: return 200
        case .tesla:   return 300
        case .nova:    return 500
        }
    }

    var damage: CGFloat {
        switch self {
        case .bolt:    return 20
        case .blast:   return 15
        case .frost:   return 5
        case .pierce:  return 25
        case .core:    return 45
        case .inferno: return 18
        case .tesla:   return 35
        case .nova:    return 90
        }
    }

    var attackSpeed: TimeInterval {
        switch self {
        case .bolt:    return 1.0 / 1.2
        case .blast:   return 1.0 / 0.5
        case .frost:   return 1.0 / 0.8
        case .pierce:  return 1.0 / 1.0
        case .core:    return 1.0 / 0.7
        case .inferno: return 1.0 / 1.5
        case .tesla:   return 1.0 / 0.9
        case .nova:    return 1.0 / 0.35
        }
    }

    var range: CGFloat {
        switch self {
        case .bolt:    return 192
        case .blast:   return 160
        case .frost:   return 192
        case .pierce:  return 192
        case .core:    return 160
        case .inferno: return 160
        case .tesla:   return 200
        case .nova:    return 220
        }
    }

    var blastRadius: CGFloat? {
        switch self {
        case .blast: return 96
        case .nova:  return 160
        default:     return nil
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
        }
    }

    var nodeColor: SKColor {
        switch self {
        case .bolt:    return SKColor(red: 0.0,  green: 0.78, blue: 1.0,  alpha: 1)
        case .blast:   return SKColor(red: 1.0,  green: 0.42, blue: 0.0,  alpha: 1)
        case .frost:   return SKColor(red: 0.55, green: 0.31, blue: 1.0,  alpha: 1)
        case .pierce:  return SKColor(red: 0.6,  green: 1.0,  blue: 0.2,  alpha: 1)
        case .core:    return SKColor(red: 1.0,  green: 0.27, blue: 0.0,  alpha: 1)
        case .inferno: return SKColor(red: 1.0,  green: 0.15, blue: 0.0,  alpha: 1)
        case .tesla:   return SKColor(red: 0.4,  green: 0.8,  blue: 1.0,  alpha: 1)
        case .nova:    return SKColor(red: 1.0,  green: 0.95, blue: 0.5,  alpha: 1)
        }
    }

    var projectileColor: SKColor {
        switch self {
        case .bolt:    return SKColor.yellow
        case .blast:   return SKColor.orange
        case .frost:   return SKColor.cyan
        case .pierce:  return SKColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 1)
        case .core:    return SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1)
        case .inferno: return SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 1)
        case .tesla:   return SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1)
        case .nova:    return SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1)
        }
    }

    var diamondCost: Int {
        switch self {
        case .inferno: return 50
        case .tesla:   return 150
        case .nova:    return 300
        default:       return 0
        }
    }

    var isPremium: Bool { diamondCost > 0 }

    var typeAdvantageHint: String? {
        switch self {
        case .bolt:    return "+50% vs Runners"
        case .blast:   return "+60% vs Swarms"
        case .frost:   return nil
        case .pierce:  return "+100% vs Shields"
        case .core:    return "+60% vs Tanks"
        case .inferno: return "+75% vs Ghosts"
        case .tesla:   return "+75% vs Swarms"
        case .nova:    return "+50% vs Boss"
        }
    }

    func damageMultiplier(against enemyType: EnemyType) -> CGFloat {
        switch self {
        case .bolt:    return (enemyType == .runner || enemyType == .splitter) ? 1.5 : 1.0
        case .blast:   return enemyType == .swarm ? 1.6 : 1.0
        case .frost:   return 1.0
        case .pierce:  return enemyType == .shield ? 2.0 : 1.0
        case .core:    return enemyType == .tank ? 1.6 : 1.0
        case .inferno: return enemyType == .ghost ? 1.75 : 1.0
        case .tesla:   return enemyType == .swarm ? 1.75 : 1.0
        case .nova:    return enemyType == .boss ? 1.5 : 1.0
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
    func scaledDamage() -> CGFloat {
        return type.damage * (1.0 + 0.25 * CGFloat(level - 1))
    }

    func effectiveAttackInterval() -> TimeInterval {
        return type.attackSpeed / (1.0 + 0.08 * Double(level - 1))
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
