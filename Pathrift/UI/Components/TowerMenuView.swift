import SwiftUI
import SpriteKit

struct TowerMenuView: View {
    let slotId: Int
    let goldAvailable: Int
    let diamonds: Int
    let onSelect: (TowerType) -> Void
    let onUnlockTower: (TowerType) -> Void
    let onDismiss: () -> Void

    @State private var selectedType: TowerType? = nil
    @State private var showUnlockConfirm: Bool = false

    private var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()
                if isLandscape {
                    landscapeMenuCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    portraitMenuCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: true)
        }
    }

    // MARK: - Portrait Menu Card (original)

    private var portraitMenuCard: some View {
        VStack(spacing: 0) {
            dragHandle

            VStack(spacing: 12) {
                headerRow
                towerGrid
                if let type = selectedType {
                    towerDetailPanel(type)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                actionButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .padding(.top, 8)
        }
        .background(Color.pathriftSurface)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }

    // MARK: - Landscape Menu Card (100pt compact horizontal)

    private var landscapeMenuCard: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.pathriftTextSecondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            HStack(spacing: 0) {
                // Left: horizontal tower scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TowerType.allCases) { type in
                            landscapeTowerCard(type)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.pathriftTextSecondary.opacity(0.2))
                    .frame(width: 1)

                // Right: action area (160pt)
                VStack(spacing: 6) {
                    if let type = selectedType {
                        if let hint = type.typeAdvantageHint {
                            Text(hint)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.pathriftGold)
                                .lineLimit(1)
                        }
                        landscapeActionButton(type: type)
                    } else {
                        Text("SELECT\nTOWER")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.pathriftTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: 160)
                .padding(.horizontal, 12)
            }
            .frame(height: 80)
            .padding(.bottom, 10)
        }
        .background(Color.pathriftSurface)
        .cornerRadius(18, corners: [.topLeft, .topRight])
    }

    private func landscapeTowerCard(_ type: TowerType) -> some View {
        let isSelected = selectedType == type
        let canAfford = goldAvailable >= type.cost
        let isUnlocked = DiamondStore.shared.isUnlocked(type)

        return Button(action: {
            withAnimation(.spring(response: 0.25)) {
                selectedType = isSelected ? nil : type
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.swiftUIColor : type.swiftUIColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().strokeBorder(type.swiftUIColor.opacity(isSelected ? 1 : 0.4), lineWidth: isSelected ? 2 : 1))
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                }
                Text(String(type.displayName.prefix(4)).uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .pathriftTextPrimary : .pathriftTextSecondary)
                Text(isUnlocked ? "\(type.cost)g" : "\(type.diamondCost)♦")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(isUnlocked ? (canAfford ? .pathriftGold : .pathriftDanger) : Color(red: 0, green: 0.8, blue: 1))
            }
            .frame(width: 52)
            .padding(.vertical, 6)
            .background(isSelected ? type.swiftUIColor.opacity(0.1) : Color.clear)
            .cornerRadius(10)
        }
        .opacity(isUnlocked && canAfford ? 1.0 : 0.5)
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func landscapeActionButton(type: TowerType) -> some View {
        let isUnlocked = DiamondStore.shared.isUnlocked(type)
        if isUnlocked {
            let canAfford = goldAvailable >= type.cost
            Button(action: { if canAfford { onSelect(type) } }) {
                VStack(spacing: 2) {
                    Text(canAfford ? "BUILD" : "NO GOLD")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text(canAfford ? "\(type.displayName) — \(type.cost)g" : "Need \(type.cost)g")
                        .font(.system(size: 9, design: .monospaced))
                }
                .foregroundColor(canAfford ? .pathriftBackground : .pathriftTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(canAfford ? Color.pathriftNeonBlue : Color.pathriftSurface)
                .cornerRadius(10)
            }
            .disabled(!canAfford)
        } else {
            let hasDiamonds = diamonds >= type.diamondCost
            Button(action: { if hasDiamonds { onUnlockTower(type) } }) {
                VStack(spacing: 2) {
                    Text(hasDiamonds ? "UNLOCK" : "NEED MORE ♦")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("\(type.diamondCost)♦")
                        .font(.system(size: 9, design: .monospaced))
                }
                .foregroundColor(hasDiamonds ? .pathriftBackground : .pathriftTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(hasDiamonds ? Color(red: 0, green: 0.78, blue: 1) : Color.pathriftSurface)
                .cornerRadius(10)
            }
            .disabled(!hasDiamonds)
        }
    }

    // MARK: - Shared sub-views

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.pathriftTextSecondary.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    private var headerRow: some View {
        HStack {
            Text("PLACE TOWER")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.pathriftTextPrimary)
                .kerning(1)
            Spacer()
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.pathriftGold)
                        .font(.caption)
                    Text("\(goldAvailable)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }
                HStack(spacing: 4) {
                    Text("♦")
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                        .font(.system(size: 13, weight: .bold))
                    Text("\(diamonds)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                }
            }
        }
    }

    private var towerGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TowerType.allCases) { type in
                    TowerCardButton(
                        type: type,
                        isSelected: selectedType == type,
                        canAfford: goldAvailable >= type.cost,
                        isUnlocked: DiamondStore.shared.isUnlocked(type),
                        diamonds: diamonds
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            selectedType = selectedType == type ? nil : type
                            showUnlockConfirm = false
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func towerDetailPanel(_ type: TowerType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(type.description)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .multilineTextAlignment(.leading)
            if let hint = type.typeAdvantageHint {
                HStack(spacing: 4) {
                    Text("⚡").font(.system(size: 11))
                    Text(hint)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let type = selectedType {
            let isUnlocked = DiamondStore.shared.isUnlocked(type)

            if !isUnlocked {
                let canAffordDiamonds = diamonds >= type.diamondCost
                Button(action: {
                    if canAffordDiamonds { onUnlockTower(type) }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: canAffordDiamonds ? "lock.open.fill" : "lock.fill")
                        Text(canAffordDiamonds
                             ? "UNLOCK \(type.displayName.uppercased()) — \(type.diamondCost)♦"
                             : "NEED \(type.diamondCost)♦ DIAMONDS")
                            .kerning(0.5)
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(canAffordDiamonds ? .black : .pathriftTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(canAffordDiamonds
                                ? Color(red: 0.4, green: 0.8, blue: 1.0)
                                : Color.pathriftSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(canAffordDiamonds ? Color.clear : Color.pathriftTextSecondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(!canAffordDiamonds)
            } else {
                let canAfford = goldAvailable >= type.cost
                Button(action: {
                    if canAfford { onSelect(type) }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: canAfford ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(canAfford ? "BUILD \(type.displayName.uppercased()) — \(type.cost)g" : "NOT ENOUGH GOLD")
                            .kerning(0.5)
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(canAfford ? .pathriftBackground : .pathriftTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(canAfford ? Color.pathriftNeonBlue : Color.pathriftSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(canAfford ? Color.clear : Color.pathriftTextSecondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(!canAfford)
            }
        } else {
            Text("Select a tower type above")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
    }
}

struct TowerCardButton: View {
    let type: TowerType
    let isSelected: Bool
    let canAfford: Bool
    let isUnlocked: Bool
    let diamonds: Int
    let action: () -> Void

    var towerColor: Color { type.swiftUIColor }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? towerColor : towerColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Circle()
                        .strokeBorder(isSelected ? towerColor : towerColor.opacity(0.4), lineWidth: isSelected ? 2.5 : 1)
                        .frame(width: 44, height: 44)
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(isSelected ? .white : towerColor.opacity(0.7))
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Image(systemName: towerIcon)
                            .foregroundColor(isSelected ? .white : towerColor)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .shadow(color: isSelected ? towerColor.opacity(0.5) : .clear, radius: 8)

                Text(type.displayName.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .pathriftTextPrimary : .pathriftTextSecondary)

                if !isUnlocked {
                    Text("\(type.diamondCost)♦")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(diamonds >= type.diamondCost
                                         ? Color(red: 0.4, green: 0.8, blue: 1.0)
                                         : .pathriftDanger)
                } else {
                    Text("\(type.cost)g")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(canAfford ? .pathriftGold : .pathriftDanger)
                }
            }
            .frame(width: 68)
            .padding(.vertical, 10)
            .background(isSelected ? towerColor.opacity(0.12) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? towerColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity((isUnlocked && !canAfford) ? 0.5 : 1.0)
    }

    private var towerIcon: String {
        switch type {
        case .bolt:      return "bolt.fill"
        case .blast:     return "flame.fill"
        case .frost:     return "snowflake"
        case .pierce:    return "arrow.right.to.line.alt"
        case .core:      return "shield.slash.fill"
        case .inferno:   return "flame.circle.fill"
        case .tesla:     return "bolt.circle.fill"
        case .nova:      return "sun.max.fill"
        case .sniper:    return "scope"
        case .artillery: return "target"
        }
    }
}
