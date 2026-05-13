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
            // Game scene — tüm ekranı kaplar (safe area dahil)
            SpriteView(scene: viewModel.scene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // HUD — safe area içinde otomatik kalır
            CombatHUDView(
                viewModel: viewModel,
                onStartWave: { viewModel.startNextWave() },
                onPause: {
                    isPaused = true
                    viewModel.scene.isPaused = true
                }
            )

            // Tower menüsü
            if showTowerMenu, let slotId = selectedSlotId {
                TowerMenuView(
                    slotId: slotId,
                    goldAvailable: viewModel.gold,
                    diamonds: viewModel.diamonds,
                    onSelect: { towerType in
                        viewModel.placeTower(type: towerType, at: slotId)
                        showTowerMenu = false
                        selectedSlotId = nil
                    },
                    onUnlockTower: { towerType in
                        viewModel.unlockTower(towerType)
                    },
                    onDismiss: {
                        showTowerMenu = false
                        selectedSlotId = nil
                    }
                )
            }

            // Tower info panel (upgrade/sell)
            if let info = viewModel.selectedTowerInfo {
                TowerInfoPanel(
                    info: info,
                    gold: viewModel.gold,
                    onUpgrade: {
                        viewModel.upgradeSelectedTower()
                    },
                    onSell: {
                        viewModel.sellSelectedTower()
                    },
                    onDismiss: {
                        viewModel.selectedTowerSlotId = nil
                        viewModel.selectedTowerInfo = nil
                        viewModel.scene.hideRangeRing()
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
                        isPaused = false
                        appState.goHome()
                    }
                )
            }
        }
        // NO .ignoresSafeArea() on ZStack
        .onAppear {
            viewModel.configure(appState: appState)
            viewModel.scene.onSlotTapped = { [weak viewModel] slotId in
                guard let vm = viewModel, !isPaused else { return }
                if let slot = vm.scene.gridSystem.slot(at: slotId),
                   !slot.state.isOccupied {
                    selectedSlotId = slotId
                    showTowerMenu = true
                }
            }
        }
        .onChange(of: viewModel.isGameOver) { _, isOver in
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
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("⏸")
                        .font(.system(size: 40))
                    Text("PAUSED")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.pathriftNeonBlue)
                        .shadow(color: .pathriftNeonBlue.opacity(0.5), radius: 10)
                }

                VStack(spacing: 14) {
                    Button(action: onResume) {
                        Label("RESUME", systemImage: "play.fill")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.pathriftBackground)
                            .frame(width: 220, height: 52)
                            .background(Color.pathriftNeonBlue)
                            .cornerRadius(14)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: onQuit) {
                        Label("QUIT RUN", systemImage: "xmark")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.pathriftDanger)
                            .frame(width: 220, height: 52)
                            .background(Color.pathriftSurface)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.pathriftDanger.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
}
