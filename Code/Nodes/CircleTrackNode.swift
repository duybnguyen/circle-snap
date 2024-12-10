//
//  CircleTrackNode.swift
//  circle_snap
//
//  Created by Duy Nguyen on 12/7/24.
//

import SpriteKit


class CircleTrackNode: SKShapeNode {
    // Custom initializer
    init(radius: CGFloat, lineWidth: CGFloat, color: SKColor) {
        super.init()

        // Define the circular path
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
        self.path = path

        // Configure the stroke
        self.strokeColor = color.withAlphaComponent(0.8)
        self.lineWidth = lineWidth
        
        let circleTrackCloud = SKSpriteNode(imageNamed: "circleTrackCloud")
        circleTrackCloud.position = CGPoint(x: frame.midX, y: frame.midY - GameConstants.circleTrackRadius - 35)
        circleTrackCloud.zPosition = 10
        self.addChild(circleTrackCloud)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
