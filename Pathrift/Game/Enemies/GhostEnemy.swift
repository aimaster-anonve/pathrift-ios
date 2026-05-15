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
    var pathLayer: PathLayer = .ground
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
        container.alpha = 0.70  // semi-transparent by default

        // Soft circle body (purple)
        let body = SKShapeNode(circleOfRadius: 10)
        body.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.80, alpha: 0.65)
        body.strokeColor = SKColor(red: 0.75, green: 0.55, blue: 1.00, alpha: 0.80)
        body.lineWidth = 1.0
        container.addChild(body)

        // Wispy trailing ellipses (behind movement direction = below in +Y up world)
        let trailSizes: [(CGFloat, CGFloat, CGFloat)] = [(10, 6, 0.50), (8, 4, 0.30), (6, 3, 0.15)]
        for (i, (tw, th, ta)) in trailSizes.enumerated() {
            let trail = SKShapeNode(ellipseOf: CGSize(width: tw, height: th))
            trail.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.80, alpha: ta)
            trail.strokeColor = .clear
            trail.position = CGPoint(x: 0, y: CGFloat(-12 - i * 8))
            container.addChild(trail)
        }

        // Ghost float: Y ±3 over 1.5s
        container.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.75),
            SKAction.moveBy(x: 0, y: -3, duration: 0.75)
        ])))

        // Phase animation: alpha breathes 0.55 → 0.85
        container.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.55, duration: 1.0),
            SKAction.fadeAlpha(to: 0.85, duration: 1.0)
        ])))

        let (bg, bar) = GhostEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        return container
    }
}
