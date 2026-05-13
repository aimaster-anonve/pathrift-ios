import Foundation
import CoreGraphics
import SpriteKit

final class SwarmEnemy: EnemyNode {
    let type: EnemyType = .swarm
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 120
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = 3
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    let node: SKNode

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 25 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 120
        self.node = SwarmEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        let body = SKShapeNode(circleOfRadius: 7)
        body.fillColor = SKColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1)
        body.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1)
        body.lineWidth = 1.5
        container.addChild(body)

        // Tiny health bar
        let bgPath = CGMutablePath()
        bgPath.addRect(CGRect(x: -10, y: 0, width: 20, height: 3))
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor = SKColor.darkGray
        bg.strokeColor = SKColor.clear
        bg.name = "healthBarBg"
        bg.position = CGPoint(x: 0, y: 14)
        container.addChild(bg)

        let barPath = CGMutablePath()
        barPath.addRect(CGRect(x: -10, y: 0, width: 20, height: 3))
        let bar = SKShapeNode(path: barPath)
        bar.fillColor = SKColor.yellow
        bar.strokeColor = SKColor.clear
        bar.name = "healthBar"
        bar.position = CGPoint(x: 0, y: 14)
        container.addChild(bar)

        // Override refreshHealthBar for narrower bar — handled generically by protocol extension
        // (uses "healthBar" node name, scales to 20pt instead of 32pt via direct path manipulation)

        // Erratic dash animation on body
        let randomDx1 = CGFloat.random(in: -3...3)
        let randomDy1 = CGFloat.random(in: -3...3)
        let randomDx2 = CGFloat.random(in: -3...3)
        let randomDy2 = CGFloat.random(in: -3...3)
        let dash = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: randomDx1, y: randomDy1, duration: 0.1),
            SKAction.moveBy(x: randomDx2, y: randomDy2, duration: 0.1)
        ]))
        body.run(dash)

        return container
    }

    // Override refreshHealthBar for the narrower 20pt swarm health bar
    func refreshHealthBar() {
        guard let bar = node.childNode(withName: "healthBar") as? SKShapeNode else { return }
        let ratio = max(0, currentHP / maxHP)
        let totalWidth: CGFloat = 20
        let filledWidth = totalWidth * ratio

        let path = CGMutablePath()
        path.addRect(CGRect(x: -10, y: 0, width: filledWidth, height: 3))
        bar.path = path

        bar.fillColor = ratio > 0.5 ? SKColor.yellow : SKColor.red
    }
}
