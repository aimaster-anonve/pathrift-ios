import Foundation
import CoreGraphics

// MARK: - GridSystem (Build 8 — DEC-032)
// Repurposed from slot-based to free-form tower position tracker.
// No predefined slot positions. Towers are placed at arbitrary scene-space points.

final class GridSystem {

    struct PlacedRecord {
        let towerId: Int
        var position: CGPoint
        var type: TowerType
    }

    private(set) var placed: [Int: PlacedRecord] = [:]
    private var nextId: Int = 0

    var count: Int { placed.count }

    @discardableResult
    func addTower(type: TowerType, at position: CGPoint) -> Int {
        let id = nextId; nextId += 1
        placed[id] = PlacedRecord(towerId: id, position: position, type: type)
        return id
    }

    func removeTower(id: Int) {
        placed.removeValue(forKey: id)
    }

    func moveTower(id: Int, to position: CGPoint) {
        placed[id]?.position = position
    }

    func record(for id: Int) -> PlacedRecord? { placed[id] }

    func clear() { placed.removeAll(); nextId = 0 }

    /// Minimum distance from point `p` to any placed tower center, optionally excluding one tower.
    func minDistanceToTower(_ p: CGPoint, excluding excludeId: Int? = nil) -> CGFloat {
        placed.values
            .filter { $0.towerId != excludeId }
            .map { hypot($0.position.x - p.x, $0.position.y - p.y) }
            .min() ?? .infinity
    }
}
