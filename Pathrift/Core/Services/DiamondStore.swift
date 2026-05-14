import Foundation

final class DiamondStore {
    static let shared = DiamondStore()
    private let balanceKey = "pathrift_diamonds"
    private let unlockedKey = "pathrift_unlocked_towers"

    private init() {
        // Always ensure bolt is unlocked
        if !unlockedTowers.contains(TowerType.bolt.rawValue) {
            var set = unlockedTowers
            set.insert(TowerType.bolt.rawValue)
            unlockedTowers = set
        }
    }

    var balance: Int {
        get { UserDefaults.standard.integer(forKey: balanceKey) }
        set { UserDefaults.standard.set(newValue, forKey: balanceKey) }
    }

    func earn(_ amount: Int) {
        balance += amount
    }

    func spend(_ amount: Int) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }

    var unlockedTowers: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: unlockedKey) ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: unlockedKey)
        }
    }

    func isUnlocked(_ type: TowerType) -> Bool {
        if PremiumStore.shared.isPremium { return true }
        guard type.diamondCost > 0 else { return true }
        return unlockedTowers.contains(type.rawValue)
    }

    func unlock(_ type: TowerType) -> Bool {
        guard type.diamondCost > 0 else { return true }
        guard spend(type.diamondCost) else { return false }
        var set = unlockedTowers
        set.insert(type.rawValue)
        unlockedTowers = set
        return true
    }
}
