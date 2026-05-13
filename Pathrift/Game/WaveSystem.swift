import Foundation
import CoreGraphics

enum EnemyType: String, CaseIterable {
    case runner = "Runner"
    case tank = "Tank"
}

struct EnemySpawnEntry {
    let type: EnemyType
    let count: Int
}

struct WaveDefinition {
    let waveNumber: Int
    let spawns: [EnemySpawnEntry]
    let spawnInterval: TimeInterval

    var totalEnemyCount: Int {
        spawns.reduce(0) { $0 + $1.count }
    }
}

final class WaveSystem {
    private let basePatterns: [WaveDefinition] = [
        WaveDefinition(waveNumber: 1, spawns: [EnemySpawnEntry(type: .runner, count: 5)], spawnInterval: 1.2),
        WaveDefinition(waveNumber: 2, spawns: [EnemySpawnEntry(type: .runner, count: 3), EnemySpawnEntry(type: .tank, count: 1)], spawnInterval: 1.5),
        WaveDefinition(waveNumber: 3, spawns: [EnemySpawnEntry(type: .runner, count: 8)], spawnInterval: 1.0),
        WaveDefinition(waveNumber: 4, spawns: [EnemySpawnEntry(type: .tank, count: 2)], spawnInterval: 2.0),
        WaveDefinition(waveNumber: 5, spawns: [EnemySpawnEntry(type: .runner, count: 6), EnemySpawnEntry(type: .tank, count: 2)], spawnInterval: 1.3)
    ]

    private(set) var currentWave: Int = 0
    private let cycleSize: Int = 5

    func nextWave() -> WaveDefinition {
        currentWave += 1
        return waveDefinition(for: currentWave)
    }

    func waveDefinition(for waveNumber: Int) -> WaveDefinition {
        let patternIndex = (waveNumber - 1) % cycleSize
        let cycleNumber = (waveNumber - 1) / cycleSize
        let base = basePatterns[patternIndex]

        if cycleNumber == 0 {
            return base
        }

        let scaledSpawns = base.spawns.map { entry in
            EnemySpawnEntry(type: entry.type, count: entry.count + cycleNumber)
        }
        let adjustedInterval = max(0.5, base.spawnInterval - Double(cycleNumber) * 0.05)
        return WaveDefinition(waveNumber: waveNumber, spawns: scaledSpawns, spawnInterval: adjustedInterval)
    }

    func hpScaleMultiplier(for waveNumber: Int) -> CGFloat {
        let cycleNumber = CGFloat((waveNumber - 1) / cycleSize)
        return 1.0 + cycleNumber * 0.20
    }

    func reset() {
        currentWave = 0
    }
}
