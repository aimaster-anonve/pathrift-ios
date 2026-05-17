import Foundation

final class AdRewardStore {
    static let shared = AdRewardStore()
    private init() {}

    let maxDailyAds = 3
    let rewardPerAd  = 5   // diamonds per ad watch

    private var todayKey: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return "pathrift_ads_\(fmt.string(from: Date()))"
    }

    var adsWatchedToday: Int {
        get { UserDefaults.standard.integer(forKey: todayKey) }
        set { UserDefaults.standard.set(newValue, forKey: todayKey) }
    }

    var canWatch: Bool { adsWatchedToday < maxDailyAds }

    var adsRemaining: Int { max(0, maxDailyAds - adsWatchedToday) }

    /// Simulate watching a rewarded ad. Returns true and awards diamonds if limit not reached.
    @discardableResult
    func watchAd() -> Bool {
        guard canWatch else { return false }
        adsWatchedToday += 1
        DiamondStore.shared.earn(rewardPerAd)
        return true
    }
}
