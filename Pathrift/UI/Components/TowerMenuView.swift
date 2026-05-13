import SwiftUI
import SpriteKit

struct TowerMenuView: View {
    let slotId: Int
    let goldAvailable: Int
    let onSelect: (TowerType) -> Void
    let onDismiss: () -> Void

    @State private var selectedType: TowerType? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()
                menuCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: true)
        }
    }

    private var menuCard: some View {
        VStack(spacing: 0) {
            dragHandle

            VStack(spacing: 12) {
                headerRow
                towerGrid
                if let type = selectedType {
                    towerDetailPanel(type)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                confirmButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .padding(.top, 8)
        }
        .background(Color.pathriftSurface)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }

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
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.pathriftGold)
                    .font(.caption)
                Text("\(goldAvailable)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.pathriftGold)
            }
        }
    }

    private var towerGrid: some View {
        HStack(spacing: 10) {
            ForEach(TowerType.allCases) { type in
                TowerCardButton(
                    type: type,
                    isSelected: selectedType == type,
                    canAfford: goldAvailable >= type.cost
                ) {
                    withAnimation(.spring(response: 0.25)) {
                        selectedType = selectedType == type ? nil : type
                    }
                }
            }
        }
    }

    private func towerDetailPanel(_ type: TowerType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.description)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }

    private var confirmButton: some View {
        Group {
            if let type = selectedType {
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
            } else {
                Text("Select a tower type above")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
        }
    }
}

struct TowerCardButton: View {
    let type: TowerType
    let isSelected: Bool
    let canAfford: Bool
    let action: () -> Void

    var towerColor: Color {
        switch type {
        case .bolt:  return Color(red: 0.0,  green: 0.78, blue: 1.0)
        case .blast: return Color(red: 1.0,  green: 0.42, blue: 0.0)
        case .frost: return Color(red: 0.55, green: 0.31, blue: 1.0)
        }
    }

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
                    Image(systemName: towerIcon)
                        .foregroundColor(isSelected ? .white : towerColor)
                        .font(.system(size: 18, weight: .bold))
                }
                .shadow(color: isSelected ? towerColor.opacity(0.5) : .clear, radius: 8)

                Text(type.displayName.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .pathriftTextPrimary : .pathriftTextSecondary)

                Text("\(type.cost)g")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(canAfford ? .pathriftGold : .pathriftDanger)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? towerColor.opacity(0.12) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? towerColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(canAfford ? 1.0 : 0.5)
    }

    private var towerIcon: String {
        switch type {
        case .bolt:  return "bolt.fill"
        case .blast: return "flame.fill"
        case .frost: return "snowflake"
        }
    }
}
