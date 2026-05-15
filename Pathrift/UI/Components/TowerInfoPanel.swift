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
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()
                compactCard
            }
        }
    }

    private var compactCard: some View {
        HStack(spacing: 0) {
            // Left accent bar — tower color
            RoundedRectangle(cornerRadius: 2)
                .fill(info.towerType.swiftUIColor)
                .frame(width: 4)
                .padding(.vertical, 8)
                .padding(.leading, 12)

            // Identity: name + level + targeting
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(info.towerType.displayName.uppercased())
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.pathriftTextPrimary)
                    Text("Lv.\(info.level)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftNeonBlue)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.pathriftNeonBlue.opacity(0.15))
                        .cornerRadius(4)
                }
                let mode = info.towerType.targetingMode
                if mode != .groundOnly {
                    Text(mode == .allLayers ? "ALL LAYERS" : "BRIDGE ONLY")
                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                        .foregroundColor(.pathriftTextSecondary)
                }
            }
            .padding(.leading, 10)
            .frame(width: 96, alignment: .leading)

            // Stats + advantage hint
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    miniStat(value: String(format: "%.0f", info.damage), label: "DMG", color: .pathriftOrange)
                    Color.pathriftTextSecondary.opacity(0.2).frame(width: 1, height: 20)
                    miniStat(value: String(format: "%.0ft", info.range / 64 * 3), label: "RNG", color: .pathriftNeonBlue)
                    Color.pathriftTextSecondary.opacity(0.2).frame(width: 1, height: 20)
                    miniStat(value: String(format: "%.1f/s", 1.0 / info.attackSpeed), label: "SPD", color: .pathriftPurple)
                }
                if let hint = info.towerType.typeAdvantageHint {
                    Text(hint)
                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                        .foregroundColor(info.towerType.swiftUIColor)
                        .lineLimit(1)
                        .kerning(0.3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.25))
            .cornerRadius(8)
            .frame(maxWidth: .infinity)

            // Action buttons
            HStack(spacing: 6) {
                Button(action: onUpgrade) {
                    VStack(spacing: 1) {
                        Text("UPGRADE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                        Text("\(info.upgradeCost)g")
                            .font(.system(size: 8, design: .monospaced)).opacity(0.8)
                    }
                    .foregroundColor(canAffordUpgrade ? .pathriftBackground : .pathriftTextSecondary)
                    .frame(width: 72, height: 38)
                    .background(canAffordUpgrade ? Color.pathriftNeonBlue : Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(canAffordUpgrade ? .clear : Color.pathriftTextSecondary.opacity(0.25), lineWidth: 1))
                }
                .disabled(!canAffordUpgrade)
                .buttonStyle(ScaleButtonStyle())

                Button(action: onSell) {
                    VStack(spacing: 1) {
                        Text("SELL")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                        Text("+\(info.sellValue)g")
                            .font(.system(size: 8, design: .monospaced)).opacity(0.8)
                    }
                    .foregroundColor(.pathriftDanger)
                    .frame(width: 56, height: 38)
                    .background(Color.pathriftDanger.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.pathriftDanger.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.pathriftTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.trailing, 12)
            .padding(.leading, 8)
        }
        .frame(height: 58)
        .background(.ultraThinMaterial)
        .background(Color.pathriftBackground.opacity(0.88))
        .overlay(alignment: .top) {
            info.towerType.swiftUIColor.opacity(0.4).frame(height: 1)
        }
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextPrimary)
            Text(label)
                .font(.system(size: 7, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
                .kerning(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
