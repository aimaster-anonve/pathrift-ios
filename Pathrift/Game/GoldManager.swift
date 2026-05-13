import Foundation
import Combine

final class GoldManager: ObservableObject {
    @Published private(set) var gold: Int
    private var onGoldChanged: ((Int) -> Void)?

    init(startingGold: Int = EconomyConstants.startingGold) {
        self.gold = startingGold
    }

    func setChangeHandler(_ handler: @escaping (Int) -> Void) {
        onGoldChanged = handler
    }

    @discardableResult
    func spend(_ amount: Int) -> Bool {
        guard gold >= amount else { return false }
        gold -= amount
        onGoldChanged?(gold)
        return true
    }

    func earn(_ amount: Int) {
        gold += amount
        onGoldChanged?(gold)
    }

    func canAfford(_ amount: Int) -> Bool {
        return gold >= amount
    }

    func awardWaveReward(wave: Int) {
        let reward = EconomyConstants.goldRewardForWave(wave)
        earn(reward)
    }
}
