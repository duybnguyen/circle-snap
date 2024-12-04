//
//  GameOverView.swift
//  circle_snap
//
//  Created by Duy Nguyen on 11/5/24.
//
import SwiftUI

struct GameOverView: View {
    @ObservedObject var viewModel: CSViewModel

    var body: some View {
        Text("Game Over")
            .font(.largeTitle)
            .foregroundColor(.red)
        // reset all game state variables
        Button("Play Again") {
            viewModel.gameStatus = .inProgress
            viewModel.gameState.score = 0
            viewModel.gameState.animationSpeed = 4
            viewModel.gameState.randomNodeAngle = Double.random(in: 0..<360)
            viewModel.gameState.progress = Double.random(in: 0..<1)
        }
    }
}
