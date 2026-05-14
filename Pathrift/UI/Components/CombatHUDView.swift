import SwiftUI

struct CombatHUDView: View {
    @ObservedObject var viewModel: GameViewModel
    let onStartWave: () -> Void
    let onPause: () -> Void

    private var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLandscape {
                landscapeTopBar
            } else {
                portraitTopBar
            }
            if let msg = viewModel.waveCompleteMessage {
                EventBannerView(message: msg, color: .pathriftSuccess)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
            bottomBar
        }
        .animation(.spring(response: 0.3), value: viewModel.waveCompleteMessage)
    }

    // MARK: - Wave Progress Strip (4pt bar below top HUD)

    private var waveProgressStrip: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 4)

                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.pathriftNeonBlue, .pathriftPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(viewModel.waveProgress), height: 4)
                    .animation(.linear(duration: 0.3), value: viewModel.waveProgress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 8)
    }

    // MARK: - Landscape Top Bar (three-section: wave | stats | speed+pause)

    private var landscapeTopBar: some View {
        HStack(spacing: 0) {
            // LEFT: Wave number
            Text("W\(viewModel.currentWave == 0 ? "--" : "\(viewModel.currentWave)")")
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundColor(.pathriftNeonBlue)
                .frame(width: 60, alignment: .leading)
                .padding(.leading, 16)

            Spacer()

            // CENTER: Lives + Gold + Diamond (clustered with pill backgrounds)
            HStack(spacing: 10) {
                // Lives hearts pill
                HStack(spacing: 2) {
                    ForEach(0..<max(0, viewModel.lives), id: \.self) { _ in
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.pathriftDanger)
                    }
                    ForEach(viewModel.lives..<EconomyConstants.startingLives, id: \.self) { _ in
                        Image(systemName: "heart")
                            .font(.system(size: 11))
                            .foregroundColor(.pathriftTextSecondary.opacity(0.3))
                    }
                }
                .statPill()

                // Gold pill
                HStack(spacing: 3) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.pathriftGold)
                    Text("\(viewModel.gold)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }
                .statPill()

                // Diamond pill
                HStack(spacing: 3) {
                    Text("♦")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 0.78, blue: 1))
                    Text("\(viewModel.diamonds)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0, green: 0.78, blue: 1))
                }
                .statPill()

                // Kills pill
                HStack(spacing: 3) {
                    Image(systemName: "xmark.shield.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.pathriftOrange)
                    Text("\(viewModel.enemyKills)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftOrange)
                }
                .statPill()
            }

            Spacer()

            // RIGHT: Speed + Pause
            HStack(spacing: 6) {
                speedBtn
                pauseBtn
            }
            .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(
            ZStack {
                Color.pathriftBackground.opacity(0.6)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
            }
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Portrait Top Bar (original)

    private var portraitTopBar: some View {
        HStack(spacing: 0) {
            goldStat
            Spacer()
            waveStat
            Spacer()
            HStack(spacing: 10) {
                diamondStat
                livesStat
                speedBtn
                pauseBtn
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.pathriftBackground.opacity(0.9), .clear],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private var goldStat: some View {
        HStack(spacing: 5) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.pathriftGold)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(viewModel.gold)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.pathriftTextPrimary)
                    .monospacedDigit()
                Text("GOLD").font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary).kerning(1.5)
            }
        }
    }

    private var waveStat: some View {
        VStack(spacing: 2) {
            Text(viewModel.currentWave == 0 ? "READY" : "WAVE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary).kerning(2)
            Text(viewModel.currentWave == 0 ? "--" : "\(viewModel.currentWave)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.pathriftNeonBlue).monospacedDigit()
        }
    }

    private var diamondStat: some View {
        HStack(spacing: 3) {
            Text("♦")
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                .font(.system(size: 14, weight: .bold))
            Text("\(viewModel.diamonds)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                .monospacedDigit()
        }
    }

    private var livesStat: some View {
        HStack(spacing: 3) {
            ForEach(0..<EconomyConstants.startingLives, id: \.self) { idx in
                Image(systemName: idx < viewModel.lives ? "heart.fill" : "heart")
                    .foregroundColor(idx < viewModel.lives ? .pathriftDanger : .pathriftTextSecondary.opacity(0.3))
                    .font(.system(size: 16))
                    .scaleEffect(idx < viewModel.lives ? 1.0 : 0.8)
            }
        }
    }

    // MARK: - Speed Button (polished pill with active glow)

    private var speedBtn: some View {
        Button(action: { viewModel.toggleSpeed() }) {
            HStack(spacing: 3) {
                Image(systemName: "speedometer")
                    .font(.system(size: 9))
                Text(viewModel.speedMultiplier == 1.0 ? "×1" : "×2")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .foregroundColor(viewModel.speedMultiplier == 2.0 ? .pathriftNeonBlue : .pathriftTextSecondary)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(
                viewModel.speedMultiplier == 2.0
                    ? Color.pathriftNeonBlue.opacity(0.2)
                    : Color.white.opacity(0.07)
            )
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(
                viewModel.speedMultiplier == 2.0
                    ? Color.pathriftNeonBlue.opacity(0.5)
                    : Color.white.opacity(0.1),
                lineWidth: 1
            ))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Pause Button

    private var pauseBtn: some View {
        Button(action: onPause) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.75))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if !isLandscape {
                killsStat.padding(.leading, 16)
            }

            Spacer()

            Group {
                if viewModel.isWaveActive {
                    waveProgressIndicator
                } else if !viewModel.isGameOver {
                    sendWaveButton
                }
            }
            .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(
            LinearGradient(
                colors: [.clear, Color.pathriftBackground.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var killsStat: some View {
        HStack(spacing: 5) {
            Image(systemName: "bolt.fill")
                .foregroundColor(.pathriftOrange)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(viewModel.enemyKills)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.pathriftTextPrimary).monospacedDigit()
                Text("KILLS").font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary).kerning(1.5)
            }
        }
    }

    // MARK: - Send Wave Button (gradient + shadow polish)

    private var sendWaveButton: some View {
        Button(action: onStartWave) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.right.2")
                    .font(.system(size: 11, weight: .bold))
                Text(viewModel.currentWave == 0 ? "START" : "NEXT WAVE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .kerning(0.5)
            }
            .foregroundColor(Color.pathriftBackground)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(
                LinearGradient(
                    colors: [.pathriftNeonBlue, .pathriftPurple],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: .pathriftNeonBlue.opacity(0.3), radius: 6, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Wave Progress Indicator (polished capsule with fraction)

    private var waveProgressIndicator: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.waveEnemiesCleared)/\(viewModel.waveEnemyTotal)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.pathriftNeonBlue, .pathriftPurple],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * CGFloat(viewModel.waveProgress), height: 5)
                        .animation(.linear(duration: 0.2), value: viewModel.waveProgress)
                }
            }
            .frame(width: 100, height: 5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
    }
}

struct HUDStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.pathriftTextPrimary).monospacedDigit()
                Text(label).font(.system(size: 8, weight: .semibold, design: .monospaced)).foregroundColor(.pathriftTextSecondary).kerning(1.5)
            }
        }
    }
}
