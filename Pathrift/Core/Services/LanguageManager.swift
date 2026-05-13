import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case turkish = "tr"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var current: AppLanguage {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "app_language") }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        current = AppLanguage(rawValue: saved) ?? .english
    }

    func s(_ key: LocalizedKey) -> String {
        switch current {
        case .english: return key.en
        case .turkish: return key.tr
        }
    }
}

struct LocalizedKey {
    let en: String
    let tr: String
}

// Localized strings
enum L {
    // Home
    static let play      = LocalizedKey(en: "PLAY",           tr: "OYNA")
    static let howToPlay = LocalizedKey(en: "HOW TO PLAY",    tr: "NASIL OYNANIR")
    static let settings  = LocalizedKey(en: "SETTINGS",       tr: "AYARLAR")
    static let store     = LocalizedKey(en: "STORE",          tr: "MAĞAZA")
    static let bestScore = LocalizedKey(en: "BEST",           tr: "EN İYİ")

    // Game
    static let wave           = LocalizedKey(en: "WAVE",              tr: "DALGA")
    static let gold           = LocalizedKey(en: "GOLD",              tr: "ALTIN")
    static let lives          = LocalizedKey(en: "LIVES",             tr: "CAN")
    static let kills          = LocalizedKey(en: "KILLS",             tr: "ÖLDÜRME")
    static let sendWave       = LocalizedKey(en: "SEND WAVE",         tr: "DALGA GÖNDER")
    static let waveInProgress = LocalizedKey(en: "WAVE IN PROGRESS",  tr: "DALGA DEVAM EDİYOR")
    static let paused         = LocalizedKey(en: "PAUSED",            tr: "DURAKLATILDI")
    static let resume         = LocalizedKey(en: "RESUME",            tr: "DEVAM ET")
    static let quitRun        = LocalizedKey(en: "QUIT RUN",          tr: "OYUNU BIRAK")

    // Tower
    static let upgrade = LocalizedKey(en: "UPGRADE", tr: "GELİŞTİR")
    static let sell    = LocalizedKey(en: "SELL",    tr: "SAT")

    // Run End
    static let runOver      = LocalizedKey(en: "RUN OVER",   tr: "OYUN BİTTİ")
    static let score        = LocalizedKey(en: "SCORE",      tr: "PUAN")
    static let wavesReached = LocalizedKey(en: "WAVES",      tr: "DALGALAR")
    static let playAgain    = LocalizedKey(en: "PLAY AGAIN", tr: "TEKRAR OYNA")
    static let mainMenu     = LocalizedKey(en: "MAIN MENU",  tr: "ANA MENÜ")

    // Settings
    static let language = LocalizedKey(en: "Language", tr: "Dil")
    static let version  = LocalizedKey(en: "Version",  tr: "Versiyon")
    static let gameInfo = LocalizedKey(en: "GAME INFO", tr: "OYUN BİLGİSİ")

    // Store
    static let diamonds   = LocalizedKey(en: "DIAMONDS",         tr: "ELMASlar")
    static let comingSoon = LocalizedKey(en: "Coming Soon",       tr: "Yakında")
    static let free       = LocalizedKey(en: "FREE",              tr: "BEDAVA")
    static let towerSkins = LocalizedKey(en: "TOWER SKINS",       tr: "KULE KAPLAMALARI")
    static let dailyBonus = LocalizedKey(en: "DAILY BONUS",       tr: "GÜNLÜK BONUS")
}
