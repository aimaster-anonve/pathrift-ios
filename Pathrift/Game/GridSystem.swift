import Foundation
import CoreGraphics

struct TileCoordinate: Hashable, Equatable {
    let col: Int
    let row: Int

    func toPoint(tileSize: CGFloat) -> CGPoint {
        return CGPoint(
            x: CGFloat(col) * tileSize + tileSize / 2,
            y: CGFloat(row) * tileSize + tileSize / 2
        )
    }
}

enum TowerSlotState {
    case empty
    case occupied(TowerType)
    case locked

    var isOccupied: Bool {
        if case .occupied = self { return true }
        return false
    }

    var towerType: TowerType? {
        if case .occupied(let type) = self { return type }
        return nil
    }
}

struct TowerSlot {
    let id: Int
    let position: CGPoint
    var state: TowerSlotState

    init(id: Int, position: CGPoint) {
        self.id = id
        self.position = position
        self.state = .empty
    }
}

final class GridSystem {
    let columns: Int = 12
    let rows: Int = 8
    let tileSize: CGFloat = 64.0

    private(set) var slots: [TowerSlot]

    var sceneSize: CGSize {
        CGSize(width: CGFloat(columns) * tileSize, height: CGFloat(rows) * tileSize)
    }

    init() {
        slots = GridSystem.buildPredefinedSlots()
    }

    private static func buildPredefinedSlots() -> [TowerSlot] {
        let positions: [CGPoint] = [
            CGPoint(x: 64,  y: 224),
            CGPoint(x: 128, y: 224),
            CGPoint(x: 192, y: 160),
            CGPoint(x: 256, y: 96),
            CGPoint(x: 320, y: 96),
            CGPoint(x: 384, y: 160),
            CGPoint(x: 448, y: 288),
            CGPoint(x: 512, y: 352)
        ]
        return positions.enumerated().map { idx, pos in
            TowerSlot(id: idx, position: pos)
        }
    }

    func slot(at id: Int) -> TowerSlot? {
        slots.first { $0.id == id }
    }

    func slotIndex(for id: Int) -> Int? {
        slots.firstIndex { $0.id == id }
    }

    @discardableResult
    func placeTower(type: TowerType, at slotId: Int) -> Bool {
        guard let idx = slotIndex(for: slotId),
              case .empty = slots[idx].state else {
            return false
        }
        slots[idx].state = .occupied(type)
        return true
    }

    func removeTower(at slotId: Int) {
        guard let idx = slotIndex(for: slotId) else { return }
        slots[idx].state = .empty
    }

    func updateSlots(_ positions: [CGPoint]) {
        slots = positions.enumerated().map { idx, pos in
            TowerSlot(id: idx, position: pos)
        }
    }

    func availableSlots() -> [TowerSlot] {
        slots.filter { if case .empty = $0.state { return true }; return false }
    }

    func occupiedSlots() -> [TowerSlot] {
        slots.filter { $0.state.isOccupied }
    }

    func tileCoordinate(for point: CGPoint) -> TileCoordinate {
        let col = max(0, min(columns - 1, Int(point.x / tileSize)))
        let row = max(0, min(rows - 1, Int(point.y / tileSize)))
        return TileCoordinate(col: col, row: row)
    }
}
