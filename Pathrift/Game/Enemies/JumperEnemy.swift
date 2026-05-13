import Foundation
import CoreGraphics
import SpriteKit

final class JumperEnemy: EnemyNode {
    let type: EnemyType = .jumper
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 55
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.10
    let goldReward: Int = 15
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode
    var lastJumpTime: TimeInterval

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 120 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 55
        self.lastJumpTime = CACurrentMediaTime()
        self.node = JumperEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Teal body
        let body = SKShapeNode(circleOfRadius: 14)
        body.fillColor = SKColor(red: 0.0, green: 0.7, blue: 0.5, alpha: 1)
        body.strokeColor = SKColor(red: 0.0, green: 0.9, blue: 0.6, alpha: 1)
        body.lineWidth = 2
        container.addChild(body)

        // Jump coil springs
        for xOff: CGFloat in [-5, 5] {
            let spring = SKShapeNode(rectOf: CGSize(width: 3, height: 10), cornerRadius: 1)
            spring.fillColor = SKColor(red: 0.0, green: 0.9, blue: 0.6, alpha: 0.7)
            spring.strokeColor = SKColor.clear
            spring.position = CGPoint(x: xOff, y: -10)
            container.addChild(spring)
        }

        // Eyes — alert look
        for xOff: CGFloat in [-4, 4] {
            let eye = SKShapeNode(circleOfRadius: 3)
            eye.fillColor = SKColor.white
            eye.strokeColor = SKColor.clear
            eye.position = CGPoint(x: xOff, y: 4)
            container.addChild(eye)

            let pupil = SKShapeNode(circleOfRadius: 1.5)
            pupil.fillColor = SKColor(red: 0.0, green: 0.3, blue: 0.2, alpha: 1)
            pupil.strokeColor = SKColor.clear
            pupil.position = CGPoint(x: xOff, y: 4)
            container.addChild(pupil)
        }

        // Health bar
        let (bg, bar) = JumperEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        // Ready-to-jump subtle bounce
        let bounce = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.5),
            SKAction.moveBy(x: 0, y: -3, duration: 0.5)
        ]))
        body.run(bounce)

        return container
    }

    func updateMovement(deltaTime: TimeInterval) {
        let pathLength = PathSystem.totalPathLength()
        guard pathLength > 0 else { return }
        let distanceToMove = currentSpeed * CGFloat(deltaTime)
        pathProgress += distanceToMove / pathLength

        // Jump check
        let now = CACurrentMediaTime()
        if now - lastJumpTime >= 3.0 {
            lastJumpTime = now
            pathProgress = min(1.0, pathProgress + 0.20)

            // Visual jump flash
            let flash = SKAction.sequence([
                SKAction.scale(to: 1.4, duration: 0.08),
                SKAction.scale(to: 0.85, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            node.run(flash)

            // Teal flash color
            if let body = node.children.first as? SKShapeNode {
                let colorFlash = SKAction.sequence([
                    SKAction.colorize(with: SKColor.white, colorBlendFactor: 0.8, duration: 0.05),
                    SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.15)
                ])
                body.run(colorFlash)
            }
        }

        if pathProgress >= 1.0 {
            hasReachedEnd = true
            node.removeFromParent()
            return
        }

        let newPos = PathSystem.position(at: pathProgress)
        node.position = newPos

        // Update path layer
        let newLayer = PathSystem.layerAt(progress: pathProgress)
        if newLayer != pathLayer {
            pathLayer = newLayer
            let targetScale: CGFloat = pathLayer == .bridge ? 1.15 : 1.0
            node.run(SKAction.scale(to: targetScale, duration: 0.1))
        }
    }
}
