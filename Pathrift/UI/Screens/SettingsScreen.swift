import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var lang = LanguageManager.shared

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 24) {
                        languageSection
                        gameInfoSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var navBar: some View {
        HStack {
            Button(action: { appState.goHome() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text(lang.s(L.mainMenu))
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.pathriftNeonBlue)
            }
            Spacer()
            Text(lang.s(L.settings).uppercased())
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.pathriftTextPrimary)
                .kerning(2)
            Spacer()
            // Balance spacer
            Color.clear.frame(width: 80, height: 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.pathriftSurface.opacity(0.9))
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lang.s(L.language).uppercased(), icon: "globe")
            HStack(spacing: 12) {
                ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                    Button(action: { lang.current = language }) {
                        HStack(spacing: 8) {
                            Text(language == .english ? "🇬🇧" : "🇹🇷")
                                .font(.system(size: 20))
                            Text(language.displayName)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(lang.current == language ? .pathriftBackground : .pathriftTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(lang.current == language ? Color.pathriftNeonBlue : Color.pathriftSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(lang.current == language ? .clear : Color.pathriftTextSecondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    private var gameInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lang.s(L.gameInfo), icon: "info.circle")
            infoRow(label: lang.s(L.version), value: "\(appVersion) (\(buildNumber))")
                .background(Color.pathriftSurface)
                .cornerRadius(12)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("PATHRIFT", icon: "bolt.fill")
            Text("Endless tower defense where the map never stops shifting.\nPlace towers. Survive the Rift. Push further.")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.pathriftSurface)
                .cornerRadius(12)
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.pathriftNeonBlue)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(1.5)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.pathriftTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.pathriftSurface)
    }
}
