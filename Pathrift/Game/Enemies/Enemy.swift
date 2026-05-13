import Foundation
import CoreGraphics
import SpriteKit

protocol EnemyNode: AnyObject {
    var type: EnemyType { get }
    var maxHP: CGFloat { get }
    var currentHP: CGFloat { get set }
    var baseSpeed: CGFloat { get }
    var currentSpeed: CGFloat { get set }
    var armor: CGFloat { get }
    var goldReward: Int { get }
    var pathProgress: CGFloat { get set }
    var isAlive: Bool { get }
    var isDead: Bool { get }
    var hasReachedEnd: Bool { get set }
    var node: SKNode { get }
    var slowTimer: TimeInterval { get set }

    func applyDamage(_ amount: CGFloat)
    func applySlow(factor: CGFloat, duration: TimeInterval)
    func updateMovement(deltaTime: TimeInterval)
    func updateSlowEffect(currentTime: TimeInterval)
}

extension EnemyNode {
    // Pierce: bypasses shield HP, goes straight to currentHP
    func applyDamagePiercing(_ rawAmount: CGFloat) {
        let reducedDamage = rawAmount * (1.0 - armor)
        currentHP = max(0, currentHP - reducedDamage)
        refreshHealthBar()
        if isDead {
            spawnDeathParticles()
            node.removeFromParent()
        }
    }

    // Core: armor is halved (penetration factor applied)
    func applyDamageWithPenetration(_ rawAmount: CGFloat, penetration: CGFloat) {
        let effectiveArmor = armor * (1.0 - penetration)
        let reducedDamage = rawAmount * (1.0 - effectiveArmor)
        currentHP = max(0, currentHP - reducedDamage)
        refreshHealthBar()
        if isDead {
            spawnDeathParticles()
            node.removeFromParent()
        }
    }
}

extension EnemyNode {
    var isAlive: Bool { currentHP > 0 && !hasReachedEnd }
    var isDead: Bool { currentHP <= 0 }

    func applyDamage(_ rawAmount: CGFloat) {
        let reducedDamage = rawAmount * (1.0 - armor)
        currentHP = max(0, currentHP - reducedDamage)
        refreshHealthBar()
        if isDead {
            spawnDeathParticles()
            node.removeFromParent()
        }
    }

    func applySlow(factor: CGFloat, duration: TimeInterval) {
        currentSpeed = baseSpeed * (1.0 - factor)
        slowTimer = CACurrentMediaTime() + duration
        node.alpha = 0.7
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            if CACurrentMediaTime() >= self.slowTimer {
                self.currentSpeed = self.baseSpeed
                self.node.alpha = 1.0
            }
        }
    }

    func updateSlowEffect(currentTime: TimeInterval) {
        if currentTime >= slowTimer && currentSpeed < baseSpeed {
            currentSpeed = baseSpeed
            node.alpha = 1.0
        }
    }

    func updateMovement(deltaTime: TimeInterval) {
        let pathLength = PathSystem.totalPathLength()
        guard pathLength > 0 else { return }
        let distanceToMove = currentSpeed * CGFloat(deltaTime)
        pathProgress += distanceToMove / pathLength

        if pathProgress >= 1.0 {
            hasReachedEnd = true
            node.removeFromParent()
            return
        }

        let newPos = PathSystem.position(at: pathProgress)
        node.position = newPos
    }

    func refreshHealthBar() {
        guard let bar = node.childNode(withName: "healthBar") as? SKShapeNode else { return }
        let ratio = max(0, currentHP / maxHP)
        let totalWidth: CGFloat = 32
        let filledWidth = totalWidth * ratio

        let path = CGMutablePath()
        path.addRect(CGRect(x: -totalWidth / 2, y: 0, width: filledWidth, height: 4))
        bar.path = path

        let color: SKColor
        if ratio > 0.6 {
            color = SKColor.green
        } else if ratio > 0.3 {
            color = SKColor.yellow
        } else {
            color = SKColor.red
        }
        bar.fillColor = color
    }

    func spawnDeathParticles() {
        let pos = node.position
        guard let scene = node.scene else { return }

        for _ in 0..<6 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = SKColor.orange
            particle.position = pos
            particle.zPosition = 6
            scene.addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 20...50)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    static func makeHealthBarNodes() -> (bg: SKShapeNode, bar: SKShapeNode) {
        let bgPath = CGMutablePath()
        bgPath.addRect(CGRect(x: -16, y: 0, width: 32, height: 4))
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor = SKColor.darkGray
        bg.strokeColor = SKColor.clear
        bg.name = "healthBarBg"
        bg.position = CGPoint(x: 0, y: 24)

        let barPath = CGMutablePath()
        barPath.addRect(CGRect(x: -16, y: 0, width: 32, height: 4))
        let bar = SKShapeNode(path: barPath)
        bar.fillColor = SKColor.green
        bar.strokeColor = SKColor.clear
        bar.name = "healthBar"
        bar.position = CGPoint(x: 0, y: 24)

        return (bg, bar)
    }
}
