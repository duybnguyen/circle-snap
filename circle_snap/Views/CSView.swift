//
//  CSView.swift
//  circle_snap
//
//  Created by Duy Nguyen on 11/4/24.
//
import SwiftUI

struct CSView: View {
    @ObservedObject var viewModel: CSViewModel
    
    var body: some View {
        ZStack {
            CircleTrackView()
            ComboView(score: viewModel.gameState.score)
            if viewModel.gameState.currentCondition != .none {
                ConditionView(
                    weather: viewModel.gameState.currentCondition,
                    startAngle: viewModel.gameState.conditionPatchStartAngle
                )
            }
            TargetNodeView(
                angle: viewModel.gameState.randomNodeAngle,
                scale: viewModel.gameState.nodeScale,
                offset: viewModel.gameState.nodeShakeOffset,
                isGlowing: viewModel.gameState.nodeIsGlowing,
                onTap: viewModel.handleTap
            )
            if viewModel.gameState.isPowerUpActive {
                PowerUpNodeView(
                    angle: viewModel.gameState.randomPowerUpNodeAngle,
                    scale: viewModel.gameState.powerUpScale,
                    offset: viewModel.gameState.powerUpShakeOffset)

            }
            MovingIndicatorView(progress: viewModel.gameState.progress, isBarVisible: viewModel.gameState.isBarVisible)
            
            // Uncomment for debugging
            //DebugOverlayView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
