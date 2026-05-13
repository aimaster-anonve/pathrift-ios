import Foundation
import CoreGraphics
import SpriteKit

final class TankEnemy: EnemyNode {
    let type: EnemyType = .tank
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 50
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

        let body = SKShapeNode(rectOf: CGSize(width: 30, height: 26), cornerRadius: 4)
        body.fillColor = SKColor(red: 0.7, green: 0.2, blue: 0.15, alpha: 1)
        body.strokeColor = SKColor.white
        body.lineWidth = 2
        container.addChild(body)

        let armor1 = SKShapeNode(rectOf: CGSize(width: 26, height: 8), cornerRadius: 2)
        armor1.fillColor = SKColor(red: 0.5, green: 0.15, blue: 0.1, alpha: 1)
        armor1.position = CGPoint(x: 0, y: 6)
        container.addChild(armor1)

        let armor2 = SKShapeNode(rectOf: CGSize(width: 26, height: 8), cornerRadius: 2)
        armor2.fillColor = SKColor(red: 0.5, green: 0.15, blue: 0.1, alpha: 1)
        armor2.position = CGPoint(x: 0, y: -4)
        container.addChild(armor2)

        let cannon = SKShapeNode(rectOf: CGSize(width: 8, height: 18), cornerRadius: 2)
        cannon.fillColor = SKColor.gray
        cannon.position = CGPoint(x: 0, y: 18)
        container.addChild(cannon)

        let (bg, bar) = TankEnemy.makeHealthBarNodes()
        bg.position = CGPoint(x: 0, y: 30)
        bar.position = CGPoint(x: 0, y: 30)
        container.addChild(bg)
        container.addChild(bar)

        let label = SKLabelNode(text: "T")
        label.fontColor = SKColor.white
        label.fontSize = 10
        label.fontName = "AvenirNext-Bold"
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        let rumble = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 1, y: 0, duration: 0.15),
            SKAction.moveBy(x: -1, y: 0, duration: 0.15)
        ]))
        body.run(rumble)

        return container
    }
}
