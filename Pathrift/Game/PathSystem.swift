import Foundation
import CoreGraphics

struct PathSystem {
    static let waypoints: [CGPoint] = [
        CGPoint(x: 0,   y: 300),
        CGPoint(x: 200, y: 300),
        CGPoint(x: 200, y: 100),
        CGPoint(x: 500, y: 100),
        CGPoint(x: 500, y: 400),
        CGPoint(x: 750, y: 400)
    ]

    static func totalPathLength() -> CGFloat {
        var length: CGFloat = 0
        for i in 1..<waypoints.count {
            let dx = waypoints[i].x - waypoints[i - 1].x
            let dy = waypoints[i].y - waypoints[i - 1].y
            length += sqrt(dx * dx + dy * dy)
        }
        return length
    }

    static func position(at progress: CGFloat) -> CGPoint {
        let totalLength = totalPathLength()
        let targetDistance = progress * totalLength
        var accumulated: CGFloat = 0

        for i in 1..<waypoints.count {
            let from = waypoints[i - 1]
            let to = waypoints[i]
            let dx = to.x - from.x
            let dy = to.y - from.y
            let segmentLength = sqrt(dx * dx + dy * dy)

            if accumulated + segmentLength >= targetDistance {
                let remaining = targetDistance - accumulated
                let t = segmentLength > 0 ? remaining / segmentLength : 0
                return CGPoint(
                    x: from.x + dx * t,
                    y: from.y + dy * t
                )
            }
            accumulated += segmentLength
        }
        return waypoints.last ?? .zero
    }

    static func direction(at progress: CGFloat) -> CGVector {
        let totalLength = totalPathLength()
        let targetDistance = progress * totalLength
        var accumulated: CGFloat = 0

        for i in 1..<waypoints.count {
            let from = waypoints[i - 1]
            let to = waypoints[i]
            let dx = to.x - from.x
            let dy = to.y - from.y
            let segmentLength = sqrt(dx * dx + dy * dy)

            if accumulated + segmentLength >= targetDistance {
                let len = segmentLength > 0 ? segmentLength : 1
                return CGVector(dx: dx / len, dy: dy / len)
            }
            accumulated += segmentLength
        }
        return CGVector(dx: 1, dy: 0)
    }
}
