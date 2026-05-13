import Foundation
import CoreGraphics

struct PathSystem {
    // Set dynamically by GameScene.buildDynamicLayout()
    static var waypoints: [CGPoint] = [
        CGPoint(x: 0,   y: 0),
        CGPoint(x: 100, y: 0)
    ]

    static func totalPathLength() -> CGFloat {
        var length: CGFloat = 0
        for i in 1..<waypoints.count {
            let dx = waypoints[i].x - waypoints[i-1].x
            let dy = waypoints[i].y - waypoints[i-1].y
            length += sqrt(dx*dx + dy*dy)
        }
        return length
    }

    static func position(at progress: CGFloat) -> CGPoint {
        let totalLength = totalPathLength()
        guard totalLength > 0 else { return waypoints.first ?? .zero }
        let targetDistance = progress * totalLength
        var accumulated: CGFloat = 0

        for i in 1..<waypoints.count {
            let from = waypoints[i-1]
            let to = waypoints[i]
            let dx = to.x - from.x
            let dy = to.y - from.y
            let segLen = sqrt(dx*dx + dy*dy)
            if accumulated + segLen >= targetDistance {
                let t = segLen > 0 ? (targetDistance - accumulated) / segLen : 0
                return CGPoint(x: from.x + dx*t, y: from.y + dy*t)
            }
            accumulated += segLen
        }
        return waypoints.last ?? .zero
    }

    static func direction(at progress: CGFloat) -> CGVector {
        let totalLength = totalPathLength()
        let targetDistance = progress * totalLength
        var accumulated: CGFloat = 0
        for i in 1..<waypoints.count {
            let from = waypoints[i-1]
            let to = waypoints[i]
            let dx = to.x - from.x
            let dy = to.y - from.y
            let segLen = sqrt(dx*dx + dy*dy)
            if accumulated + segLen >= targetDistance {
                let len = segLen > 0 ? segLen : 1
                return CGVector(dx: dx/len, dy: dy/len)
            }
            accumulated += segLen
        }
        return CGVector(dx: 1, dy: 0)
    }
}
