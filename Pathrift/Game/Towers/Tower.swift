import Foundation
import CoreGraphics
import SpriteKit

enum TowerType: String, CaseIterable, Identifiable {
    case bolt  = "Bolt"
    case blast = "Blast"
    case frost = "Frost"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var cost: Int {
        switch self {
        case .bolt:  return EconomyConstants.TowerCost.bolt
        case .blast: return EconomyConstants.TowerCost.blast
        case .frost: return EconomyConstants.TowerCost.frost
        }
    }

    var damage: CGFloat {
        switch self {
        case .bolt:  return 20
        case .blast: return 15
        case .frost: return 5
        }
    }

    var attackSpeed: TimeInterval {
        switch self {
        case .bolt:  return 1.0 / 1.2
        case .blast: return 1.0 / 0.5
        case .frost: return 1.0 / 0.8
        }
    }

    var range: CGFloat {
        switch self {
        case .bolt:  return 192
        case .blast: return 160
        case .frost: return 192
        }
    }

    var blastRadius: CGFloat? {
        switch self {
        case .blast: return 96
        default: return nil
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
        }
    }

    var nodeColor: SKColor {
        switch self {
        case .bolt:  return SKColor(red: 0.0,  green: 0.78, blue: 1.0,  alpha: 1)
        case .blast: return SKColor(red: 1.0,  green: 0.42, blue: 0.0,  alpha: 1)
        case .frost: return SKColor(red: 0.55, green: 0.31, blue: 1.0,  alpha: 1)
        }
    }

    var projectileColor: SKColor {
        switch self {
        case .bolt:  return SKColor.yellow
        case .blast: return SKColor.orange
        case .frost: return SKColor.cyan
        }
    }
}

protocol Tower: AnyObject {
    var type: TowerType { get }
    var position: CGPoint { get set }
    var slotId: Int { get }
    var lastFiredTime: TimeInterval { get set }
    var node: SKNode { get }
    var level: Int { get set }
    var totalInvested: Int { get set }

    func canFire(at currentTime: TimeInterval) -> Bool
    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval)
    func buildNode() -> SKNode
}

extension Tower {
    func canFire(at currentTime: TimeInterval) -> Bool {
        return currentTime - lastFiredTime >= type.attackSpeed
    }

    func isInRange(_ enemy: EnemyNode) -> Bool {
        let dx = enemy.node.position.x - position.x
        let dy = enemy.node.position.y - position.y
        return sqrt(dx * dx + dy * dy) <= type.range
    }
}
