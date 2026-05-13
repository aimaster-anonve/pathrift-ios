import SwiftUI

struct StoreScreen: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var lang = LanguageManager.shared
    @State private var diamonds: Int = 0
    @State private var dailyClaimed: Bool = false
    @State private var isPremium: Bool = false
    @State private var selectedTower: TowerType? = nil

    private var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                if isLandscape {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
        }
        .onAppear {
            diamonds = DiamondStore.shared.balance
            dailyClaimed = UserDefaults.standard.bool(forKey: "daily_claimed_\(todayKey())")
            isPremium = PremiumStore.shared.isPremium
        }
        .sheet(item: $selectedTower) { type in
            TowerDetailSheet(type: type, diamonds: $diamonds)
        }
    }

    // MARK: - Nav Bar

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
        .padding(.vertical, 10)
        .background(Color.pathriftSurface.opacity(0.9))
    }

    // MARK: - Portrait Content

    private var portraitContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                premiumSection
                towersSection
                diamondsSection
                dailyBonusCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Landscape Content (two-column)

    private var landscapeContent: some View {
        HStack(alignment: .top, spacing: 0) {
            // LEFT column: premium + diamonds + daily bonus
            ScrollView {
                VStack(spacing: 16) {
                    premiumSection
                    diamondsSection
                    dailyBonusCard
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.pathriftSurface)
                .frame(width: 1)

            // RIGHT column: towers
            ScrollView {
                VStack(spacing: 16) {
                    towersSection
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Section 1: Premium

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("PREMIUM", icon: "bolt.fill")

            if isPremium {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.pathriftNeonBlue.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.pathriftNeonBlue)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PREMIUM ACTIVE ✓")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(.pathriftNeonBlue)
                        Text("All premium features unlocked")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.pathriftTextSecondary)
                    }
                    Spacer()
                    Button(action: {
                        PremiumStore.shared.toggle()
                        isPremium = PremiumStore.shared.isPremium
                    }) {
                        Text("DEACTIVATE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.pathriftDanger)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.pathriftDanger.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.pathriftSurface, Color.pathriftNeonBlue.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.pathriftNeonBlue.opacity(0.3), lineWidth: 1)
                )
            } else {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        premiumBenefitRow(icon: "forward.fill", text: "×2 Speed in-game")
                        premiumBenefitRow(icon: "heart.fill", text: "1 Revive per run")
                        premiumBenefitRow(icon: "sparkles", text: "More coming soon")
                    }
                    .padding(16)
                    .background(Color.pathriftSurface)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.pathriftNeonBlue.opacity(0.2), lineWidth: 1)
                    )

                    Button(action: {
                        PremiumStore.shared.toggle()
                        isPremium = PremiumStore.shared.isPremium
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill").font(.system(size: 14))
                            Text("GET PREMIUM (FREE – Test Mode)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.pathriftBackground)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.pathriftNeonBlue, Color.pathriftPurple],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .pathriftNeonBlue.opacity(0.35), radius: 10, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    private func premiumBenefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.pathriftNeonBlue)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.pathriftTextPrimary)
        }
    }

    // MARK: - Section 2: Towers

    private var towersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("TOWERS", icon: "shield.fill")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TowerType.allCases) { type in
                    storeTowerCard(for: type)
                }
            }
        }
    }

    private func storeTowerCard(for type: TowerType) -> some View {
        let unlocked = DiamondStore.shared.isUnlocked(type)
        return Button(action: { selectedTower = type }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(type.swiftUIColor.opacity(0.1))
                        .frame(height: 68)
                    Circle()
                        .fill(type.swiftUIColor)
                        .frame(width: 34, height: 34)
                        .shadow(color: type.swiftUIColor.opacity(0.5), radius: 6)
                }
                Text(type.displayName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.pathriftTextPrimary)
                if unlocked {
                    Text("OWNED")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftSuccess)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.pathriftSuccess.opacity(0.15))
                        .cornerRadius(6)
                } else {
                    HStack(spacing: 3) {
                        Text("♦")
                        Text("\(type.diamondCost)")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.pathriftNeonBlue.opacity(0.12))
                    .cornerRadius(6)
                }
            }
            .padding(12)
            .background(Color.pathriftSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(unlocked ? type.swiftUIColor.opacity(0.25) : Color.pathriftTextSecondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Section 3: Diamonds

    private var diamondsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DIAMONDS", icon: "diamond.fill")
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DIAMONDS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.pathriftTextSecondary)
                            .kerning(2)
                        HStack(spacing: 8) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.pathriftNeonBlue)
                                .shadow(color: .pathriftNeonBlue.opacity(0.6), radius: 8)
                            Text("\(diamonds)")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(.pathriftTextPrimary)
                                .monospacedDigit()
                        }
                    }
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.pathriftTextSecondary.opacity(0.3))
                }
                Text("Buy Diamonds – Coming Soon (Phase 7)")
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
    }

    // MARK: - Daily Bonus

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
                        Image(systemName: "diamond.fill").font(.system(size: 11))
                        Text("+10").font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.pathriftGold)
                    .padding(.horizontal, 12).padding(.vertical, 6)
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

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(.pathriftNeonBlue)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(1.5)
        }
    }

    private func claimDailyBonus() {
        guard !dailyClaimed else { return }
        DiamondStore.shared.earn(10)
        diamonds = DiamondStore.shared.balance
        UserDefaults.standard.set(true, forKey: "daily_claimed_\(todayKey())")
        dailyClaimed = true
    }

    private func todayKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}

