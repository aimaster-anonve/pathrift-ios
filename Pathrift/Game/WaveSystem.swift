import Foundation
import CoreGraphics

enum EnemyType: String, CaseIterable {
    case runner   = "Runner"
    case tank     = "Tank"
    case boss     = "Boss"
    case shield   = "Shield"   // intro cycle 2 (wave 8+): absorbs first 80 dmg
    case swarm    = "Swarm"    // intro cycle 3 (wave 19+): fast packs, low HP
    case ghost    = "Ghost"    // intro cycle 4 (wave 28+): 90% frost immune
    case splitter = "Splitter" // cycle 2+: splits into 2 Swarm on death
    case jumper   = "Jumper"   // cycle 2+: jumps forward path every 5s
    case healer   = "Healer"   // cycle 4+ (wave 32+): aura heals nearby enemies every 2.5s
    case phantom  = "Phantom"  // cycle 4+ (wave 38+): 40% dodge vs single-target projectiles
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
    // 9-wave base cycle (wave 10 is boss, handled separately).
    // Players have 250 gold = ~3 towers by wave 1.
    private let basePatterns: [WaveDefinition] = [
        // Wave 1: easy intro — 3 slow runners, generous interval
        WaveDefinition(waveNumber: 1,
                       spawns: [EnemySpawnEntry(type: .runner, count: 3)],
                       spawnInterval: 2.5),
        // Wave 2: slightly more, introduce spacing challenge
        WaveDefinition(waveNumber: 2,
                       spawns: [EnemySpawnEntry(type: .runner, count: 4)],
                       spawnInterval: 2.2),
        // Wave 3: first tank — teaches armor counter
        WaveDefinition(waveNumber: 3,
                       spawns: [EnemySpawnEntry(type: .runner, count: 4),
                                EnemySpawnEntry(type: .tank,   count: 1)],
                       spawnInterval: 2.0),
        // Wave 4: pressure ramps up
        WaveDefinition(waveNumber: 4,
                       spawns: [EnemySpawnEntry(type: .runner, count: 6),
                                EnemySpawnEntry(type: .tank,   count: 1)],
                       spawnInterval: 1.8),
        // Wave 5: dual tanks test + Rift Shift fires after this wave
        WaveDefinition(waveNumber: 5,
                       spawns: [EnemySpawnEntry(type: .runner, count: 5),
                                EnemySpawnEntry(type: .tank,   count: 2)],
                       spawnInterval: 1.6),
        // Wave 6: heavier runner pressure
        WaveDefinition(waveNumber: 6,
                       spawns: [EnemySpawnEntry(type: .runner, count: 7),
                                EnemySpawnEntry(type: .tank,   count: 2)],
                       spawnInterval: 1.5),
        // Wave 7: sustained DPS test
        WaveDefinition(waveNumber: 7,
                       spawns: [EnemySpawnEntry(type: .runner, count: 8),
                                EnemySpawnEntry(type: .tank,   count: 3)],
                       spawnInterval: 1.4),
        // Wave 8: first shield wave (shields introduced here, cycle repeats from wave 17+)
        WaveDefinition(waveNumber: 8,
                       spawns: [EnemySpawnEntry(type: .runner, count: 5),
                                EnemySpawnEntry(type: .shield, count: 2)],
                       spawnInterval: 1.5),
        // Wave 9: pre-boss mixed pressure
        WaveDefinition(waveNumber: 9,
                       spawns: [EnemySpawnEntry(type: .runner, count: 6),
                                EnemySpawnEntry(type: .tank,   count: 2),
                                EnemySpawnEntry(type: .shield, count: 1)],
                       spawnInterval: 1.3),
    ]

    private(set) var currentWave: Int = 0
    // 9-wave non-boss cycle; wave 10, 20, 30... are boss waves handled separately
    private let cycleSize: Int = 9

    func nextWave() -> WaveDefinition {
        currentWave += 1
        return waveDefinition(for: currentWave)
    }

    func isBossWave(_ waveNumber: Int) -> Bool {
        return waveNumber % 10 == 0
    }

