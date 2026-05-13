import Foundation
import CoreGraphics
import SpriteKit

final class GhostEnemy: EnemyNode {
    let type: EnemyType = .ghost
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 95
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = 10
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    let node: SKNode

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 90 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 95
        self.node = GhostEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    // Override applySlow — ghost is 90% immune to frost slow
    func applySlow(factor: CGFloat, duration: TimeInterval) {
        // Only 10% of the slow effect applies
        let reducedFactor = factor * 0.10
        currentSpeed = baseSpeed * (1.0 - reducedFactor)
        slowTimer = CACurrentMediaTime() + duration * 0.3
        // Subtle visual cue (ghost barely reacts)
        node.alpha = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.3) { [weak self] in
            guard let self = self else { return }
            self.currentSpeed = self.baseSpeed
            self.node.alpha = 0.75
        }
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4
        container.alpha = 0.75  // semi-transparent

        let body = SKShapeNode(circleOfRadius: 13)
        body.fillColor = SKColor(red: 0.7, green: 0.9, blue: 0.7, alpha: 0.8)
        body.strokeColor = SKColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 0.9)
        body.lineWidth = 1.5
        container.addChild(body)

        // Inner glow
        let glow = SKShapeNode(circleOfRadius: 7)
        glow.fillColor = SKColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 0.6)
        glow.strokeColor = SKColor.clear
        container.addChild(glow)

        // Eerie flicker animation
        let flicker = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.3),
            SKAction.fadeAlpha(to: 0.85, duration: 0.4),
            SKAction.fadeAlpha(to: 0.6, duration: 0.2),
            SKAction.fadeAlpha(to: 0.85, duration: 0.3)
        ]))
        container.run(flicker)

        let (bg, bar) = GhostEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        return container
    }
}
