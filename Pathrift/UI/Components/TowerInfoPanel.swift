import SwiftUI

struct TowerInfoPanel: View {
    let info: GameViewModel.TowerInfo
    let gold: Int
    let onUpgrade: () -> Void
    let onSell: () -> Void
    let onDismiss: () -> Void

    var canAffordUpgrade: Bool { gold >= info.upgradeCost }

    private var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()
                if isLandscape {
                    landscapePanel
                } else {
                    portraitPanel
                }
            }
        }
    }

    // MARK: - Landscape Panel (compact 160pt right action column)

    private var landscapePanel: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.pathriftTextSecondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            // Header row
            HStack {
                Circle().fill(info.towerType.swiftUIColor).frame(width: 10, height: 10)
                    .shadow(color: info.towerType.swiftUIColor, radius: 3)
                Text(info.towerType.displayName.uppercased())
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.pathriftTextPrimary)
                    .kerning(0.5)
                Text("Lv.\(info.level)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.pathriftNeonBlue)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.pathriftNeonBlue.opacity(0.15)).cornerRadius(5)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 16))
                        .foregroundColor(.pathriftTextSecondary)
                }
            }
            .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 4)

            // Main: stats left + buttons right
            HStack(alignment: .center, spacing: 0) {
                // Left: stats
                VStack(spacing: 6) {
                    // Compact stats row
                    HStack(spacing: 0) {
                        compactStatItem(icon: "bolt.fill", label: "DMG",
                            value: String(format: "%.0f", info.damage), color: .pathriftOrange)
                        Divider().frame(height: 28)
                        compactStatItem(icon: "scope", label: "RNG",
                            value: String(format: "%.0f", info.range / 64 * 3) + "t", color: .pathriftNeonBlue)
                        Divider().frame(height: 28)
                        compactStatItem(icon: "timer", label: "SPD",
                            value: String(format: "%.1f/s", 1.0 / info.attackSpeed), color: .pathriftPurple)
                    }
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)

                    // Type advantage
                    if let hint = info.towerType.typeAdvantageHint {
                        Text(hint)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.pathriftGold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Targeting mode badge
                    landscapeTargetingBadge
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
                .frame(maxWidth: .infinity)

                Divider().frame(height: 80)

                // Right: action buttons
                VStack(spacing: 6) {
                    // Upgrade button
                    Button(action: onUpgrade) {
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.circle.fill").font(.system(size: 11))
                                Text("UPGRADE").font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            Text("\(info.upgradeCost)g").font(.system(size: 10, weight: .semibold)).opacity(0.8)
                        }
                        .foregroundColor(canAffordUpgrade ? .pathriftBackground : .pathriftTextSecondary)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(canAffordUpgrade ? Color.pathriftNeonBlue : Color.pathriftSurface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(canAffordUpgrade ? Color.clear : Color.pathriftTextSecondary.opacity(0.3), lineWidth: 1))
                    }
                    .disabled(!canAffordUpgrade)
                    .buttonStyle(ScaleButtonStyle())

                    // Sell button
                    Button(action: onSell) {
                        HStack(spacing: 4) {
                            Text("SELL").font(.system(size: 12, weight: .bold, design: .rounded))
                            Text("+\(info.sellValue)g").font(.system(size: 10, weight: .semibold)).opacity(0.8)
                        }
                        .foregroundColor(.pathriftDanger)
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(Color.pathriftSurface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.pathriftDanger.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .frame(width: 140)
            }
            .padding(.bottom, 12)
        }
        .background(Color.pathriftSurface)
        .cornerRadius(18, corners: [.topLeft, .topRight])
    }

    private func compactStatItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(color)
            Text(value).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.pathriftTextPrimary)
            Text(label).font(.system(size: 7, weight: .semibold, design: .monospaced)).foregroundColor(.pathriftTextSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var landscapeTargetingBadge: some View {
        let mode = info.towerType.targetingMode
        if mode != .groundOnly {
            HStack(spacing: 4) {
                Image(systemName: mode == .allLayers ? "square.stack.fill" : "arrow.up.square.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.pathriftTextSecondary)
                Text(mode == .allLayers ? "ALL LAYERS" : "BRIDGE ONLY")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary)
            }
        }
    }

    // MARK: - Portrait Panel (compact — max ~160pt visible height)

    private var portraitPanel: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.pathriftTextSecondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            VStack(spacing: 10) {
                // Header
                HStack {
                    Circle()
                        .fill(info.towerType.swiftUIColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: info.towerType.swiftUIColor, radius: 3)
                    Text(info.towerType.displayName.uppercased())
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(.pathriftTextPrimary)
                    Text("Lv.\(info.level)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftNeonBlue)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.pathriftNeonBlue.opacity(0.15)).cornerRadius(5)
                    if let hint = info.towerType.typeAdvantageHint {
                        Text("⚡")
                            .font(.system(size: 11))
                            .help(hint)
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.pathriftTextSecondary)
                    }
                }

                // Stats + buttons in one row
                HStack(spacing: 0) {
                    // Stats inline
                    HStack(spacing: 0) {
                        statItem(icon: "bolt.fill", label: "DMG",
                                 value: String(format: "%.0f", info.damage), color: .pathriftOrange)
                        Divider().frame(height: 28)
                        statItem(icon: "scope", label: "RNG",
                                 value: String(format: "%.0f", info.range / 64 * 3) + "t", color: .pathriftNeonBlue)
                        Divider().frame(height: 28)
                        statItem(icon: "timer", label: "SPD",
                                 value: String(format: "%.1f/s", 1.0 / info.attackSpeed), color: .pathriftPurple)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)

                    // Buttons
                    HStack(spacing: 6) {
                        Button(action: onUpgrade) {
                            VStack(spacing: 2) {
                                Text("UPGRADE").font(.system(size: 11, weight: .bold, design: .rounded))
                                Text("\(info.upgradeCost)g").font(.system(size: 9, design: .monospaced)).opacity(0.8)
                            }
                            .foregroundColor(canAffordUpgrade ? .pathriftBackground : .pathriftTextSecondary)
                            .frame(width: 80).frame(height: 40)
                            .background(canAffordUpgrade ? Color.pathriftNeonBlue : Color.pathriftSurface)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(canAffordUpgrade ? .clear : Color.pathriftTextSecondary.opacity(0.3), lineWidth: 1))
                        }
                        .disabled(!canAffordUpgrade).buttonStyle(ScaleButtonStyle())

                        Button(action: onSell) {
                            VStack(spacing: 2) {
                                Text("SELL").font(.system(size: 11, weight: .bold, design: .rounded))
                                Text("+\(info.sellValue)g").font(.system(size: 9, design: .monospaced)).opacity(0.8)
                            }
                            .foregroundColor(.pathriftDanger)
                            .frame(width: 64).frame(height: 40)
                            .background(Color.pathriftSurface)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.pathriftDanger.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.leading, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .padding(.top, 6)
        }
        .background(.ultraThinMaterial)
        .background(Color.pathriftSurface.opacity(0.92))
        .cornerRadius(18, corners: [.topLeft, .topRight])
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
            Text(value).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.pathriftTextPrimary)
            Text(label).font(.system(size: 8, weight: .semibold, design: .monospaced)).foregroundColor(.pathriftTextSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity)
    }
}
