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
    @State private var showNextWaveInfo: Bool = false

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
                },
                onShowNextWaveInfo: {
                    showNextWaveInfo = true
                }
            )

            // Tower menüsü — shown via slot tap or counter pill "+"
            if showTowerMenu || viewModel.isShowingTowerMenu, let slotId = selectedSlotId {
                TowerMenuView(
                    slotId: slotId,
                    goldAvailable: viewModel.gold,
                    diamonds: viewModel.diamonds,
                    onSelect: { towerType in
                        // Use drag mode instead of direct placement
                        viewModel.startDragPlacement(type: towerType)
                        showTowerMenu = false
                        viewModel.isShowingTowerMenu = false
                        selectedSlotId = nil
                    },
                    onUnlockTower: { towerType in
                        viewModel.unlockTower(towerType)
                    },
                    onDismiss: {
                        showTowerMenu = false
                        viewModel.isShowingTowerMenu = false
                        selectedSlotId = nil
                    }
                )
            } else if viewModel.isShowingTowerMenu && selectedSlotId == nil {
                // Opened from tower counter pill — no pre-selected slot
                TowerMenuView(
                    slotId: -1,
                    goldAvailable: viewModel.gold,
                    diamonds: viewModel.diamonds,
                    onSelect: { towerType in
                        viewModel.startDragPlacement(type: towerType)
                        viewModel.isShowingTowerMenu = false
                    },
                    onUnlockTower: { towerType in
                        viewModel.unlockTower(towerType)
                    },
                    onDismiss: {
                        viewModel.isShowingTowerMenu = false
                    }
                )
            }

            // Tower info panel (upgrade/sell/move)
            if let info = viewModel.selectedTowerInfo {
                TowerInfoPanel(
                    info: info,
                    gold: viewModel.gold,
                    isWaveActive: viewModel.isWaveActive,
                    onUpgrade: {
                        viewModel.upgradeSelectedTower()
                    },
                    onSell: {
                        viewModel.sellSelectedTower()
                    },
                    onMove: {
                        let cost = Int(ceil(Double(info.totalInvested) * EconomyConstants.MoveCost.percent))
                        viewModel.beginMoveMode(slotId: info.slotId, moveCostValue: cost)
                    },
                    onDismiss: {
                        viewModel.selectedTowerSlotId = nil
                        viewModel.selectedTowerInfo = nil
                        viewModel.scene.hideRangeRing()
                    }
                )
            }

            // Drag-and-drop placement overlay (Build 7 — DEC-030)
            if viewModel.isDraggingTower {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                viewModel.dragPosition = value.location
                                let scenePoint = sceneCoordinate(from: value.location)
                                viewModel.updateDrag(scenePoint: scenePoint)
                            }
                            .onEnded { value in
                                let scenePoint = sceneCoordinate(from: value.location)
                                viewModel.dropTower(scenePoint: scenePoint)
                            }
                    )

                // Ghost icon follows the finger
                if let dragType = viewModel.dragTowerType {
                    TowerDragGhost(type: dragType)
                        .position(viewModel.dragPosition)
                        .allowsHitTesting(false)
                } else if viewModel.isMovingTower {
                    // Moving tower — ghost uses the type of the tower being moved
                    let movingTowerType = viewModel.scene.activeTowers
                        .first(where: { $0.slotId == viewModel.movingFromSlotId })?.type
                    if let t = movingTowerType {
                        TowerDragGhost(type: t)
                            .position(viewModel.dragPosition)
                            .allowsHitTesting(false)
                    }
                }
            }

            // Next wave info panel overlay
            NextWaveInfoPanel(
                waveDef: viewModel.nextWaveDefinition,
                isVisible: $showNextWaveInfo
            )

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
        .onChange(of: viewModel.isShowingTowerMenu) { _, showing in
            // When opened from counter pill, ensure a dummy slot is used
            if showing && selectedSlotId == nil {
                // No slot selected — menu will dismiss after type selection and start drag
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

// MARK: - Drag Coordinate Helper

extension GameView {
    /// Convert a SwiftUI local coordinate to SpriteKit scene coordinate.
    /// SpriteKit uses anchorPoint = .zero with Y flipped relative to UIKit.
    func sceneCoordinate(from point: CGPoint) -> CGPoint {
        let sceneHeight = viewModel.scene.size.height
        return CGPoint(x: point.x, y: sceneHeight - point.y)
    }
}

// MARK: - Tower Drag Ghost

struct TowerDragGhost: View {
    let type: TowerType

    var body: some View {
        TowerShapeView(type: type, size: 44)
            .opacity(0.70)
            .shadow(color: type.swiftUIColor.opacity(0.55), radius: 12, y: 4)
            .scaleEffect(1.25)
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
