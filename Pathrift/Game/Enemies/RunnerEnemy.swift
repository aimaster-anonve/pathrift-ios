import Foundation
import CoreGraphics
import SpriteKit

final class RunnerEnemy: EnemyNode {
    let type: EnemyType = .runner
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 72   // ~half speed — gives towers time to fire
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = EconomyConstants.EnemyGoldReward.runner
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 50 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 150
        self.node = RunnerEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Body — diamond/angular shape for speed feel
        let body = SKShapeNode(rectOf: CGSize(width: 16, height: 20), cornerRadius: 4)
        body.fillColor = SKColor(red: 0.1, green: 0.8, blue: 0.25, alpha: 1)
        body.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 0.8)
        body.lineWidth = 1.5
        container.addChild(body)

        // Speed stripes
        for yOff: CGFloat in [3, -3] {
            let stripe = SKShapeNode(rectOf: CGSize(width: 10, height: 2), cornerRadius: 1)
            stripe.fillColor = SKColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.5)
            stripe.strokeColor = SKColor.clear
            stripe.position = CGPoint(x: 0, y: yOff)
            container.addChild(stripe)
        }

        // Eyes
        let eye = SKShapeNode(circleOfRadius: 3)
        eye.fillColor = SKColor.red
        eye.strokeColor = SKColor.white
        eye.lineWidth = 1
        eye.position = CGPoint(x: 0, y: 5)
        container.addChild(eye)

        // Health bar
        let (bg, bar) = RunnerEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        // Run animation (subtle bounce)
        let bounce = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 2, duration: 0.15),
            SKAction.moveBy(x: 0, y: -2, duration: 0.15)
        ]))
        body.run(bounce)

        return container
    }
}
