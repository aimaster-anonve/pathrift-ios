import Foundation
import CoreGraphics
import SpriteKit

final class TankEnemy: EnemyNode {
    let type: EnemyType = .tank
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 32   // deliberately slow — requires sustained DPS
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.2
    let goldReward: Int = EconomyConstants.EnemyGoldReward.tank
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    let node: SKNode

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 300 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 50
        self.node = TankEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Treads (bottom rectangles)
        for xOff: CGFloat in [-14, 14] {
            let tread = SKShapeNode(rectOf: CGSize(width: 8, height: 24), cornerRadius: 3)
            tread.fillColor = SKColor(red: 0.3, green: 0.15, blue: 0.1, alpha: 1)
            tread.strokeColor = SKColor(red: 0.5, green: 0.25, blue: 0.15, alpha: 0.8)
            tread.lineWidth = 1
            tread.position = CGPoint(x: xOff, y: 0)
            container.addChild(tread)
        }

        // Hull
        let hull = SKShapeNode(rectOf: CGSize(width: 24, height: 20), cornerRadius: 3)
        hull.fillColor = SKColor(red: 0.55, green: 0.1, blue: 0.08, alpha: 1)
        hull.strokeColor = SKColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 1)
        hull.lineWidth = 2
        hull.position = CGPoint(x: 0, y: 2)
        container.addChild(hull)

        // Turret dome
        let turret = SKShapeNode(circleOfRadius: 9)
        turret.fillColor = SKColor(red: 0.45, green: 0.08, blue: 0.06, alpha: 1)
        turret.strokeColor = SKColor(red: 1.0, green: 0.25, blue: 0.2, alpha: 0.9)
        turret.lineWidth = 1.5
        turret.position = CGPoint(x: 0, y: 6)
        container.addChild(turret)

        // Cannon barrel
        let cannon = SKShapeNode(rectOf: CGSize(width: 5, height: 14), cornerRadius: 2)
        cannon.fillColor = SKColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
        cannon.strokeColor = SKColor.clear
        cannon.position = CGPoint(x: 0, y: 18)
        container.addChild(cannon)

        // Armor glow
        let armorGlow = SKShapeNode(rectOf: CGSize(width: 28, height: 22), cornerRadius: 4)
        armorGlow.fillColor = SKColor.clear
        armorGlow.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.3)
        armorGlow.lineWidth = 1.5
        armorGlow.position = CGPoint(x: 0, y: 2)
        container.addChild(armorGlow)

        // Health bar (positioned higher for tall tank)
        let (bg, bar) = TankEnemy.makeHealthBarNodes()
        bg.position = CGPoint(x: 0, y: 32)
        bar.position = CGPoint(x: 0, y: 32)
        container.addChild(bg)
        container.addChild(bar)

        // Slow rumble
        let rumble = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 1.5, y: 0, duration: 0.12),
            SKAction.moveBy(x: -1.5, y: 0, duration: 0.12)
        ]))
        container.run(rumble)

        return container
    }
}
