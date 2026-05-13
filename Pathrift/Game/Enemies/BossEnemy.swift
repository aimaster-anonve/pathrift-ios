import Foundation
import CoreGraphics
import SpriteKit

final class BossEnemy: EnemyNode {
    let type: EnemyType = .boss
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 28
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.35       // 35% damage reduction
    let goldReward: Int = 100
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    let node: SKNode

    init(waveNumber: Int) {
        let bossNumber = waveNumber / 10
        let hp = CGFloat(800 + bossNumber * 400)  // scales with each boss cycle
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 28
        self.node = BossEnemy.makeNode(bossNumber: bossNumber)
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    // Override refreshHealthBar for the wider 48pt boss health bar
    func refreshHealthBar() {
        guard let bar = node.childNode(withName: "healthBar") as? SKShapeNode else { return }
        let ratio = max(0, currentHP / maxHP)
        let totalWidth: CGFloat = 48
        let filledWidth = totalWidth * ratio

        let path = CGMutablePath()
        path.addRect(CGRect(x: -totalWidth / 2, y: 0, width: filledWidth, height: 6))
        bar.path = path

        let color: SKColor
        if ratio > 0.6 {
            color = SKColor(red: 0.8, green: 0.2, blue: 1.0, alpha: 1)
        } else if ratio > 0.3 {
            color = SKColor.yellow
        } else {
            color = SKColor.red
        }
        bar.fillColor = color
    }

    private static func makeNode(bossNumber: Int) -> SKNode {
        // Root container — holds the rotating body AND static UI separately
        let container = SKNode()
        container.zPosition = 4

        // --- Rotating body sub-node ---
        let body = SKNode()
        container.addChild(body)

        // Large menacing body
        let bodyShape = SKShapeNode(circleOfRadius: 22)
        bodyShape.fillColor = SKColor(red: 0.6, green: 0.0, blue: 0.7, alpha: 1)
        bodyShape.strokeColor = SKColor(red: 0.9, green: 0.4, blue: 1.0, alpha: 1)
        bodyShape.lineWidth = 3
        body.addChild(bodyShape)

        // Inner core
        let core = SKShapeNode(circleOfRadius: 10)
        core.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.8, alpha: 1)
        core.strokeColor = SKColor.white
        core.lineWidth = 1.5
        body.addChild(core)

        // Outer aura ring
        let aura = SKShapeNode(circleOfRadius: 26)
        aura.fillColor = SKColor.clear
        aura.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 1.0, alpha: 0.4)
        aura.lineWidth = 2
        body.addChild(aura)

        // Spike ornaments (4 diagonal spikes)
        let spikeAngles: [CGFloat] = [.pi/4, 3 * .pi/4, 5 * .pi/4, 7 * .pi/4]
        for angle in spikeAngles {
            let spike = SKShapeNode(rectOf: CGSize(width: 4, height: 14), cornerRadius: 2)
            spike.fillColor = SKColor(red: 0.9, green: 0.5, blue: 1.0, alpha: 0.9)
            spike.strokeColor = SKColor.clear
            spike.position = CGPoint(x: cos(angle) * 20, y: sin(angle) * 20)
            spike.zRotation = angle
            body.addChild(spike)
        }

        // Pulsing aura animation
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.5),
            SKAction.scale(to: 0.92, duration: 0.5)
        ]))
        aura.run(pulse)

        // Slow rotation of body sub-node only
        let rotate = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 3.0))
        body.run(rotate)

        // --- Static UI (label + health bar) — added to root container, not body ---
        let bossLabel = SKLabelNode(text: bossNumber == 1 ? "BOSS" : "BOSS \(bossNumber)")
        bossLabel.fontSize = 9
        bossLabel.fontName = "AvenirNext-Bold"
        bossLabel.fontColor = .white
        bossLabel.verticalAlignmentMode = .center
        bossLabel.horizontalAlignmentMode = .center
        container.addChild(bossLabel)

        // Wide health bar background (48pt)
        let bgPath = CGMutablePath()
        bgPath.addRect(CGRect(x: -24, y: 0, width: 48, height: 6))
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor = SKColor.darkGray
        bg.strokeColor = SKColor.clear
        bg.name = "healthBarBg"
        bg.position = CGPoint(x: 0, y: 30)
        container.addChild(bg)

        let barPath = CGMutablePath()
        barPath.addRect(CGRect(x: -24, y: 0, width: 48, height: 6))
        let bar = SKShapeNode(path: barPath)
        bar.fillColor = SKColor(red: 0.8, green: 0.2, blue: 1.0, alpha: 1)
        bar.strokeColor = SKColor.clear
        bar.name = "healthBar"
        bar.position = CGPoint(x: 0, y: 30)
        container.addChild(bar)

        return container
    }
}
