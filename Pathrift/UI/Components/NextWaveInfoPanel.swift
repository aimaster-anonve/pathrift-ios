import SwiftUI

struct NextWaveInfoPanel: View {
    let waveDef: WaveDefinition
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture { isVisible = false }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("NEXT WAVE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0, green: 0.78, blue: 1))
                        Spacer()
                        Button("✕") { isVisible = false }
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 12))
                    }

                    if waveDef.spawns.isEmpty {
                        Text("BOSS WAVE")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.8))
                    } else {
                        ForEach(waveDef.spawns, id: \.type.rawValue) { entry in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(entry.type.indicatorColor)
                                    .frame(width: 10, height: 10)
                                Text(entry.type.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("×\(entry.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(red: 0, green: 0.78, blue: 1))
                            }
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.05, green: 0.08, blue: 0.15).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0, green: 0.78, blue: 1).opacity(0.4), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 60)
            }
        }
    }
}

extension EnemyType {
    var indicatorColor: Color {
        switch self {
        case .runner:   return Color(red: 0.2, green: 0.5, blue: 1.0)
        case .tank:     return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .boss:     return Color(red: 0.8, green: 0.2, blue: 1.0)
        case .shield:   return Color(red: 0.2, green: 0.8, blue: 0.3)
        case .swarm:    return Color(red: 1.0, green: 0.9, blue: 0.2)
        case .ghost:    return Color(red: 0.8, green: 0.8, blue: 1.0)
        case .splitter: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .jumper:   return Color(red: 0.0, green: 0.8, blue: 0.6)
        case .healer:   return Color(red: 0.2, green: 1.0, blue: 0.4)
        case .phantom:  return Color(red: 0.7, green: 0.3, blue: 1.0)
        }
    }
}
