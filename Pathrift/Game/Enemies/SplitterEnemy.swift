import Foundation
import CoreGraphics
import SpriteKit

final class SplitterEnemy: EnemyNode {
    let type: EnemyType = .splitter
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 90
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = 8
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 80 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 90
        self.node = SplitterEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Amber diamond body
        let body = SKShapeNode(rectOf: CGSize(width: 18, height: 18), cornerRadius: 3)
        body.fillColor = SKColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1)
        body.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 0.9)
        body.lineWidth = 2
        body.zRotation = .pi / 4  // diamond orientation
        container.addChild(body)

        // Split indicator — two small dots showing it will split
        for xOff: CGFloat in [-6, 6] {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.8)
            dot.strokeColor = SKColor.clear
            dot.position = CGPoint(x: xOff, y: 0)
            container.addChild(dot)
        }

        // Eyes
        let eye = SKShapeNode(circleOfRadius: 2.5)
        eye.fillColor = SKColor.red
        eye.strokeColor = SKColor.clear
        eye.position = CGPoint(x: 0, y: 4)
        container.addChild(eye)

        // Health bar
        let (bg, bar) = SplitterEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        // Pulsing split animation
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.4),
            SKAction.scale(to: 0.95, duration: 0.4)
        ]))
        body.run(pulse)

        return container
    }
}