    func bossWaveDefinition(for waveNumber: Int) -> WaveDefinition {
        return WaveDefinition(
            waveNumber: waveNumber,
            spawns: [EnemySpawnEntry(type: .boss, count: 1)],
            spawnInterval: 5.0
        )
    }

    func waveDefinition(for waveNumber: Int) -> WaveDefinition {
        // Boss every 10 waves — exempt from normal pattern cycling
        if isBossWave(waveNumber) {
            return bossWaveDefinition(for: waveNumber)
        }

        // Map non-boss wave into 9-wave cycle.
        // Skip every 10th number: wave 1-9 → index 0-8, wave 11-19 → index 0-8, etc.
        let bossesBeforeThisWave = waveNumber / 10
        let positionInNonBoss = waveNumber - bossesBeforeThisWave  // position excluding boss waves
        let patternIndex = (positionInNonBoss - 1) % cycleSize
        let cycleNumber  = (positionInNonBoss - 1) / cycleSize
        let base = basePatterns[patternIndex]

        if cycleNumber == 0 { return WaveDefinition(waveNumber: waveNumber, spawns: base.spawns, spawnInterval: base.spawnInterval) }

        // Scale base spawns by cycle depth
        var scaledSpawns = base.spawns.map { entry in
            EnemySpawnEntry(type: entry.type, count: entry.count + cycleNumber)
        }

        // Cycle 2+ (wave 19+): inject swarm packs every 3rd pattern slot
        if cycleNumber >= 2 && patternIndex % 3 == 0 {
            scaledSpawns.append(EnemySpawnEntry(type: .swarm, count: 5 + cycleNumber))
        }

        // Cycle 3+ (wave 28+): inject ghost enemies every 4th pattern slot (offset by 1)
        if cycleNumber >= 3 && patternIndex % 4 == 1 {
            scaledSpawns.append(EnemySpawnEntry(type: .ghost, count: 2 + cycleNumber))
        }

        // Cycle 2+: inject splitter enemies every 3rd pattern slot (offset by 1)
        if cycleNumber >= 2 && patternIndex % 3 == 1 {
            scaledSpawns.append(EnemySpawnEntry(type: .splitter, count: 2 + cycleNumber))
        }

        // Cycle 2+: inject jumper enemies every 4th pattern slot (offset by 2)
        if cycleNumber >= 2 && patternIndex % 4 == 2 {
            scaledSpawns.append(EnemySpawnEntry(type: .jumper, count: 1 + cycleNumber))
        }

        // Cycle 4+ (wave 32+): Healer every 4th pattern slot (offset 3)
        if cycleNumber >= 4 && patternIndex % 4 == 3 {
            scaledSpawns.append(EnemySpawnEntry(type: .healer, count: 1 + cycleNumber - 3))
        }

        // Cycle 4+ (wave 38+): Phantom every 3rd pattern slot (offset 2, avoid jumper conflict)
        if cycleNumber >= 4 && patternIndex % 3 == 2 && patternIndex != 2 {
            scaledSpawns.append(EnemySpawnEntry(type: .phantom, count: 1 + cycleNumber - 3))
        }

        let adjustedInterval = max(0.8, base.spawnInterval - Double(cycleNumber) * 0.08)
        return WaveDefinition(waveNumber: waveNumber, spawns: scaledSpawns, spawnInterval: adjustedInterval)
    }

    // Aggressive exponential HP scaling
    func hpScaleMultiplier(for waveNumber: Int) -> CGFloat {
        if waveNumber <= 5  { return 1.0 }
        if waveNumber <= 10 { return 1.0 + CGFloat(waveNumber - 5) * 0.15 }
        if waveNumber <= 20 { return 1.75 + CGFloat(waveNumber - 10) * 0.20 }
        return 3.75 + CGFloat(waveNumber - 20) * 0.30
    }

    func syncWave(_ waveNumber: Int) {
        currentWave = waveNumber
    }

    /// Returns the 0-based cycle number for a given wave (for gold scaling, enemy intro)
    func cycleNumber(for waveNumber: Int) -> Int {
        let bossesBeforeThisWave = waveNumber / 10
        let positionInNonBoss = waveNumber - bossesBeforeThisWave
        return (positionInNonBoss - 1) / cycleSize
    }

    func reset() { currentWave = 0 }
}
