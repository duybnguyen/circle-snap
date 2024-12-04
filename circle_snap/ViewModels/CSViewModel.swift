import SwiftUI
import Combine

// ViewModel to manage the game's state and logic, including the timer and game actions.
class CSViewModel: ObservableObject {
    @Published var gameState = GameState() // Observable game state object to manage UI updates
    @Published var gameStatus: GameStatus = .notStarted
    private var lastCycleProgress : Double = 0
    private var isReverse : Bool = false
    private var didTap : Bool = false
    private var rotationTimer: AnyCancellable?
    private var countdownTimer: AnyCancellable?
    private let angleTolerance: Double // Tolerance for alignment detection
    private var displayLink: CADisplayLink? // CADisplayLink for syncing with screen refresh rate
    private var startTime: CFTimeInterval? // Track the start time of the animation
    
    private var weatherTimer: AnyCancellable?
        
    
    // Debug properties to visualize the start and end angles for the active zone
    var debugStartAngle: Double { normalizeAngle(gameState.randomNodeAngle - angleTolerance) }
    var debugEndAngle: Double { normalizeAngle(gameState.randomNodeAngle + angleTolerance) }
    
    // Initializes the ViewModel and calculates angle tolerance for determining successful taps.
    init() {
        self.angleTolerance = Self.calculateAngleTolerance()
    }
    
    func onAppear() {
        gameState.randomNodeAngle = Double.random(in: 0..<360)
        gameState.progress = Double.random(in: 0..<1)
        startRotation()
        startConditionCycle()
    }
    
    
    
    // Calculates the tolerance angle based on the radius of the node and circle.
    private static func calculateAngleTolerance() -> Double {
        return ((Double(GameConstants.nodeRadius) / Double(GameConstants.circleRadius)) * 180 / .pi) * 1.75
    }
    
    
    // Starts the rotation animation timer, updating progress based on elapsed time.
    private func startRotation() {
        startTime = CACurrentMediaTime() // Track the start time when rotation begins
        displayLink = CADisplayLink(target: self, selector: #selector(updateRotation))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    // Helper: Calculate the smallest difference between two points on a circular scale
    // transitioning from 0.99 to 0.01 should result in 0.02, not -0.98.
    func circularDifference(current: Double, last: Double) -> Double {
        let diff = (current - last).truncatingRemainder(dividingBy: 1.0)
        return diff < -0.5 ? diff + 1.0 : (diff > 0.5 ? diff - 1.0 : diff)
    }
    
    private func calculateProbability(probability: Double) -> Bool {
        return Double.random(in: 0.0...1.0) < probability
    }
    
    // Called by CADisplayLink to update the game state on each frame.
    @objc private func updateRotation() {
        guard let startTime = startTime else { return }
        let elapsedTime = CACurrentMediaTime() - startTime
        let cycleProgress = elapsedTime.truncatingRemainder(dividingBy: gameState.animationSpeed) / gameState.animationSpeed
        
        // Calculate current angle
        let currentAngle = normalizeAngle(gameState.progress * 360)
        
        // Check if in weather patch
        let weatherStartAngle = gameState.conditionPatchStartAngle
        let weatherEndAngle = normalizeAngle(weatherStartAngle + GameConstants.conditionPatchSize)
        gameState.isInConditionPatch = isAngleInRange(currentAngle, start: weatherStartAngle, end: weatherEndAngle)
        
        // Calculate base progress change
        //var progressChange = abs(cycleProgress - lastCycleProgress)
        var progressChange = circularDifference(current: cycleProgress, last: lastCycleProgress)

        lastCycleProgress = cycleProgress
        if gameState.isInConditionPatch {
            switch gameState.currentCondition {
            case .wind:
                progressChange *= GameConstants.windSpeedMultiplier
            case .sand:
                progressChange *= GameConstants.sandSpeedMultiplier
            case .ice:
                let isPositiveProgress = calculateProbability(probability: 0.8)
                let adjustment = Double.random(in: GameConstants.iceMinAdjustment...GameConstants.iceMaxAdjustment)
                let randomAdjustment = isPositiveProgress ? adjustment : -adjustment
                progressChange *= randomAdjustment
            case .fog:
                gameState.isBarVisible = false
            case .none:
                break
            }
        } else {
            gameState.isBarVisible = true
        }

        if progressChange < 0 {
            progressChange += 1.0
        } else if progressChange >= 1.0 {
            progressChange -= 1.0
        }
        
        var progress = gameState.progress
        if isReverse {
            progress -= progressChange
        } else {
            progress += progressChange
        }
        progress = progress.truncatingRemainder(dividingBy: 1.0)
        if progress < 0 {
            progress += 1.0
        }
        gameState.progress = progress
        
        // Determine if the bar is in range (glowing)
        let wasInRange = gameState.isGlowing
        gameState.isGlowing = isRectangleInRange()
        
        // If the bar passes through the node (was glowing but is no longer in range), handle the failure
        if wasInRange && !gameState.isGlowing {
            if gameState.score > 0 && !didTap {
                handleFailedTap()
            }
            didTap = false
        }
    }

    
    // Checks if the rotating rectangle is within the success range of the node's angle.
    private func isRectangleInRange() -> Bool {
        let normalizedProgress = normalizeAngle(gameState.progress * 360)
        let startAngle = debugStartAngle
        let endAngle = debugEndAngle
        
        // Determines if the progress angle falls within the specified tolerance range
        return startAngle < endAngle
        ? normalizedProgress >= startAngle && normalizedProgress <= endAngle
        : normalizedProgress >= startAngle || normalizedProgress <= endAngle
    }
    
    
    // calls success or failure handlers based on alignment.
    func handleTap() {
        didTap = true;
        if isRectangleInRange() {
            handleSuccessfulTap()
        } else {
            handleFailedTap()
        }
    }
    
    
    // Handles a successful tap, triggering animations and updating the node position.
    private func handleSuccessfulTap() {
        speedUpOnSuccessfulTap()
        gameState.lastClickProgress = gameState.progress
        isReverse = !isReverse
        gameState.score += 1
        
        // Animations
        withAnimation(.easeIn(duration: GameConstants.scaleAnimationDuration)) {
            gameState.scale = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.scaleAnimationDuration) {
            var newAngle: Double
            let exclusionRange = 360.0 / 4
            let lastAngle = self.gameState.randomNodeAngle
            repeat {
                newAngle = Double.random(in: 0..<360)
            } while abs(newAngle - lastAngle) < exclusionRange || abs(newAngle - lastAngle) > 360 - exclusionRange
            self.gameState.randomNodeAngle = newAngle

            withAnimation(.easeOut(duration: GameConstants.scaleAnimationDuration)) {
                self.gameState.scale = 1.0
            }
        }
    }
    
    // Handles a failed tap, triggering a shaking animation to indicate incorrect alignment.
    private func handleFailedTap() {
        gameStatus = .gameOver
        withAnimation(Animation.easeInOut(duration: GameConstants.shakeDuration).repeatCount(3, autoreverses: true)) {
            gameState.scale = 0.95
            gameState.shakeOffset = 10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                self.gameState.scale = 1.0
                self.gameState.shakeOffset = 0
            }
        }
    }
        
        
    // Normalizes an angle to fall within the 0-360° range.
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        return normalized
    }

