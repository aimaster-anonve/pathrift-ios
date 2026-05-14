import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject var appState: AppState
    let restoreFromSave: Bool
    @StateObject private var viewModel: GameViewModel

    init(restoreFromSave: Bool = false) {
        self.restoreFromSave = restoreFromSave
        _viewModel = StateObject(wrappedValue: GameViewModel(restoreFromSave: restoreFromSave))
    }
    @State private var selectedSlotId: Int? = nil
    @State private var showTowerMenu: Bool = false
    @State private var isPaused: Bool = false

    var body: some View {
        ZStack {
            // Background fills full screen including behind Dynamic Island
            Color.pathriftBackground.ignoresSafeArea()

            // Game scene — fills full screen including Dynamic Island area
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
                        GameSaveStore.shared.clear()
                        appState.goHome()
                    }
                )
            }

            // Revive overlay
            if viewModel.showRevivePrompt {
                ZStack {
                    Color.black.opacity(0.75).ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("💀 GAME OVER")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.pathriftDanger)
                        Text("REVIVE? (\(viewModel.reviveCountdown)s)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("You have 1 revive available (Premium)")
                            .font(.system(size: 12))
                            .foregroundColor(.pathriftTextSecondary)
                        HStack(spacing: 16) {
                            Button("REVIVE") { viewModel.acceptRevive() }
                                .font(.system(size: 16, weight: .black))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            Button("Give Up") { viewModel.declineRevive() }
                                .font(.system(size: 14))
                                .frame(width: 100, height: 52)
                                .background(Color.pathriftSurface)
                                .foregroundColor(.pathriftDanger)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.pathriftDanger.opacity(0.4), lineWidth: 1))
                        }
                    }
                    .padding(28)
                    .background(Color.pathriftSurface)
                    .cornerRadius(24)
                    .padding(24)
                }
                .transition(.opacity)
                .zIndex(50)
            }
        }
        // Status bar + Dynamic Island hidden → full immersive game screen
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // Scene fills full screen; layout keeps content clear of HUD overlay
            viewModel.scene.hudTopInset = 56   // HUD bar + safe area clearance
            viewModel.scene.hudBottomInset = 48  // bottom bar clearance
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
        .sheet(isPresented: $viewModel.showPremiumPrompt) {
            VStack(spacing: 16) {
                Text("⚡ PREMIUM FEATURE")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.pathriftNeonBlue)
                Text("×2 Speed requires Premium membership.")
                    .font(.system(size: 13))
                    .foregroundColor(.pathriftTextSecondary)
                    .multilineTextAlignment(.center)
                Button("Get Premium") {
                    viewModel.showPremiumPrompt = false
                    appState.showStore()
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.pathriftNeonBlue)
                .foregroundColor(.pathriftBackground)
                .cornerRadius(10)
                Button("Not Now") { viewModel.showPremiumPrompt = false }
                    .font(.system(size: 12))
                    .foregroundColor(.pathriftTextSecondary)
            }
            .padding(24)
            .background(Color.pathriftSurface)
            .cornerRadius(20)
            .padding(32)
            .presentationDetents([.height(280)])
            .presentationBackground(Color.pathriftBackground)
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
