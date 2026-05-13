import SwiftUI

struct ArsenalScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var diamonds = DiamondStore.shared.balance
    @State private var refreshToggle = false

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(TowerType.allCases) { type in
                            TowerArsenalCard(type: type, diamonds: $diamonds)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
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
                    Text("HOME")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.pathriftNeonBlue)
            }
            Spacer()
            Text("ARSENAL")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.pathriftTextPrimary)
                .kerning(2)
            Spacer()
            HStack(spacing: 4) {
                Text("♦")
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                Text("\(diamonds)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.pathriftSurface.opacity(0.9))
    }
}

struct TowerArsenalCard: View {
    let type: TowerType
    @Binding var diamonds: Int

    var isUnlocked: Bool { DiamondStore.shared.isUnlocked(type) }
    var dmgLevel: Int { ArsenalStore.shared.permDamageLevel(for: type) }
    var spdLevel: Int { ArsenalStore.shared.permSpeedLevel(for: type) }
    var dmgCost: Int? { ArsenalStore.shared.dmgUpgradeCost(for: type) }
    var spdCost: Int? { ArsenalStore.shared.speedUpgradeCost(for: type) }

    var towerColor: Color { type.swiftUIColor }

    var body: some View {
        HStack(spacing: 12) {
            // Left: identity (max 45% width)
            HStack(spacing: 8) {
                Circle()
                    .fill(towerColor)
                    .frame(width: 32, height: 32)
                    .shadow(color: towerColor.opacity(0.4), radius: 4)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(type.displayName.uppercased())
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.pathriftTextPrimary)
                        Text("T\(type.tier)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(towerColor)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(towerColor.opacity(0.15))
                            .cornerRadius(3)
                    }
                    Text(type.typeAdvantageHint ?? type.description)
                        .font(.system(size: 10))
                        .foregroundColor(.pathriftTextSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isUnlocked {
                Divider().frame(height: 40)
                upgradeRow(label: "DMG", level: dmgLevel, cost: dmgCost, color: .pathriftOrange) {
                    if let cost = dmgCost, DiamondStore.shared.spend(cost) {
                        ArsenalStore.shared.setPermDamageLevel(dmgLevel + 1, for: type)
                        diamonds = DiamondStore.shared.balance
                    }
                }
                .frame(width: 100)
                Divider().frame(height: 40)
                upgradeRow(label: "SPD", level: spdLevel, cost: spdCost, color: .pathriftPurple) {
                    if let cost = spdCost, DiamondStore.shared.spend(cost) {
                        ArsenalStore.shared.setPermSpeedLevel(spdLevel + 1, for: type)
                        diamonds = DiamondStore.shared.balance
                    }
                }
                .frame(width: 100)
            } else {
                Spacer()
                VStack(spacing: 2) {
                    Text("🔒").font(.system(size: 14))
                    Text("\(type.diamondCost)♦")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                }
            }
        }
        .padding(12)
        .background(Color.pathriftSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .strokeBorder(isUnlocked ? towerColor.opacity(0.2) : Color.pathriftTextSecondary.opacity(0.12), lineWidth: 1))
        .opacity(isUnlocked ? 1.0 : 0.6)
    }

    private func upgradeRow(label: String, level: Int, cost: Int?, color: Color, onUpgrade: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary)
                    .kerning(1)
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < level ? color : Color.pathriftTextSecondary.opacity(0.2))
                            .frame(width: 14, height: 5)
                    }
                }
            }
            Spacer()
            if let cost = cost {
                Button(action: onUpgrade) {
                    Text("+\(cost)♦")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(diamonds >= cost ? color : .pathriftTextSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background((diamonds >= cost ? color : Color.pathriftTextSecondary).opacity(0.12))
                        .cornerRadius(6)
                        .lineLimit(1)
                }
                .disabled(diamonds < cost)
            } else {
                Text("MAX")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
            }
        }
    }
}
