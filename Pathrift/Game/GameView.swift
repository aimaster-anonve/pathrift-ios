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
                        viewModel.beginMoveMode(towerId: info.slotId, moveCost: cost)
                    },
                    onDismiss: {
                        viewModel.selectedTowerSlotId = nil
                        viewModel.selectedTowerInfo = nil
                        viewModel.scene.hideRangeRing()
                    }
                )
            }

            // Drag-and-drop placement overlay (Build 9 — ghost center, OK/Cancel below ghost)
            if viewModel.isDraggingTower {
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            // Only for new placement (not move) — start ghost at screen center
                            if !viewModel.isMovingTower && viewModel.dragPosition == .zero {
                                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                                viewModel.dragPosition = center
                                viewModel.updateDragFromScreen(center, sceneSize: geo.size)
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                    viewModel.updateDragFromScreen(value.location, sceneSize: geo.size)
                                }
                                .onEnded { _ in
                                    // Don't auto-place on release — user must tap confirm button
                                }
                        )

                    // Ghost icon follows the finger
                    let ghostType: TowerType? = viewModel.dragTowerType
                        ?? viewModel.scene.activeTowers.first(where: { $0.slotId == viewModel.movingFromSlotId })?.type

                    if let dragType = ghostType {
                        TowerDragGhost(type: dragType, isValid: viewModel.isDragPositionValid)
                            .position(viewModel.dragPosition)
                            .allowsHitTesting(false)
                    }

                    // Cancel (sol) + OK/Confirm (sağ) — ghost'un hemen altında, yan yana
                    HStack(spacing: 20) {
                        // Cancel — her zaman görünür
                        Button(action: { viewModel.cancelDrag() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.pathriftDanger.opacity(0.20))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.pathriftDanger)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // OK — sadece geçerli konumda aktif
                        if viewModel.isDragPositionValid {
                            Button(action: { viewModel.confirmPlacement() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.pathriftSuccess.opacity(0.25))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.pathriftSuccess)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(duration: 0.2), value: viewModel.isDragPositionValid)
                        } else {
                            // Disabled OK placeholder — aynı boyut, soluk
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white.opacity(0.2))
                            }
                        }
                    }
                    .position(
                        x: viewModel.dragPosition.x,
                        y: min(geo.size.height - 60, viewModel.dragPosition.y + 58)
                    )
                }
                .ignoresSafeArea()
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
            // Build 8: no slot tap handler — free-form placement via counter pill "+" (DEC-032)
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

// MARK: - Tower Drag Ghost (Build 8 — DEC-032)

struct TowerDragGhost: View {
    let type: TowerType
    var isValid: Bool = false

    var body: some View {
        ZStack {
            // Glow halkası — haritadaki tower ile aynı boyut
            Circle()
                .fill((isValid ? Color.pathriftSuccess : Color.pathriftDanger).opacity(0.18))
                .frame(width: 72, height: 72)
                .blur(radius: 8)
            // Tower shape — haritadaki boyutla aynı (52pt)
            TowerShapeView(type: type, size: 52)
                .shadow(color: type.swiftUIColor.opacity(0.7), radius: 8)
        }
        .animation(.easeInOut(duration: 0.15), value: isValid)
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
