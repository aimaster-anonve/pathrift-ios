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

        let brass = SKColor(red: 0.75, green: 0.58, blue: 0.12, alpha: 1.0)

        // Floor shadow — 28pt (0.70× 40)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 7))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -10)
        container.addChild(shadow)

        // Wide squat hexagon body — 21×15pt (0.70× 30×22)
        let hexPath = CGMutablePath()
        let hw: CGFloat = 10.5, hh: CGFloat = 7.5
        hexPath.move(to: CGPoint(x: -hw + 3.5, y: hh))
        hexPath.addLine(to: CGPoint(x: hw - 3.5, y: hh))
        hexPath.addLine(to: CGPoint(x: hw, y: 0))
        hexPath.addLine(to: CGPoint(x: hw - 3.5, y: -hh))
        hexPath.addLine(to: CGPoint(x: -hw + 3.5, y: -hh))
        hexPath.addLine(to: CGPoint(x: -hw, y: 0))
        hexPath.closeSubpath()
        let body = SKShapeNode(path: hexPath)
        body.fillColor = SKColor(red: 0.14, green: 0.10, blue: 0.01, alpha: 1.0)
        body.strokeColor = brass
        body.lineWidth = 1.5
        container.addChild(body)

        // 2 horizontal band stripes
        for yOff: CGFloat in [-1.5, 1.5] {
            let band = SKShapeNode(rectOf: CGSize(width: 18, height: 1.5))
            band.fillColor = SKColor(red: 0.75, green: 0.58, blue: 0.12, alpha: 0.40)
            band.strokeColor = .clear
            band.position = CGPoint(x: 0, y: yOff)
            container.addChild(band)
        }

        // Barrel — 5×9pt (0.70× 8×13)
        let barrel = SKShapeNode(rectOf: CGSize(width: 5, height: 9), cornerRadius: 1)
        barrel.fillColor = brass
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: hh + 4)
        container.addChild(barrel)

        // Flat end plate
        let endPlate = SKShapeNode(rectOf: CGSize(width: 7, height: 2))
        endPlate.fillColor = brass
        endPlate.strokeColor = .clear
        endPlate.position = CGPoint(x: 0, y: hh + 8)
        container.addChild(endPlate)

        container.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: .pi * 3 / 180, duration: 1.0),
            SKAction.rotate(byAngle: -.pi * 3 / 180, duration: 1.0)
        ])))

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