    private func speedUpOnSuccessfulTap() {
        if (gameState.animationSpeed > 2) {
            // current elapsed time based on the current progress and speed
            guard let startTime = startTime else { return }
            
            // calculate elapsed time with the current animation speed
            let elapsedTime = CACurrentMediaTime() - startTime
            let currentProgress = elapsedTime.truncatingRemainder(dividingBy: gameState.animationSpeed) / gameState.animationSpeed
            
            gameState.animationSpeed -= GameConstants.speedUpModifier
            
            // adjust startTime so the rotation progress stays the same
            let adjustedElapsedTime = currentProgress * gameState.animationSpeed
            self.startTime = CACurrentMediaTime() - adjustedElapsedTime
        }
        return
    }
    
    private func startConditionCycle() {
        // Initial weather setup
        updateCondition()
        
        // Create timer for weather changes
        weatherTimer = Timer.publish(every: GameConstants.conditionEventDuration, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCondition()
            }
    }
    
    private func updateCondition() {
        // Randomly choose between conditions
        gameState.currentCondition = GameConstants.conditions.randomElement()!   // Random starting position for condition patch
        gameState.conditionPatchStartAngle = Double.random(in: 0..<360)
    }
    
    private func isAngleInRange(_ angle: Double, start: Double, end: Double) -> Bool {
        if start <= end {
            return angle >= start && angle <= end
        } else {
            return angle >= start || angle <= end
        }
    }
    
    // Cancels the timer when the ViewModel is deinitialized.
    deinit {
        displayLink?.invalidate()
        countdownTimer?.cancel()
        weatherTimer?.cancel()
    }
}
