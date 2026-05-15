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
    var pathLayer: PathLayer = .ground
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

        // Small irregular hexagon (bug-body: 8×10)
        let hexPath = CGMutablePath()
        let hw: CGFloat = 4, hh: CGFloat = 5
        hexPath.move(to: CGPoint(x: 0, y: hh))
        hexPath.addLine(to: CGPoint(x: hw, y: hh/2))
        hexPath.addLine(to: CGPoint(x: hw, y: -hh/2))
        hexPath.addLine(to: CGPoint(x: 0, y: -hh))
        hexPath.addLine(to: CGPoint(x: -hw, y: -hh/2))
        hexPath.addLine(to: CGPoint(x: -hw, y: hh/2))
        hexPath.closeSubpath()
        let body = SKShapeNode(path: hexPath)
        body.fillColor = SKColor(red: 0.25, green: 0.22, blue: 0.00, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.00, green: 0.88, blue: 0.10, alpha: 1.0)
        body.lineWidth = 1.0
        container.addChild(body)

        // 2 antennae
        for side: CGFloat in [-1, 1] {
            let antPath = CGMutablePath()
            antPath.move(to: CGPoint(x: side * 2, y: hh))
            antPath.addLine(to: CGPoint(x: side * 4, y: hh + 5))
            let ant = SKShapeNode(path: antPath)
            ant.strokeColor = SKColor(red: 1.00, green: 0.88, blue: 0.10, alpha: 0.70)
            ant.lineWidth = 0.75
            ant.lineCap = .round
            container.addChild(ant)
        }

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

        // Chaotic wobble animation
        let wobbleDuration = Double.random(in: 0.2...0.3)
        let wobbleDeg = CGFloat.random(in: 4...6) * .pi / 180
        let dash = SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: wobbleDeg, duration: wobbleDuration),
            SKAction.rotate(byAngle: -wobbleDeg, duration: wobbleDuration)
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
