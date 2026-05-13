import SwiftUI

struct TowerInfoPanel: View {
    let info: GameViewModel.TowerInfo
    let gold: Int
    let onUpgrade: () -> Void
    let onSell: () -> Void
    let onDismiss: () -> Void

    var canAffordUpgrade: Bool { gold >= info.upgradeCost }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()
                panel
            }
        }
    }

    private var panel: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.pathriftTextSecondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            VStack(spacing: 16) {
                // Header
                HStack {
                    Circle()
                        .fill(info.towerType.swiftUIColor)
                        .frame(width: 12, height: 12)
                        .shadow(color: info.towerType.swiftUIColor, radius: 4)
                    Text(info.towerType.displayName.uppercased())
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.pathriftTextPrimary)
                        .kerning(1)
                    Text("Lv.\(info.level)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftNeonBlue)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.pathriftNeonBlue.opacity(0.15))
                        .cornerRadius(6)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.pathriftTextSecondary)
                    }
                }

                // Stats row
                HStack(spacing: 0) {
                    statItem(icon: "bolt.fill", label: "DMG",
                             value: String(format: "%.0f", info.damage),
                             color: .pathriftOrange)
                    Divider().background(Color.pathriftTextSecondary.opacity(0.2)).frame(height: 32)
                    statItem(icon: "scope", label: "RNG",
                             value: String(format: "%.0f", info.range / 64 * 3) + "t",
                             color: .pathriftNeonBlue)
                    Divider().background(Color.pathriftTextSecondary.opacity(0.2)).frame(height: 32)
                    statItem(icon: "timer", label: "SPD",
                             value: String(format: "%.1f/s", 1.0 / info.attackSpeed),
                             color: .pathriftPurple)
                }
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)

                // Type advantage hint
                if let hint = info.towerType.typeAdvantageHint {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.pathriftGold)
                        Text(hint)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.pathriftGold)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.pathriftGold.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.pathriftGold.opacity(0.25), lineWidth: 1))
                }

                // Upgrade & Sell buttons
                HStack(spacing: 12) {
                    // Upgrade
                    Button(action: onUpgrade) {
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 13))
                                Text("UPGRADE")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .kerning(0.5)
                            }
                            Text("\(info.upgradeCost)g")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .opacity(0.8)
                        }
                        .foregroundColor(canAffordUpgrade ? .pathriftBackground : .pathriftTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canAffordUpgrade ? Color.pathriftNeonBlue : Color.pathriftSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(canAffordUpgrade ? .clear : Color.pathriftTextSecondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(!canAffordUpgrade)
                    .buttonStyle(ScaleButtonStyle())

                    // Sell
                    Button(action: onSell) {
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: "dollarsign.circle")
                                    .font(.system(size: 13))
                                Text("SELL")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .kerning(0.5)
                            }
                            Text("+\(info.sellValue)g")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .opacity(0.8)
                        }
                        .foregroundColor(.pathriftDanger)
                        .frame(width: 100)
                        .frame(height: 52)
                        .background(Color.pathriftSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.pathriftDanger.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // Tower description
                Text(info.towerType.description)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .padding(.top, 8)
        }
        .background(Color.pathriftSurface)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextPrimary)
            Text(label)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(1)
        }
        .frame(maxWidth: .infinity)
    }
}
