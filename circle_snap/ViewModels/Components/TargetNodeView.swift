//
//  TargetNodeView.swift
//  circle_snap
//
//  Created by Duy Nguyen on 11/4/24.
//
import SwiftUI

struct TargetNodeView: View {
    let angle: Double
    let scale: CGFloat
    let offset: CGFloat
    let isGlowing: Bool
    let onTap: () -> Void
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .scaleEffect(scale)
            .frame(width: GameConstants.nodeRadius * 2, height: GameConstants.nodeRadius * 2)
            .offset(
                x: GameConstants.circleRadius * cos(angle * .pi / 180) + offset,
                y: GameConstants.circleRadius * sin(angle * .pi / 180)
            )
            .shadow(
                color: isGlowing ? Color.red.opacity(0.8) : Color.clear,
                radius: 10,
                x: 0,
                y: 0
            )

    }
}
