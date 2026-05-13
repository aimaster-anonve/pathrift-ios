import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var titlePulse: Bool = false
    @State private var highScore: Int = 0

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            backgroundGrid

            VStack(spacing: 0) {
                Spacer()
                titleSection
                Spacer().frame(height: 60)
                buttonSection
                Spacer()
                footerSection
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            highScore = LocalRunStorage.shared.loadHighScore()
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                titlePulse = true
            }
        }
    }

    private var backgroundGrid: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let spacing: CGFloat = 48
                let cols = Int(size.width / spacing) + 1
                let rows = Int(size.height / spacing) + 1
                let lineColor = GraphicsContext.Shading.color(.white.opacity(0.04))

                for col in 0...cols {
                    let x = CGFloat(col) * spacing
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: lineColor, lineWidth: 0.5)
                }

                for row in 0...rows {
                    let y = CGFloat(row) * spacing
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: lineColor, lineWidth: 0.5)
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("PATHRIFT")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.pathriftNeonBlue)
                .shadow(color: .pathriftNeonBlue.opacity(titlePulse ? 0.9 : 0.3), radius: titlePulse ? 20 : 8)
                .scaleEffect(titlePulse ? 1.02 : 0.98)

            Text("ENDLESS TOWER DEFENSE")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(3)

            if highScore > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.pathriftGold)
                        .font(.caption)
                    Text("BEST: \(ScoreCalculator.formatScore(highScore))")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }
                .padding(.top, 8)
            }
        }
    }

    private var buttonSection: some View {
        VStack(spacing: 16) {
            PathriftButton(
                title: "START RUN",
                icon: "play.fill",
                style: .primary
            ) {
                appState.startGame()
            }

            PathriftButton(
                title: "HOW TO PLAY",
                icon: "questionmark.circle",
                style: .secondary
            ) {
                appState.showHowToPlay()
            }

            towerLegendCard
        }
    }

    private var towerLegendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TOWERS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(2)

            ForEach(TowerType.allCases) { towerType in
                HStack(spacing: 12) {
                    Circle()
                        .fill(towerType.swiftUIColor)
                        .frame(width: 10, height: 10)
                    Text(towerType.displayName.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.pathriftTextPrimary)
                    Spacer()
                    Text("\(towerType.cost)g")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }
            }
        }
        .padding(16)
        .background(Color.pathriftSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.pathriftNeonBlue.opacity(0.3), lineWidth: 1)
        )
    }

    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Phase 1 — Core Combat Prototype")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary.opacity(0.5))
            Text("v1.0.0")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary.opacity(0.3))
        }
        .padding(.bottom, 24)
    }
}
