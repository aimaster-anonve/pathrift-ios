import Foundation
import CoreGraphics
import SpriteKit

final class ArtilleryTower: Tower {
    let type: TowerType = .artillery
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    /// Called by GameScene to apply AoE damage when artillery shell impacts.
    var artilleryDamageCallback: ((CGPoint, CGFloat, CGFloat) -> Void)?

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = TowerType.artillery.cost
        self.node = ArtilleryTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        let brass = SKColor(red: 0.8, green: 0.53, blue: 0.0, alpha: 1)
        let darkBrass = SKColor(red: 0.45, green: 0.28, blue: 0.0, alpha: 1)

        // Heavy base
        let base = SKShapeNode(rectOf: CGSize(width: 40, height: 8), cornerRadius: 3)
        base.fillColor = darkBrass
        base.strokeColor = brass.withAlphaComponent(0.6)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -14)
        container.addChild(base)

        // Thick square body
        let body = SKShapeNode(rectOf: CGSize(width: 30, height: 26), cornerRadius: 5)
        body.fillColor = SKColor(red: 0.25, green: 0.15, blue: 0.0, alpha: 1)
        body.strokeColor = brass
        body.lineWidth = 2
        container.addChild(body)

        // Brass core
        let core = SKShapeNode(circleOfRadius: 7)
        core.fillColor = brass
        core.strokeColor = SKColor.clear
        container.addChild(core)

        // Wide artillery barrel (angled top)
        let barrel = SKShapeNode(rectOf: CGSize(width: 10, height: 18), cornerRadius: 3)
        barrel.fillColor = darkBrass
        barrel.strokeColor = brass.withAlphaComponent(0.7)
        barrel.lineWidth = 1.5
        barrel.position = CGPoint(x: 0, y: 18)
        container.addChild(barrel)

        // Barrel opening
        let muzzle = SKShapeNode(rectOf: CGSize(width: 12, height: 4), cornerRadius: 2)
        muzzle.fillColor = brass
        muzzle.strokeColor = SKColor.clear
        muzzle.position = CGPoint(x: 0, y: 27)
        container.addChild(muzzle)

        // Side wheels
        for xOff: CGFloat in [-12, 12] {
            let wheel = SKShapeNode(circleOfRadius: 5)
            wheel.fillColor = darkBrass
            wheel.strokeColor = brass.withAlphaComponent(0.5)
            wheel.lineWidth = 1
            wheel.position = CGPoint(x: xOff, y: -10)
            container.addChild(wheel)
        }

        // Slow ember glow on core
        let glow = SKAction.repeatForever(SKAction.sequence([
            SKAction.colorize(with: SKColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1), colorBlendFactor: 0.6, duration: 0.8),
            SKAction.colorize(with: brass, colorBlendFactor: 0, duration: 0.8)
        ]))
        core.run(glow)

        return container
    }

    func buildNode() -> SKNode {
        ArtilleryTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let brass = SKColor(red: 0.8, green: 0.53, blue: 0.0, alpha: 1)

        // Artillery shell (larger projectile, arcing path)
        let shell = SKShapeNode(circleOfRadius: 7)
        shell.fillColor = type.projectileColor
        shell.strokeColor = SKColor.white
        shell.lineWidth = 1.5
        shell.position = position
        shell.zPosition = 5
        scene.addChild(shell)

        let targetPos = enemy.node.position
        let blastRadius = type.blastRadius ?? 80
        let damage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        let callback = artilleryDamageCallback

        // Create arcing path: rise in the middle
        let midX = (position.x + targetPos.x) / 2
        let midY = max(position.y, targetPos.y) + 60  // arc peak
        let arcMid = CGPoint(x: midX, y: midY)

        // Use two-step move to simulate arc
        let rise = SKAction.move(to: arcMid, duration: 0.2)
        let fall = SKAction.move(to: targetPos, duration: 0.15)
        rise.timingMode = .easeOut
        fall.timingMode = .easeIn

        let explode = SKAction.run { [weak scene] in
            shell.removeFromParent()
            guard let scene = scene else { return }

            // Explosion circle
            let explosion = SKShapeNode(circleOfRadius: CGFloat(blastRadius))
            explosion.fillColor = brass.withAlphaComponent(0.35)
            explosion.strokeColor = brass
            explosion.lineWidth = 2.5
            explosion.position = targetPos
            explosion.zPosition = 5
            scene.addChild(explosion)

            // Inner heat core
            let heat = SKShapeNode(circleOfRadius: 20)
            heat.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.8)
            heat.strokeColor = SKColor.clear
            heat.position = targetPos
            heat.zPosition = 6
            scene.addChild(heat)

            explosion.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.4, duration: 0.22),
                    SKAction.fadeOut(withDuration: 0.22)
                ]),
                SKAction.removeFromParent()
            ]))
            heat.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 2.0, duration: 0.18),
                    SKAction.fadeOut(withDuration: 0.18)
                ]),
                SKAction.removeFromParent()
            ]))

            // Shockwave ring
            let ring = SKShapeNode(circleOfRadius: 10)
            ring.fillColor = SKColor.clear
            ring.strokeColor = brass
            ring.lineWidth = 2
            ring.position = targetPos
            ring.zPosition = 5
            scene.addChild(ring)
            ring.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: CGFloat(blastRadius) / 10, duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.25)
                ]),
                SKAction.removeFromParent()
            ]))

            callback?(targetPos, CGFloat(blastRadius), damage)
        }

        shell.run(SKAction.sequence([rise, fall, explode]))

        // Muzzle shake on tower
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 2, y: 4, duration: 0.04),
            SKAction.moveBy(x: -4, y: -8, duration: 0.04),
            SKAction.moveBy(x: 2, y: 4, duration: 0.04)
        ])
        node.run(shake)
    }
}
