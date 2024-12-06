//
//  GameConstants.swift
//  circle_snap
//
//  Created by Duy Nguyen on 11/4/24.
//

import SwiftUI

struct GameConstants {
    static let circleRadius: CGFloat = 155.0
    static let nodeRadius: CGFloat = 22
    static let timerInterval: TimeInterval = 0.0001
    static let shakeDuration: Double = 0.05
    static let scaleAnimationDuration: Double = 0.2
    
    static let speedUpModifier: Double = 0.10
    
    static let conditionEventDuration: TimeInterval = 15.0
    static let conditionPatchSize: Double = 80.0
    
    
    static let windSpeedMultiplier: Double = 1.5
    static let sandSpeedMultiplier: Double = 0.5
    
    static let iceMinAdjustment = 0.3
    static let iceMaxAdjustment = 1.4
    
    static let conditions: [ConditionType] = [.mud, .ice, .wind, .fog]
}
    


