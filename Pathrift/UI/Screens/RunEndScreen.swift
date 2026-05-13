import SwiftUI

struct RunEndScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var animateScore: Bool = false
    @State private var displayedScore: Int = 0
    @State private var isNewHighScore: Bool = false

    private var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .onAppear {
            checkHighScore()
            animateScoreCount()
        }
    }

    private var result: RunResult? { appState.lastRunResult }

    // MARK: - Portrait Layout (original)

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            headerSection
            Spacer().frame(height: 40)
            statsSection
            Spacer().frame(height: 48)
            actionsSection
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Landscape Layout (two-panel)

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            // Left panel (45%): score display
            VStack(spacing: 10) {
                Spacer()
                Text(result?.isVictory == true ? "VICTORY" : "RUN OVER")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(result?.isVictory == true ? .pathriftSuccess : .pathriftDanger)
                    .shadow(color: (result?.isVictory == true ? Color.pathriftSuccess : Color.pathriftDanger).opacity(0.6), radius: 10)

                if isNewHighScore {
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill").foregroundColor(.pathriftGold)
                        Text("NEW HIGH SCORE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.pathriftGold)
                            .kerning(1.5)
                        Image(systemName: "star.fill").foregroundColor(.pathriftGold)
                    }
                }

                Text(ScoreCalculator.formatScore(displayedScore))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.pathriftNeonBlue)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: displayedScore)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            Rectangle()
                .fill(Color.pathriftTextSecondary.opacity(0.12))
                .frame(width: 1)

            // Right panel (55%): stats + actions
            VStack(spacing: 12) {
                Spacer()
                landscapeStatsSection
                VStack(spacing: 10) {
                    PathriftButton(title: "PLAY AGAIN", icon: "arrow.clockwise", style: .primary) {
                        appState.startGame()
                    }
                    PathriftButton(title: "MAIN MENU", icon: "house.fill", style: .secondary) {
                        appState.goHome()
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
        }
    }

    private var landscapeStatsSection: some View {
        VStack(spacing: 8) {
            statRow(icon: "flag.fill", label: "WAVES REACHED",
                    value: "\(result?.wavesReached ?? 0)", color: .pathriftNeonBlue)
            statRow(icon: "xmark.circle.fill", label: "ENEMY KILLS",
                    value: "\(result?.enemyKills ?? 0)", color: .pathriftDanger)
            statRow(icon: "trophy.fill", label: "FINAL SCORE",
                    value: ScoreCalculator.formatScore(result?.score ?? 0), color: .pathriftGold)
        }
        .padding(14)
        .background(Color.pathriftSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .strokeBorder(Color.pathriftNeonBlue.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Portrait sub-views

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(result?.isVictory == true ? "VICTORY" : "RUN OVER")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(result?.isVictory == true ? .pathriftSuccess : .pathriftDanger)
                .shadow(color: (result?.isVictory == true ? Color.pathriftSuccess : Color.pathriftDanger).opacity(0.6), radius: 16)

            if isNewHighScore {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill").foregroundColor(.pathriftGold)
                    Text("NEW HIGH SCORE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                        .kerning(2)
                    Image(systemName: "star.fill").foregroundColor(.pathriftGold)
                }
            }

            Text(ScoreCalculator.formatScore(displayedScore))
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundColor(.pathriftNeonBlue)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: displayedScore)
        }
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            statRow(icon: "flag.fill", label: "WAVES REACHED",
                    value: "\(result?.wavesReached ?? 0)", color: .pathriftNeonBlue)
            statRow(icon: "xmark.circle.fill", label: "ENEMY KILLS",
                    value: "\(result?.enemyKills ?? 0)", color: .pathriftDanger)
            statRow(icon: "trophy.fill", label: "FINAL SCORE",
                    value: ScoreCalculator.formatScore(result?.score ?? 0), color: .pathriftGold)
        }
        .padding(20)
        .background(Color.pathriftSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(Color.pathriftNeonBlue.opacity(0.2), lineWidth: 1))
    }

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .frame(width: 24)

            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(1)

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.pathriftTextPrimary)
                .monospacedDigit()
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 14) {
            PathriftButton(title: "PLAY AGAIN", icon: "arrow.clockwise", style: .primary) {
                appState.startGame()
            }
            PathriftButton(title: "MAIN MENU", icon: "house.fill", style: .secondary) {
                appState.goHome()
            }
        }
    }

    private func checkHighScore() {
        guard let score = result?.score else { return }
        let previous = LocalRunStorage.shared.loadHighScore()
        if score > previous {
            LocalRunStorage.shared.saveHighScore(score)
            isNewHighScore = true
        }
    }

    private func animateScoreCount() {
        guard let finalScore = result?.score, finalScore > 0 else {
            displayedScore = result?.score ?? 0
            return
        }
        let steps = 30
        let stepValue = finalScore / steps
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                if i == steps {
                    displayedScore = finalScore
                } else {
                    displayedScore = stepValue * i
                }
            }
        }
    }
}
