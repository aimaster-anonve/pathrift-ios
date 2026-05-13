import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GameViewModel()
    @State private var selectedSlotId: Int? = nil
    @State private var showTowerMenu: Bool = false
    @State private var isPaused: Bool = false

    var body: some View {
        ZStack {
            // SpriteKit game - fills full screen
            GeometryReader { geo in
                SpriteView(scene: viewModel.scene, options: [.allowsTransparency])
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
            }

            // HUD overlay - respects safe area
            CombatHUDView(
                viewModel: viewModel,
                onStartWave: { viewModel.startNextWave() },
                onPause: {
                    isPaused = true
                    viewModel.scene.isPaused = true
                }
            )

            // Tower placement sheet
            if showTowerMenu, let slotId = selectedSlotId {
                TowerMenuView(
                    slotId: slotId,
                    goldAvailable: viewModel.gold,
                    onSelect: { towerType in
                        viewModel.placeTower(type: towerType, at: slotId)
                        showTowerMenu = false
                        selectedSlotId = nil
                    },
                    onDismiss: {
                        showTowerMenu = false
                        selectedSlotId = nil
                    }
                )
            }

            // Pause overlay
            if isPaused {
                PauseOverlay(
                    onResume: {
                        isPaused = false
                        viewModel.scene.isPaused = false
                    },
                    onQuit: {
                        viewModel.scene.isPaused = false
                        appState.goHome()
                    }
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.configure(appState: appState)
            viewModel.scene.onSlotTapped = { slotId in
                guard !isPaused else { return }
                if let slot = viewModel.scene.gridSystem.slot(at: slotId),
                   !slot.state.isOccupied {
                    selectedSlotId = slotId
                    showTowerMenu = true
                }
            }
        }
        .onChange(of: viewModel.isGameOver) { isOver in
            if isOver, let result = viewModel.runResult {
                LocalRunStorage.shared.saveRun(result: result)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    appState.endRun(result: result)
                }
            }
        }
    }
}

struct PauseOverlay: View {
    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.pathriftNeonBlue)
                    .shadow(color: .pathriftNeonBlue.opacity(0.6), radius: 12)

                VStack(spacing: 14) {
                    Button(action: onResume) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text("RESUME")
                                .kerning(1)
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.pathriftBackground)
                        .frame(width: 220, height: 52)
                        .background(Color.pathriftNeonBlue)
                        .cornerRadius(14)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: onQuit) {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.circle")
                            Text("QUIT RUN")
                                .kerning(1)
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.pathriftDanger)
                        .frame(width: 220, height: 52)
                        .background(Color.pathriftSurface)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.pathriftDanger.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(32)
        }
    }
}
