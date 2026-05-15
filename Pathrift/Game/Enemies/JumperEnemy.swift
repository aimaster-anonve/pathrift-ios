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

        // Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 18, height: 6))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -14)
        container.addChild(shadow)

        // Coil spring legs (zigzag lines beneath circle)
        for xOff: CGFloat in [-3, 3] {
            let springPath = CGMutablePath()
            springPath.move(to: CGPoint(x: xOff, y: -9))
            springPath.addLine(to: CGPoint(x: xOff + 1.5, y: -11))
            springPath.addLine(to: CGPoint(x: xOff - 1.5, y: -12.5))
            springPath.addLine(to: CGPoint(x: xOff + 1.5, y: -14))
            let spring = SKShapeNode(path: springPath)
            spring.strokeColor = SKColor(red: 0.10, green: 0.80, blue: 0.85, alpha: 0.80)
            spring.lineWidth = 1.0
            spring.lineCap = .round
            spring.name = "spring"
            container.addChild(spring)
        }

        // Teal circle body
        let body = SKShapeNode(circleOfRadius: 9)
        body.fillColor = SKColor(red: 0.00, green: 0.35, blue: 0.38, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.10, green: 0.80, blue: 0.85, alpha: 1.0)
        body.lineWidth = 1.5
        container.addChild(body)

        // Jump charge ring
        let chargeRing = SKShapeNode(circleOfRadius: 13)
        chargeRing.fillColor = .clear
        chargeRing.strokeColor = SKColor(red: 0.10, green: 0.80, blue: 0.85, alpha: 0.30)
        chargeRing.lineWidth = 1.0
        container.addChild(chargeRing)

        // Health bar
        let (bg, bar) = JumperEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        // Spring compress/extend coiling animation
        container.children.filter { $0.name == "spring" }.forEach { spring in
            spring.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scaleY(to: 0.7, duration: 0.3),
                SKAction.scaleY(to: 1.3, duration: 0.2)
            ])))
        }

        return container
    }

    func updateMovement(deltaTime: TimeInterval) {
        let pathLength = PathSystem.totalPathLength()
        guard pathLength > 0 else { return }
        let distanceToMove = currentSpeed * CGFloat(deltaTime)
        pathProgress += distanceToMove / pathLength

        // Jump check
        let now = CACurrentMediaTime()
        if now - lastJumpTime >= 5.0 {
            lastJumpTime = now
            pathProgress = min(1.0, pathProgress + 0.10)

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
