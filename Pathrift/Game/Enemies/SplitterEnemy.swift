import Foundation
import CoreGraphics
import SpriteKit

final class SplitterEnemy: EnemyNode {
    let type: EnemyType = .splitter
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 55
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = 8
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 110 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 55
        self.node = SplitterEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Diamond body (rhombus 18×18)
        let diamPath = CGMutablePath()
        diamPath.move(to: CGPoint(x: 0, y: 9))
        diamPath.addLine(to: CGPoint(x: 9, y: 0))
        diamPath.addLine(to: CGPoint(x: 0, y: -9))
        diamPath.addLine(to: CGPoint(x: -9, y: 0))
        diamPath.closeSubpath()
        let body = SKShapeNode(path: diamPath)
        body.fillColor = SKColor(red: 0.30, green: 0.14, blue: 0.00, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.00, green: 0.60, blue: 0.10, alpha: 1.0)
        body.lineWidth = 1.5
        container.addChild(body)

        // Glowing split seam (vertical line through center)
        let seamPath = CGMutablePath()
        seamPath.move(to: CGPoint(x: 0, y: 9))
        seamPath.addLine(to: CGPoint(x: 0, y: -9))
        let seam = SKShapeNode(path: seamPath)
        seam.strokeColor = SKColor(red: 1.00, green: 0.80, blue: 0.20, alpha: 0.90)
        seam.lineWidth = 1.5
        seam.lineCap = .round
        seam.name = "seam"
        container.addChild(seam)

        // Health bar
        let (bg, bar) = SplitterEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        // Seam glow pulse (alpha 0.60 → 1.00)
        seam.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.60, duration: 0.4),
            SKAction.fadeAlpha(to: 1.00, duration: 0.4)
        ])))

        return container
    }
}
