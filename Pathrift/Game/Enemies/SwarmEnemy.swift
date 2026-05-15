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

        // Small irregular hexagon — 5×7pt (0.70× 8×10)
        let hexPath = CGMutablePath()
        let hw: CGFloat = 2.5, hh: CGFloat = 3.5
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
        body.lineWidth = 0.75
        container.addChild(body)

        // 2 antennae
        for side: CGFloat in [-1, 1] {
            let antPath = CGMutablePath()
            antPath.move(to: CGPoint(x: side * 1.5, y: hh))
            antPath.addLine(to: CGPoint(x: side * 3, y: hh + 3.5))
            let ant = SKShapeNode(path: antPath)
            ant.strokeColor = SKColor(red: 1.00, green: 0.88, blue: 0.10, alpha: 0.70)
            ant.lineWidth = 0.5
            ant.lineCap = .round
            container.addChild(ant)
        }

        // Tiny health bar — 14pt wide (0.70× 20), at y=10
        let bgPath = CGMutablePath()
        bgPath.addRect(CGRect(x: -7, y: 0, width: 14, height: 2))
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor = SKColor.darkGray
        bg.strokeColor = SKColor.clear
        bg.name = "healthBarBg"
        bg.position = CGPoint(x: 0, y: 10)
        container.addChild(bg)

        let barPath = CGMutablePath()
        barPath.addRect(CGRect(x: -7, y: 0, width: 14, height: 2))
        let bar = SKShapeNode(path: barPath)
        bar.fillColor = SKColor.yellow
        bar.strokeColor = SKColor.clear
        bar.name = "healthBar"
        bar.position = CGPoint(x: 0, y: 10)
        container.addChild(bar)

        let wobbleDuration = Double.random(in: 0.2...0.3)
        let wobbleDeg = CGFloat.random(in: 4...6) * .pi / 180
        let dash = SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: wobbleDeg, duration: wobbleDuration),
            SKAction.rotate(byAngle: -wobbleDeg, duration: wobbleDuration)
        ]))
        body.run(dash)

        return container
    }

    // Override refreshHealthBar for the narrower swarm health bar
    func refreshHealthBar() {
        guard let bar = node.childNode(withName: "healthBar") as? SKShapeNode else { return }
        let ratio = max(0, currentHP / maxHP)
        let totalWidth: CGFloat = 14
        let filledWidth = totalWidth * ratio

        let path = CGMutablePath()
        path.addRect(CGRect(x: -7, y: 0, width: filledWidth, height: 2))
        bar.path = path

        bar.fillColor = ratio > 0.5 ? SKColor.yellow : SKColor.red
    }
}
