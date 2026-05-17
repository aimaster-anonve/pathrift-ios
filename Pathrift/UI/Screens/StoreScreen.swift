import SwiftUI

struct StoreScreen: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var lang = LanguageManager.shared
    @State private var diamonds: Int = 0
    @State private var dailyClaimed: Bool = false
    @State private var isPremium: Bool = false
    @State private var selectedTower: TowerType? = nil
    @State private var adsWatchedToday: Int = 0

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
            adsWatchedToday = AdRewardStore.shared.adsWatchedToday
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
                diamondPacksSection
                watchAdSection
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
            // LEFT column: premium + diamond packs + watch ad + daily bonus
            ScrollView {
                VStack(spacing: 16) {
                    premiumSection
                    diamondPacksSection
                    watchAdSection
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
            sectionHeader("TOWERS — ALL 10", icon: "shield.fill")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TowerType.allCases) { type in
                    storeTowerCard(for: type)
                }
            }
        }
    }

    private func storeTowerCard(for type: TowerType) -> some View {
        let isFree     = type.diamondCost == 0
        let unlocked   = isFree || DiamondStore.shared.isUnlocked(type)
        let isPrem     = type.isPremium

        return Button(action: { selectedTower = type }) {
            VStack(spacing: 6) {
                // Icon area
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(type.swiftUIColor.opacity(isPrem ? 0.14 : 0.08))
                        .frame(height: 72)

                    TowerShapeView(type: type, size: 40)
                        .shadow(color: type.swiftUIColor.opacity(0.5), radius: 6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Premium badge
                    if isPrem && !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(4)
                            .background(Color.black.opacity(0.45))
                            .cornerRadius(5)
                            .padding(5)
                    }
                }

                // Name
                Text(type.displayName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.pathriftTextPrimary)
                    .lineLimit(1)

                // Status badge
                Group {
                    if isFree {
                        Text("FREE")
                            .foregroundColor(.pathriftSuccess)
                            .background(Color.pathriftSuccess.opacity(0.15))
                    } else if unlocked {
                        Text("OWNED ✓")
                            .foregroundColor(.pathriftSuccess)
                            .background(Color.pathriftSuccess.opacity(0.15))
                    } else if let price = type.iapPrice {
                        // IAP tower — show money price
                        Text(price)
                            .foregroundColor(.pathriftGold)
                            .background(Color.pathriftGold.opacity(0.12))
                    } else {
                        HStack(spacing: 3) {
                            Text("♦").foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                            Text("\(type.diamondCost)").foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                        }
                        .background(Color.pathriftNeonBlue.opacity(0.12))
                    }
                }
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .cornerRadius(6)
            }
            .padding(10)
            .background(Color.pathriftSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        unlocked ? type.swiftUIColor.opacity(0.3) : Color.pathriftTextSecondary.opacity(0.12),
                        lineWidth: unlocked ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Section 3: Diamond Packs (mock IAP)

    private var diamondPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("BUY DIAMONDS", icon: "diamond.fill")

            let packs: [(label: String, diamonds: Int, price: String, color: Color)] = [
                ("STARTER",  100,  "$0.99",  .pathriftNeonBlue),
                ("GAMER",    350,  "$2.99",  .pathriftPurple),
                ("PRO",      800,  "$5.99",  .pathriftGold),
                ("ELITE",   2000, "$12.99",  Color(red: 1, green: 0.3, blue: 0.3)),
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(packs, id: \.label) { pack in
                    Button(action: {
                        // Mock purchase — real StoreKit in Phase 7
                        DiamondStore.shared.earn(pack.diamonds)
                        diamonds = DiamondStore.shared.balance
                    }) {
                        VStack(spacing: 6) {
                            Text(pack.label)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.pathriftTextSecondary)
                                .kerning(1.5)
                            HStack(spacing: 4) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(pack.color)
                                Text("\(pack.diamonds)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(pack.color)
                            }
                            Text(pack.price)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.pathriftTextPrimary)
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(pack.color.opacity(0.18))
                                .cornerRadius(8)
                        }
                        .padding(12)
                        .background(Color.pathriftSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(pack.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // MARK: - Section 4: Watch Ad (rewarded ads)

    private var watchAdSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("FREE DIAMONDS", icon: "play.rectangle.fill")

            VStack(spacing: 10) {
                // Progress indicator
                HStack {
                    ForEach(0..<AdRewardStore.shared.maxDailyAds, id: \.self) { i in
                        Circle()
                            .fill(i < adsWatchedToday ? Color.pathriftGold : Color.pathriftSurface)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(Color.pathriftGold.opacity(0.4), lineWidth: 1))
                    }
                    Text("\(adsWatchedToday)/\(AdRewardStore.shared.maxDailyAds) today")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.pathriftTextSecondary)
                    Spacer()
                    Text("+\(AdRewardStore.shared.rewardPerAd) ♦ per ad")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }

                let canWatch = AdRewardStore.shared.canWatch
                Button(action: {
                    if AdRewardStore.shared.watchAd() {
                        diamonds = DiamondStore.shared.balance
                        adsWatchedToday = AdRewardStore.shared.adsWatchedToday
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: canWatch ? "play.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text(canWatch ? "WATCH AD — GET +\(AdRewardStore.shared.rewardPerAd) ♦" : "DAILY LIMIT REACHED")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Spacer()
                        if canWatch {
                            Text("\(AdRewardStore.shared.adsRemaining) left")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.pathriftGold.opacity(0.7))
                        }
                    }
                    .foregroundColor(canWatch ? .pathriftBackground : .pathriftTextSecondary)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(canWatch ? Color.pathriftGold : Color.pathriftSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(canWatch ? Color.clear : Color.pathriftTextSecondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!canWatch)
            }
            .padding(16)
            .background(Color.pathriftSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.pathriftGold.opacity(0.2), lineWidth: 1)
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
            TowerShapeView(type: type, size: 64)
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
                TowerShapeView(type: type, size: 56)
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
        let isFreeT = type.diamondCost == 0
        if isUnlocked || isFreeT {
            // Owned / Free
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.pathriftSuccess)
                Text(isFreeT ? "FREE" : "OWNED").font(.system(size: 15, weight: .bold)).foregroundColor(.pathriftSuccess)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.pathriftSuccess.opacity(0.12))
            .cornerRadius(14)
            .padding(.horizontal, 24)
        } else if let price = type.iapPrice {
            // IAP tower (Tesla / Nova) — real money + diamond alternative
            VStack(spacing: 10) {
                // Primary: Buy with money
                Button(action: {
                    // Mock IAP purchase — real StoreKit in Phase 7
                    DiamondStore.shared.iapUnlock(type)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.fill").font(.system(size: 13))
                        Text("BUY NOW — \(price)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.pathriftBackground)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        LinearGradient(colors: [.pathriftGold, Color(red: 1, green: 0.6, blue: 0)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.pathriftGold.opacity(0.4), radius: 8, y: 3)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)

                // Secondary: diamond unlock
                let canAffordD = diamonds >= type.diamondCost
                Button(action: {
                    if DiamondStore.shared.unlock(type) {
                        diamonds = DiamondStore.shared.balance
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("♦")
                        Text("Unlock with \(type.diamondCost) diamonds")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(canAffordD ? .pathriftNeonBlue : .pathriftTextSecondary.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Color.pathriftSurface)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(canAffordD ? Color.pathriftNeonBlue.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
                }
                .disabled(!canAffordD)
                .padding(.horizontal, 24)

                if !canAffordD {
                    Text("Need \(type.diamondCost - diamonds) more ♦")
                        .font(.system(size: 11)).foregroundColor(.pathriftDanger)
                }
            }
        } else {
            // Diamond-only tower
            let canAffordD = diamonds >= type.diamondCost
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
                    .foregroundColor(canAffordD ? .pathriftBackground : .pathriftTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(canAffordD ? Color.pathriftNeonBlue : Color.pathriftSurface)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(canAffordD ? Color.clear : Color.pathriftTextSecondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(!canAffordD)
                .padding(.horizontal, 24)
                if !canAffordD {
                    Text("Need \(type.diamondCost - diamonds) more ♦")
                        .font(.system(size: 11)).foregroundColor(.pathriftDanger)
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
