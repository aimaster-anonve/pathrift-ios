import SwiftUI

struct HowToPlayScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Button(action: { appState.goHome() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.pathriftNeonBlue)
                    }
                    Spacer()
                    Text("HOW TO PLAY")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftTextPrimary)
                        .kerning(2)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ruleSection(title: "PLACE TOWERS", icon: "square.grid.3x3.fill",
                            text: "Tap empty slots to place towers. Each tower has unique strengths.")
                        ruleSection(title: "SEND WAVES", icon: "play.fill",
                            text: "Press SEND WAVE to start the next enemy wave. Enemies follow the path.")
                        ruleSection(title: "RIFT SHIFT", icon: "bolt.fill",
                            text: "Every 5 waves the map shifts! Move and reposition your towers.")
                        ruleSection(title: "TOWERS", icon: "scope",
                            text: "Bolt: Fast single-target\nBlast: Area damage\nFrost: Slows enemies 40%")
                        ruleSection(title: "LIVES", icon: "heart.fill",
                            text: "You have 3 lives. Each enemy that reaches the exit costs 1 life.")
                        ruleSection(title: "SCORE", icon: "star.fill",
                            text: "Score = Wave × 1000 + Kills × 5. Push as far as you can!")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }

                Spacer()
            }
        }
    }

    private func ruleSection(title: String, icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.pathriftNeonBlue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.pathriftNeonBlue)
                    .kerning(1.5)
                Text(text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.pathriftTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.pathriftSurface)
        .cornerRadius(10)
    }
}
