import SwiftUI

struct CombatHUDView: View {
    @ObservedObject var viewModel: GameViewModel
    let onStartWave: () -> Void
    let onPause: () -> Void
    @State private var waveButtonPulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom

            VStack(spacing: 0) {
                topBar(safeTop: safeTop)
                if let msg = viewModel.waveCompleteMessage {
                    EventBannerView(message: msg, color: .pathriftSuccess)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
                bottomBar(safeBottom: safeBottom)
            }
            .animation(.spring(response: 0.3), value: viewModel.waveCompleteMessage)
        }
    }

    private func topBar(safeTop: CGFloat) -> some View {
        HStack(spacing: 0) {
            goldIndicator
            Spacer()
            waveIndicator
            Spacer()
            HStack(spacing: 12) {
                livesIndicator
                pauseButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, safeTop + 8)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [Color.pathriftBackground.opacity(0.95), Color.pathriftBackground.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var pauseButton: some View {
        Button(action: onPause) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.pathriftTextSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var goldIndicator: some View {
        HUDStatView(
            icon: "dollarsign.circle.fill",
            value: "\(viewModel.gold)",
            label: "GOLD",
            color: .pathriftGold
        )
    }

    private var waveIndicator: some View {
        VStack(spacing: 2) {
            Text(viewModel.currentWave == 0 ? "READY" : "WAVE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(2)
            Text(viewModel.currentWave == 0 ? "--" : "\(viewModel.currentWave)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.pathriftNeonBlue)
                .monospacedDigit()
        }
    }

    private var livesIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<EconomyConstants.startingLives, id: \.self) { idx in
                Image(systemName: idx < viewModel.lives ? "heart.fill" : "heart")
                    .foregroundColor(idx < viewModel.lives ? .pathriftDanger : .pathriftTextSecondary.opacity(0.4))
                    .font(.system(size: 16))
            }
        }
    }

    private func bottomBar(safeBottom: CGFloat) -> some View {
        HStack(spacing: 12) {
            killsCounter
            Spacer()
            if !viewModel.isWaveActive && !viewModel.isGameOver {
                waveStartButton
            } else if viewModel.isWaveActive {
                waveActiveIndicator
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, max(safeBottom + 8, 24))
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [Color.pathriftBackground.opacity(0), Color.pathriftBackground.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var killsCounter: some View {
        HUDStatView(
            icon: "xmark.circle.fill",
            value: "\(viewModel.enemyKills)",
            label: "KILLS",
            color: .pathriftDanger
        )
    }

    private var waveStartButton: some View {
        Button(action: {
            onStartWave()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("SEND WAVE")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .kerning(0.5)
            }
            .foregroundColor(.pathriftBackground)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.pathriftNeonBlue)
            .cornerRadius(12)
            .shadow(color: .pathriftNeonBlue.opacity(waveButtonPulse ? 0.8 : 0.3), radius: waveButtonPulse ? 12 : 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                waveButtonPulse = true
            }
        }
    }

    private var waveActiveIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.7)
                .tint(.pathriftNeonBlue)
            Text("WAVE IN PROGRESS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.pathriftTextSecondary)
                .kerning(1)
        }
    }
}

struct HUDStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.pathriftTextPrimary)
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.pathriftTextSecondary)
                    .kerning(1.5)
            }
        }
    }
}
