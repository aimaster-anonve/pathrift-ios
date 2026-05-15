import SwiftUI

struct NextWaveBannerView: View {
    let waveDef: WaveDefinition
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text("NEXT")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary)
                    .kerning(1.5)
                Text("▸")
                    .font(.system(size: 10))
                    .foregroundColor(.pathriftNeonBlue)

                // Show up to 4 enemy types
                ForEach(Array(waveDef.spawns.prefix(4)), id: \.type.rawValue) { entry in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(entry.type.indicatorColor)
                            .frame(width: 7, height: 7)
                        Text("\(entry.type.rawValue.prefix(3))×\(entry.count)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.pathriftTextPrimary)
                    }
                }
                if waveDef.spawns.count > 4 {
                    Text("+\(waveDef.spawns.count - 4)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.pathriftTextSecondary)
                }
                Spacer()
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.pathriftNeonBlue.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.pathriftNeonBlue.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.pathriftNeonBlue.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
