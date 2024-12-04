//
//  GameState.swift
//  circle_snap
//
//  Created by Duy Nguyen on 11/4/24.
//

import SwiftUI
import Combine

struct GameState {
    var progress: Double = 0.0
    var randomNodeAngle: Double = Double.random(in: 0..<360)
    var scale: CGFloat = 1.0
    var shakeOffset: CGFloat = 0
    var isGlowing: Bool = false
    var lastClickProgress: Double = 0.0
    
    
    // score system
    var score: Int = 0
    
    var gameTimer: Int = 5
    var timer: AnyCancellable?
    
    // modifiers
    var animationSpeed: Double = 3.5
    
    var currentCondition: ConditionType = .none
    var conditionPatchStartAngle: Double = 0
    var isInConditionPatch: Bool = false
    
    var isBarVisible: Bool = true
    

}

enum ConditionType {
    case none
    case sand
    case ice
    case wind
    case fog
}

    
enum GameStatus {
    case gameOver, inProgress, notStarted
}
