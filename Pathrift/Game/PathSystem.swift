import Foundation
import CoreGraphics

struct PathSystem {
    // Set dynamically by GameScene.buildDynamicLayout()
    static var waypoints: [CGPoint] = [
        CGPoint(x: 0,   y: 0),
        CGPoint(x: 100, y: 0)
    ]

    // Parallel array to waypoints — defines elevation of each waypoint.
    // Segment from waypoint[i] to waypoint[i+1] is "bridge" if either endpoint is .bridge.
    static var waypointLayers: [PathLayer] = []

    // Returns the layer for a given waypoint index (defaults to .ground if out of range)
    static func layer(at index: Int) -> PathLayer {
        guard index < waypointLayers.count else { return .ground }
        return waypointLayers[index]
    }

    // Returns true if the segment between waypoints[i] and waypoints[i+1] is a bridge
    static func isBridgeSegment(from i: Int) -> Bool {
        return layer(at: i) == .bridge || layer(at: i + 1) == .bridge
    }

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

    // Returns the PathLayer for a given path progress (0.0–1.0)
    static func layerAt(progress: CGFloat) -> PathLayer {
        let count = waypoints.count
        guard count >= 2, !waypointLayers.isEmpty else { return .ground }
        let estimatedIndex = Int(progress * CGFloat(count - 1))
        let clamped = min(max(0, estimatedIndex), waypointLayers.count - 1)
        return waypointLayers[clamped]
    }
}

// MARK: - Free-Form Placement Helper (Build 8 — DEC-032)

extension PathSystem {
    /// Minimum perpendicular distance from point `p` to any path segment.
    static func minDistanceToPath(_ p: CGPoint) -> CGFloat {
        var minDist = CGFloat.infinity
        let pts = waypoints
        guard pts.count > 1 else { return minDist }
        for i in 1..<pts.count {
            let a = pts[i-1]; let b = pts[i]
            let dx = b.x - a.x; let dy = b.y - a.y
            let len2 = dx*dx + dy*dy
            let dist: CGFloat
            if len2 == 0 {
                dist = hypot(p.x - a.x, p.y - a.y)
            } else {
                let t = max(0, min(1, ((p.x-a.x)*dx + (p.y-a.y)*dy) / len2))
                dist = hypot(p.x - (a.x + t*dx), p.y - (a.y + t*dy))
            }
            minDist = min(minDist, dist)
        }
        return minDist
    }
}