// MARK: - Tower Detail Sheet

struct TowerDetailSheet: View {
    let type: TowerType
    @Binding var diamonds: Int
    @Environment(\.dismiss) private var dismiss

    var isUnlocked: Bool { DiamondStore.shared.isUnlocked(type) }
    var canAfford: Bool { diamonds >= type.diamondCost }

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            GeometryReader { geo in
                let landscape = geo.size.width > geo.size.height
                if landscape {
                    landscapeSheetBody
                } else {
                    portraitSheetBody
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.pathriftBackground)
    }

    private var portraitSheetBody: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(type.swiftUIColor)
                .frame(width: 64, height: 64)
                .shadow(color: type.swiftUIColor.opacity(0.6), radius: 12)
                .padding(.top, 24)

            Text(type.displayName.uppercased())
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.pathriftTextPrimary)

            HStack(spacing: 8) {
                Text("TIER \(type.tier)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(type.swiftUIColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(type.swiftUIColor.opacity(0.15))
                    .cornerRadius(6)
                if let hint = type.typeAdvantageHint {
                    Text(hint)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.pathriftTextSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.pathriftSurface)
                        .cornerRadius(6)
                }
            }

            HStack(spacing: 16) {
                statPill(label: "DMG", value: "\(Int(type.damage))", color: .pathriftOrange)
                statPill(label: "RNG", value: "\(Int(type.range))", color: .pathriftNeonBlue)
                statPill(label: "SPD", value: String(format: "%.1f/s", 1.0 / type.attackSpeed), color: .pathriftPurple)
            }

            Text(type.description)
                .font(.system(size: 12))
                .foregroundColor(.pathriftTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
            unlockOrOwnedButton
            Button("Close") { dismiss() }
                .font(.system(size: 13))
                .foregroundColor(.pathriftTextSecondary)
                .padding(.bottom, 24)
        }
    }

    private var landscapeSheetBody: some View {
        HStack(spacing: 0) {
            // Left: tower identity
            VStack(spacing: 12) {
                Circle()
                    .fill(type.swiftUIColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: type.swiftUIColor.opacity(0.6), radius: 10)
                    .padding(.top, 20)

                Text(type.displayName.uppercased())
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.pathriftTextPrimary)

                HStack(spacing: 6) {
                    Text("TIER \(type.tier)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(type.swiftUIColor)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(type.swiftUIColor.opacity(0.15))
                        .cornerRadius(5)
                    if let hint = type.typeAdvantageHint {
                        Text(hint)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.pathriftTextSecondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.pathriftSurface)
                            .cornerRadius(5)
                    }
                }

                HStack(spacing: 12) {
                    statPill(label: "DMG", value: "\(Int(type.damage))", color: .pathriftOrange)
                    statPill(label: "RNG", value: "\(Int(type.range))", color: .pathriftNeonBlue)
                    statPill(label: "SPD", value: String(format: "%.1f/s", 1.0 / type.attackSpeed), color: .pathriftPurple)
                }

                Text(type.description)
                    .font(.system(size: 11))
                    .foregroundColor(.pathriftTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: action button
            VStack(spacing: 12) {
                Spacer()
                unlockOrOwnedButton.padding(.horizontal, 16)
                Button("Close") { dismiss() }
                    .font(.system(size: 13))
                    .foregroundColor(.pathriftTextSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var unlockOrOwnedButton: some View {
        if isUnlocked {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.pathriftSuccess)
                Text("OWNED").font(.system(size: 15, weight: .bold)).foregroundColor(.pathriftSuccess)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.pathriftSuccess.opacity(0.12))
            .cornerRadius(14)
            .padding(.horizontal, 24)
        } else {
            VStack(spacing: 4) {
                Button(action: {
                    if DiamondStore.shared.unlock(type) {
                        diamonds = DiamondStore.shared.balance
                        dismiss()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text("♦")
                        Text("UNLOCK FOR \(type.diamondCost) DIAMONDS")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(canAfford ? .pathriftBackground : .pathriftTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(canAfford ? Color.pathriftNeonBlue : Color.pathriftSurface)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(canAfford ? Color.clear : Color.pathriftTextSecondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(!canAfford)
                .padding(.horizontal, 24)
                if !canAfford {
                    Text("Not enough diamonds (need \(type.diamondCost - diamonds) more)")
                        .font(.system(size: 11))
                        .foregroundColor(.pathriftDanger)
                }
            }
        }
    }

    private func statPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(1)
            Text(value)
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// Make TowerType conform to Identifiable for .sheet(item:)
// (Already conforms via id: String { rawValue })
