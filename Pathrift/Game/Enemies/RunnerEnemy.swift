import Foundation
import CoreGraphics
import SpriteKit

final class RunnerEnemy: EnemyNode {
    let type: EnemyType = .runner
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 150
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = EconomyConstants.EnemyGoldReward.runner
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
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

        let body = SKShapeNode(rectOf: CGSize(width: 18, height: 18), cornerRadius: 3)
        body.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1)
        body.strokeColor = SKColor.white
        body.lineWidth = 1.5
        container.addChild(body)

        let eye = SKShapeNode(circleOfRadius: 3)
        eye.fillColor = SKColor.white
        eye.position = CGPoint(x: 3, y: 3)
        container.addChild(eye)

        let pupil = SKShapeNode(circleOfRadius: 1.5)
        pupil.fillColor = SKColor.black
        pupil.position = CGPoint(x: 3, y: 3)
        container.addChild(pupil)

        let (bg, bar) = RunnerEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        let label = SKLabelNode(text: "R")
        label.fontColor = SKColor.white
        label.fontSize = 8
        label.fontName = "AvenirNext-Bold"
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: -4, y: 0)
        container.addChild(label)

        let bounce = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 2, duration: 0.2),
            SKAction.moveBy(x: 0, y: -2, duration: 0.2)
        ]))
        body.run(bounce)

        return container
    }
}
