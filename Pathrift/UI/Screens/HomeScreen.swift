import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var lang = LanguageManager.shared
    @State private var titleScale: CGFloat = 1.0
    @State private var titleGlow: CGFloat = 0.3
    @State private var highScore: Int = 0
    @State private var showBestScore = false

    private var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    var body: some View {
        ZStack {
            Color.pathriftBackground.ignoresSafeArea()
            gridBackground

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .onAppear {
            highScore = LocalRunStorage.shared.loadHighScore()
            showBestScore = highScore > 0
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                titleScale = 1.03
                titleGlow = 0.8
            }
        }
    }

    // MARK: - Portrait Layout (original)

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            titleArea
            Spacer().frame(height: 32)
            actionButtons
            Spacer()
            bottomInfo
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Landscape Layout (two-panel)

    private var landscapeLayout: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // LEFT PANEL: 38% width — branding/identity
                leftPanel
                    .frame(maxWidth: geometry.size.width * 0.38)

                Rectangle()
                    .fill(Color.pathriftTextSecondary.opacity(0.12))
                    .frame(width: 1)

                // RIGHT PANEL: remaining width — navigation buttons
                rightPanel
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var leftPanel: some View {
        VStack(alignment: .center, spacing: 10) {
            Spacer()

            // App title
            Text("PATHRIFT")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.pathriftNeonBlue)
                .shadow(color: .pathriftNeonBlue.opacity(titleGlow), radius: 14)
                .scaleEffect(titleScale)

            // Tagline
            Text("ENDLESS TOWER DEFENSE")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(2)

            // Rift indicator
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.pathriftPurple.opacity(0.7))
                    .frame(width: 10, height: 2)
                Text("THE MAP ALWAYS SHIFTS")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.pathriftPurple.opacity(0.8))
                    .kerning(1)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.pathriftPurple.opacity(0.7))
                    .frame(width: 10, height: 2)
            }

            // High score badge
            if showBestScore {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.pathriftGold)
                        .font(.system(size: 11))
                    Text("BEST: \(ScoreCalculator.formatScore(highScore))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(Color.pathriftGold.opacity(0.12))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.pathriftGold.opacity(0.3), lineWidth: 1))
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Version pinned to bottom
            Text("v1.0.0 • Harita değişiyor")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var rightPanel: some View {
        VStack(spacing: 8) {
            Spacer()

            // PLAY button
            Button(action: { appState.startGame() }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").font(.system(size: 14, weight: .bold))
                    Text(lang.s(L.play))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .kerning(2)
                }
                .foregroundColor(.pathriftBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: [Color.pathriftNeonBlue, Color.pathriftPurple],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .pathriftNeonBlue.opacity(0.35), radius: 10, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())

            // HOW TO PLAY
            Button(action: { appState.showHowToPlay() }) {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle").font(.system(size: 13))
                    Text(lang.s(L.howToPlay))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .kerning(0.5)
                }
                .foregroundColor(.pathriftTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.pathriftSurface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.pathriftTextSecondary.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())

            // SETTINGS + STORE row
            HStack(spacing: 8) {
                Button(action: { appState.showSettings() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "gearshape.fill").font(.system(size: 12))
                        Text(lang.s(L.settings))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.pathriftTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.pathriftSurface)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: { appState.showStore() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "diamond.fill").font(.system(size: 12))
                        Text(lang.s(L.store))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.pathriftNeonBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.pathriftNeonBlue.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.pathriftNeonBlue.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // ARSENAL
            Button(action: { appState.showArsenal() }) {
                HStack(spacing: 5) {
                    Image(systemName: "shield.fill").font(.system(size: 12))
                    Text("ARSENAL")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.pathriftOrange)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.pathriftOrange.opacity(0.12))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.pathriftOrange.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())

            // Tower legend — compact
            HStack(spacing: 0) {
                ForEach(TowerType.allCases) { type in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(type.swiftUIColor)
                            .frame(width: 8, height: 8)
                        Text(String(type.displayName.prefix(3)))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.pathriftTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 32)
            .padding(.horizontal, 6)
            .background(Color.pathriftSurface.opacity(0.7))
            .cornerRadius(10)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    // MARK: - Shared sub-views

    private var gridBackground: some View {
        Canvas { context, size in
            let spacing: CGFloat = 44
            let color = GraphicsContext.Shading.color(.white.opacity(0.035))
            let cols = Int(size.width / spacing) + 2
            let rows = Int(size.height / spacing) + 2
            for col in 0..<cols {
                var p = Path()
                p.move(to: CGPoint(x: CGFloat(col)*spacing, y: 0))
                p.addLine(to: CGPoint(x: CGFloat(col)*spacing, y: size.height))
                context.stroke(p, with: color, lineWidth: 0.5)
            }
            for row in 0..<rows {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: CGFloat(row)*spacing))
                p.addLine(to: CGPoint(x: size.width, y: CGFloat(row)*spacing))
                context.stroke(p, with: color, lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }

    private var titleArea: some View {
        VStack(spacing: 10) {
            Text("PATHRIFT")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundColor(.pathriftNeonBlue)
                .shadow(color: .pathriftNeonBlue.opacity(titleGlow), radius: 20)
                .scaleEffect(titleScale)

            Text("ENDLESS TOWER DEFENSE")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(3)

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.pathriftPurple.opacity(0.7))
                    .frame(width: 20, height: 2)
                Text("THE MAP ALWAYS SHIFTS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.pathriftPurple.opacity(0.8))
                    .kerning(1.5)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.pathriftPurple.opacity(0.7))
                    .frame(width: 20, height: 2)
            }
            .padding(.top, 4)

            if showBestScore {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.pathriftGold)
                        .font(.system(size: 13))
                    Text("BEST: \(ScoreCalculator.formatScore(highScore))")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.pathriftGold.opacity(0.12))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.pathriftGold.opacity(0.3), lineWidth: 1))
                .padding(.top, 8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .multilineTextAlignment(.center)
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button(action: { appState.startGame() }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill").font(.system(size: 16, weight: .bold))
                    Text(lang.s(L.play))
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .kerning(2)
                }
                .foregroundColor(.pathriftBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [Color.pathriftNeonBlue, Color.pathriftPurple],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .pathriftNeonBlue.opacity(0.4), radius: 12, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())

            Button(action: { appState.showHowToPlay() }) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle").font(.system(size: 14))
                    Text(lang.s(L.howToPlay))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .kerning(1)
                }
                .foregroundColor(.pathriftTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.pathriftSurface)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.pathriftTextSecondary.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())

            HStack(spacing: 12) {
                Button(action: { appState.showSettings() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill").font(.system(size: 13))
                        Text(lang.s(L.settings))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.pathriftTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.pathriftSurface)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: { appState.showStore() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "diamond.fill").font(.system(size: 13))
                        Text(lang.s(L.store))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.pathriftNeonBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.pathriftNeonBlue.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.pathriftNeonBlue.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: { appState.showArsenal() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill").font(.system(size: 13))
                        Text("ARSENAL")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.pathriftOrange)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.pathriftOrange.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.pathriftOrange.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            towerLegend
        }
    }

    private var towerLegend: some View {
        HStack(spacing: 0) {
            ForEach(TowerType.allCases) { type in
                VStack(spacing: 4) {
                    Circle()
                        .fill(type.swiftUIColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: type.swiftUIColor.opacity(0.6), radius: 4)
                    Text(type.displayName)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.pathriftTextSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.pathriftSurface.opacity(0.7))
        .cornerRadius(12)
    }

    private var bottomInfo: some View {
        Text("Harita değişiyor • Strateji sürekli evriliyor")
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.pathriftTextSecondary.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.bottom, 12)
    }
}
