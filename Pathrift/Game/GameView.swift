import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GameViewModel()
    @State private var selectedSlotId: Int? = nil
    @State private var showTowerMenu: Bool = false

    var body: some View {
        ZStack {
            gameSceneView
            CombatHUDView(viewModel: viewModel, onStartWave: {
                viewModel.startNextWave()
            })
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
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.configure(appState: appState)
            viewModel.scene.onSlotTapped = { slotId in
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    appState.endRun(result: result)
                }
            }
        }
    }

    private var gameSceneView: some View {
        GeometryReader { geo in
            SpriteView(
                scene: viewModel.scene,
                options: [.allowsTransparency]
            )
            .frame(width: geo.size.width, height: geo.size.height)
            .ignoresSafeArea()
        }
    }
}
