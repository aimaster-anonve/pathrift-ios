import SwiftUI

struct StoreScreen: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var lang = LanguageManager.shared
    @State private var diamonds: Int = 0
    @State private var dailyClaimed: Bool = false

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 24) {
                        diamondBalanceCard
                        dailyBonusCard
                        towerSkinsSection
                        comingSoonSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            diamonds = UserDefaults.standard.integer(forKey: "diamond_balance")
            dailyClaimed = UserDefaults.standard.bool(forKey: "daily_claimed_\(todayKey())")
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
            Text(lang.s(L.store).uppercased())
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.pathriftTextPrimary)
                .kerning(2)
            Spacer()
            // Diamond counter in nav
            HStack(spacing: 4) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.pathriftNeonBlue)
                Text("\(diamonds)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.pathriftTextPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.pathriftSurface.opacity(0.9))
    }

    private var diamondBalanceCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lang.s(L.diamonds))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftTextSecondary)
                        .kerning(2)
                    HStack(spacing: 8) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.pathriftNeonBlue)
                            .shadow(color: .pathriftNeonBlue.opacity(0.6), radius: 8)
                        Text("\(diamonds)")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.pathriftTextPrimary)
                            .monospacedDigit()
                    }
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.pathriftTextSecondary.opacity(0.3))
            }
            Text("💎 IAP purchases coming in v1.1 — earn diamonds by playing!")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.pathriftSurface, Color.pathriftNeonBlue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.pathriftNeonBlue.opacity(0.2), lineWidth: 1)
        )
    }

    private var dailyBonusCard: some View {
        Button(action: claimDailyBonus) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(dailyClaimed ? Color.pathriftSurface : Color.pathriftGold.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: dailyClaimed ? "checkmark.circle.fill" : "gift.fill")
                        .font(.system(size: 24))
                        .foregroundColor(dailyClaimed ? .pathriftSuccess : .pathriftGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(lang.s(L.dailyBonus).uppercased())
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(dailyClaimed ? .pathriftTextSecondary : .pathriftTextPrimary)
                        .kerning(0.5)
                    Text(dailyClaimed ? "Come back tomorrow!" : "Claim 10 free diamonds")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.pathriftTextSecondary)
                }
                Spacer()
                if !dailyClaimed {
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 11))
                        Text("+10")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.pathriftGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.pathriftGold.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color.pathriftSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(dailyClaimed ? Color.clear : Color.pathriftGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(dailyClaimed)
    }

    private var towerSkinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lang.s(L.towerSkins).uppercased(), icon: "paintbrush.fill")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TowerType.allCases) { type in
                    skinCard(for: type)
                }
                // Locked extra skins
                ForEach(["Cyber", "Void"], id: \.self) { skinName in
                    lockedSkinCard(name: skinName)
                }
            }
        }
    }

    private func skinCard(for type: TowerType) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(type.swiftUIColor.opacity(0.15))
                    .frame(height: 70)
                Circle()
                    .fill(type.swiftUIColor)
                    .frame(width: 32, height: 32)
                    .shadow(color: type.swiftUIColor.opacity(0.6), radius: 6)
            }
            Text(type.displayName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.pathriftTextPrimary)
            Text(lang.s(L.free))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftSuccess)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.pathriftSuccess.opacity(0.15))
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color.pathriftSurface)
        .cornerRadius(12)
    }

    private func lockedSkinCard(name: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.pathriftSurface)
                    .frame(height: 70)
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.pathriftTextSecondary.opacity(0.3))
            }
            Text(name)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.pathriftTextSecondary)
            Text(lang.s(L.comingSoon))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.pathriftSurface)
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color.pathriftSurface.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.pathriftTextSecondary.opacity(0.15), lineWidth: 1)
        )
    }

    private var comingSoonSection: some View {
        VStack(spacing: 12) {
            sectionHeader("COMING SOON", icon: "sparkles")
            HStack(spacing: 12) {
                comingSoonPill(icon: "map.fill", label: "Map Themes")
                comingSoonPill(icon: "star.fill", label: "Rift Pass")
                comingSoonPill(icon: "trophy.fill", label: "Leaderboard")
            }
        }
    }

    private func comingSoonPill(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.pathriftTextSecondary.opacity(0.4))
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.pathriftSurface.opacity(0.5))
        .cornerRadius(12)
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

    private func claimDailyBonus() {
        guard !dailyClaimed else { return }
        diamonds += 10
        UserDefaults.standard.set(diamonds, forKey: "diamond_balance")
        UserDefaults.standard.set(true, forKey: "daily_claimed_\(todayKey())")
        dailyClaimed = true
    }

    private func todayKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}
