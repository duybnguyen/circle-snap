//
//  PowerUpNodeView.swift
//  circle_snap
//
//  Created by Duy Nguyen on 12/4/24.
//

import SwiftUI

struct PowerUpNodeView: View {
    let angle: Double
    let scale: CGFloat
    let offset: CGFloat
    
    var body: some View {
        Circle()
            .fill(.yellow)
            .scaleEffect(scale)
            .frame(width: GameConstants.nodeRadius * 2, height: GameConstants.nodeRadius * 2)
            .offset(
                x: GameConstants.circleRadius * cos(angle * .pi / 180) + offset,
                y: GameConstants.circleRadius * sin(angle * .pi / 180)
            )
    }
}
