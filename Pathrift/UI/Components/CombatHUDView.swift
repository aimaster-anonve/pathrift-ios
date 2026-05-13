import SwiftUI

struct CombatHUDView: View {
    @ObservedObject var viewModel: GameViewModel
    let onStartWave: () -> Void
    let onPause: () -> Void
    @State private var waveButtonPulse = false

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

            // CENTER: Lives + Gold + Diamond (clustered together)
            HStack(spacing: 12) {
                // Lives hearts
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

                // Gold
                HStack(spacing: 3) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.pathriftGold)
                    Text("\(viewModel.gold)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftGold)
                }

                // Diamond
                HStack(spacing: 3) {
                    Text("♦")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 0.78, blue: 1))
                    Text("\(viewModel.diamonds)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0, green: 0.78, blue: 1))
                }
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
            Color.pathriftBackground.opacity(0.88)
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

    private var speedBtn: some View {
        Button(action: { viewModel.toggleSpeed() }) {
            Text(viewModel.speedMultiplier == 1.0 ? "×1" : "×2")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(viewModel.speedMultiplier == 2.0 ? .pathriftNeonBlue : .pathriftTextSecondary)
                .frame(width: 36, height: 28)
                .background(Color.black.opacity(0.4))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(
                    viewModel.speedMultiplier == 2.0 ? Color.pathriftNeonBlue : Color.pathriftTextSecondary.opacity(0.3),
                    lineWidth: 1
                ))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var pauseBtn: some View {
        Button(action: onPause) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.pathriftTextSecondary.opacity(0.8))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // LEFT: kills stat (compact in landscape, full in portrait)
            if isLandscape {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.pathriftOrange)
                    Text("\(viewModel.enemyKills)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.pathriftOrange)
                }
                .padding(.leading, 16)
            } else {
                killsStat
                    .padding(.leading, 20)
            }

            Spacer()

            // RIGHT: Wave progress or send wave button
            Group {
                if !viewModel.isWaveActive && !viewModel.isGameOver {
                    sendWaveButton
                } else if viewModel.isWaveActive {
                    waveProgressIndicator
                }
            }
            .padding(.trailing, isLandscape ? 16 : 20)
        }
        .frame(height: 44)
        .background(
            LinearGradient(
                colors: [.clear, Color.pathriftBackground.opacity(0.88)],
                startPoint: .top, endPoint: .bottom
            )
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

    private var sendWaveButton: some View {
        Button(action: onStartWave) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill").font(.system(size: isLandscape ? 10 : 11, weight: .bold))
                Text("SEND WAVE").font(.system(size: isLandscape ? 12 : 13, weight: .bold, design: .rounded)).kerning(0.5)
            }
            .foregroundColor(.pathriftBackground)
            .padding(.horizontal, 22)
            .frame(height: isLandscape ? 40 : 48)
            .background(Color.pathriftNeonBlue)
            .cornerRadius(12)
            .shadow(color: .pathriftNeonBlue.opacity(waveButtonPulse ? 0.7 : 0.25), radius: waveButtonPulse ? 10 : 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { waveButtonPulse = true }
        }
    }

    private var waveProgressIndicator: some View {
        VStack(alignment: .trailing, spacing: 5) {
            HStack(spacing: 6) {
                Text("\(viewModel.waveEnemiesCleared)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.pathriftNeonBlue)
                    .monospacedDigit()
                Text("/")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.pathriftTextSecondary)
                Text("\(viewModel.waveEnemyTotal)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.pathriftTextSecondary)
                    .monospacedDigit()
                Text("CLEARED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary)
                    .kerning(1.5)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pathriftSurface)
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.pathriftNeonBlue, Color.pathriftPurple],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(8, geo.size.width * CGFloat(viewModel.waveProgress)),
                            height: 7
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.8),
                                   value: viewModel.waveProgress)
                }
            }
            .frame(width: isLandscape ? 120 : 140, height: 7)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.pathriftSurface.opacity(0.85))
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
