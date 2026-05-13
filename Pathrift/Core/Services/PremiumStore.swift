import Foundation

final class PremiumStore {
    static let shared = PremiumStore()
    private let key = "pathrift_is_premium"
    private init() {}

    var isPremium: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    func activate() { isPremium = true }
    func toggle()   { isPremium = !isPremium }
    func deactivate() { isPremium = false }
}
