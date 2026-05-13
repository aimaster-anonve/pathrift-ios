import SwiftUI

struct HowToPlayScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ruleSection(title: "PLACE TOWERS", icon: "square.grid.3x3.fill",
                            text: "Tap empty slots to place towers. Each tower has unique strengths.")
                        ruleSection(title: "SEND WAVES", icon: "play.fill",
                            text: "Press SEND WAVE to start the next enemy wave. Enemies follow the path.")
                        ruleSection(title: "RIFT SHIFT", icon: "bolt.fill",
                            text: "Every 5 waves the map shifts! Move and reposition your towers.")
                        ruleSection(title: "TOWERS", icon: "scope",
                            text: "Bolt: Fast single-target\nBlast: Area damage\nFrost: Slows enemies 40%\nSniper: Long range, all layers\nArtillery: Bridge only, AoE")
                        ruleSection(title: "BRIDGE LAYERS", icon: "square.stack.fill",
                            text: "Some maps have bridge segments. Sniper hits all layers. Artillery targets bridges only.")
                        ruleSection(title: "LIVES", icon: "heart.fill",
                            text: "You have 3 lives. Each enemy that reaches the exit costs 1 life.")
                        ruleSection(title: "SCORE", icon: "star.fill",
                            text: "Score = Wave × 1000 + Kills × 5. Push as far as you can!")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
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
            Text("HOW TO PLAY")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextPrimary)
                .kerning(2)
            Spacer()
            Color.clear.frame(width: 60, height: 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.pathriftSurface.opacity(0.9))
    }

    private func ruleSection(title: String, icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.pathriftNeonBlue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.pathriftNeonBlue)
                    .kerning(1.5)
                Text(text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.pathriftTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.pathriftSurface)
        .cornerRadius(10)
    }
}
