import SwiftUI

struct ConditionView: View {
    let weather: ConditionType
    let startAngle: Double
    let size: Double = GameConstants.conditionPatchSize
    let trackWidth: Double = 45
    
    var body: some View {
        ZStack {
            // Weather zone background
            Arc(
                startAngle: startAngle,
                size: size,
                radius: GameConstants.circleRadius
            )
            .stroke(weatherColor.opacity(0.8), lineWidth: trackWidth)
        }
    }
    
    private var weatherColor: Color {
        switch weather {
        case .wind:
            return .white
        case .mud:
            return .brown
        case .ice:
            return .cyan
        case .fog:
            return .gray
        case .none:
            return .clear
        }
    }
}

// Modified Arc shape to accept radius parameter
struct Arc: Shape {
    let startAngle: Double
    let size: Double
    let radius: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = startAngle * .pi / 180
        let end = (startAngle + size) * .pi / 180
        
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(start),
            endAngle: .radians(end),
            clockwise: false
        )
        return path
    }
}


