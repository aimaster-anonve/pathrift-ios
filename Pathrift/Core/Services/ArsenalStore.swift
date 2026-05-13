import Foundation

final class ArsenalStore {
    static let shared = ArsenalStore()
    private let prefix = "arsenal_"
    private init() {}

    // Permanent damage level (0-3) per tower type
    func permDamageLevel(for type: TowerType) -> Int {
        UserDefaults.standard.integer(forKey: "\(prefix)dmg_\(type.rawValue)")
    }

    // Permanent speed level (0-3) per tower type
    func permSpeedLevel(for type: TowerType) -> Int {
        UserDefaults.standard.integer(forKey: "\(prefix)spd_\(type.rawValue)")
    }

    func setPermDamageLevel(_ level: Int, for type: TowerType) {
        UserDefaults.standard.set(min(3, level), forKey: "\(prefix)dmg_\(type.rawValue)")
    }

    func setPermSpeedLevel(_ level: Int, for type: TowerType) {
        UserDefaults.standard.set(min(3, level), forKey: "\(prefix)spd_\(type.rawValue)")
    }

    // Bonus multiplier from permanent damage upgrade (0 = +0%, 1 = +10%, 2 = +20%, 3 = +35%)
    func permDamageBonus(for type: TowerType) -> CGFloat {
        let bonuses: [CGFloat] = [0, 0.10, 0.20, 0.35]
        return bonuses[permDamageLevel(for: type)]
    }

    // Bonus multiplier from permanent speed upgrade (0 = +0%, 1 = +8%, 2 = +16%, 3 = +28%)
    func permSpeedBonus(for type: TowerType) -> CGFloat {
        let bonuses: [CGFloat] = [0, 0.08, 0.16, 0.28]
        return bonuses[permSpeedLevel(for: type)]
    }

    // Cost to upgrade damage from current level to next
    func dmgUpgradeCost(for type: TowerType) -> Int? {
        let level = permDamageLevel(for: type)
        guard level < 3 else { return nil }
        let costs = upgradeCosts(tier: type.tier)
        return costs[level]
    }

    // Cost to upgrade speed from current level to next
    func speedUpgradeCost(for type: TowerType) -> Int? {
        let level = permSpeedLevel(for: type)
        guard level < 3 else { return nil }
        let costs = upgradeCosts(tier: type.tier)
        return costs[level]
    }

    private func upgradeCosts(tier: Int) -> [Int] {
        switch tier {
        case 1: return [25, 60, 120]
        case 2: return [40, 100, 200]
        default: return [60, 150, 300]
        }
    }
}
