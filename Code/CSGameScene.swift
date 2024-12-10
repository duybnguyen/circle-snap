import SpriteKit

class CSGameScene: SKScene {
    var gameContext: CSGameContext
    private var conditionManager: GameConditionManager
    
    private var circleTrackNode: CircleTrackNode!
    private var movingIndicatorNode : MovingIndicatorNode!
    private var conditionNode : ConditionNode!
    private var targetNode: TargetNode!
    private var scoreNode: ScoreNode!
    private var startNode: StartNode!
    private var gameOverNode: GameOverNode!
    
    private var isReverse: Bool = false
    private var didTap: Bool = false
    
    private let angleTolerance: Double
    
    init(gameContext: CSGameContext = CSGameContext(),
         conditionManager: GameConditionManager = GameConditionManager()) {
        self.gameContext = gameContext
        self.conditionManager = conditionManager
        self.angleTolerance = Self.calculateAngleTolerance()
        self.gameContext.randomNodeAngle = Double.random(in: 0..<360)
        super.init(size: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        setupScene()
    }
    
    func setupScene() {
        backgroundColor = .black
        removeAllChildren()
        setupGameBackground()
        
        switch (gameContext.currentGameStatus) {
        case .notStarted:
            startNode = StartNode(viewModel: self)
            startNode.position = CGPoint(x: frame.midX, y: frame.midY)
            addChild(startNode)
            
        case .inProgress:
            circleTrackNode = CircleTrackNode(radius: GameConstants.circleTrackRadius,
                                                  lineWidth: GameConstants.circleTrackWidth,
                                                  color: SKColor(named: "circleTrack")!)
            circleTrackNode.position = CGPoint(x: frame.midX, y: frame.midY)
            addChild(circleTrackNode)
            
            // Add dynamic condition node
            conditionNode = ConditionNode(
                weather: gameContext.currentCondition,
                startAngle: CGFloat(gameContext.conditionPatchStartAngle),
                radius: CGFloat(GameConstants.circleTrackRadius)
            )
            conditionNode.name = "ConditionNode"
            conditionNode.position = CGPoint(x: frame.midX, y: frame.midY)
            addChild(conditionNode)
                
            // Create target node
            targetNode = TargetNode(angle: 90, scale: gameContext.scale, offset:  GameConstants.circleTrackRadius, isGlowing: gameContext.isGlowing)
            gameContext.randomNodeAngle = 90
            targetNode.position = calculateTargetNodePosition()

            addChild(targetNode)
            
            // Create bar
            movingIndicatorNode = MovingIndicatorNode(circleRadius: GameConstants.circleTrackRadius)
            movingIndicatorNode.position = CGPoint(x: frame.midX, y: frame.midY)
            addChild(movingIndicatorNode)
            
            // create scoreNode
            scoreNode = ScoreNode(score: gameContext.score)
            scoreNode.position = CGPoint(x: frame.midX, y: frame.midY)
            addChild(scoreNode)
            
        case .gameOver:
            gameOverNode = GameOverNode(viewModel: self)
            gameOverNode.position = CGPoint(x: frame.midX, y: frame.midY)
            addChild(gameOverNode)
        }
        
        // Create circle
                
        
        // Setup initial game state
        gameContext.reset()
        conditionManager.updateCondition(for: gameContext)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if gameContext.currentGameStatus == .inProgress {
            updateGameState()
            // check if circle should glow when clickabke
            updateNodePositions()
            checkGameConditions()
            if  conditionNode == childNode(withName: "ConditionNode") as? ConditionNode {
                   conditionNode.updateAppearance(
                       startAngle: CGFloat(gameContext.conditionPatchStartAngle),
                       weather: gameContext.currentCondition
                   )
            }
        }
    }
    
    func setupGameBackground() {
        var backgroundImageName: String?
        
        switch gameContext.currentGameStatus {
        case .inProgress:
            backgroundImageName = "gameBackground"
        case .gameOver:
            backgroundImageName = "gameOverBackground"
        case .notStarted:
            return
        }
        if let backgroundImageName = backgroundImageName {
            let backgroundImage = SKSpriteNode(imageNamed: backgroundImageName)
            backgroundImage.position = CGPoint(x: frame.midX, y: frame.midY)
            backgroundImage.zPosition = -1
            backgroundImage.size = frame.size
            addChild(backgroundImage)
        }
    }

    
    private func updateGameState() {
       // let cycleProgress = gameContext.progress
        var progressChange = isReverse ? -0.01 : 0.01
        
        // Apply condition effects
        progressChange = conditionManager.applyConditionEffects(
            progress: progressChange,
            context: gameContext
        )
        
        gameContext.progress += progressChange
        
        // Ensure progress stays within 0-1 range
        gameContext.progress = gameContext.progress.truncatingRemainder(dividingBy: 1.0)
        if gameContext.progress < 0 {
            gameContext.progress += 1.0
        }
        // check if circle should glow when clickabke

        let isGlowing = isRectangleInRange()
        
        // Check if the user failed to tap in time
        if targetNode.glowWidth > 0 {
            if !didTap && !isGlowing && gameContext.score > 0 {
                // The bar passed the target without a valid tap
                handleFailedTap()
            } else if didTap {
                // Reset didTap after processing a successful or failed tap
                didTap = false
            }
        }
        
        targetNode.setIsGlowing(isGlowing: isGlowing);

    }
    
    private func updateNodePositions() {
        // Calculate rotation angle based on progress
        let rotationAngle = CGFloat(gameContext.progress * .pi * 2)

        // Update bar node's position and rotation
        let x = frame.midX + CGFloat(GameConstants.circleTrackRadius * cos(rotationAngle - .pi / 2))
        let y = frame.midY + CGFloat(GameConstants.circleTrackRadius * sin(rotationAngle - .pi / 2))
        
        movingIndicatorNode.position = CGPoint(x: x, y: y)
        movingIndicatorNode.zRotation = rotationAngle
    }
    
    private func checkGameConditions() {
        // Check for condition patch
        let currentAngle = normalizeAngle(gameContext.progress * 360)
        let weatherStartAngle = gameContext.conditionPatchStartAngle
        let weatherEndAngle = normalizeAngle(weatherStartAngle + GameConstants.conditionPatchSize)
        
        gameContext.isInConditionPatch = conditionManager.isAngleInRange(
            currentAngle,
            start: weatherStartAngle,
            end: weatherEndAngle
        )
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if gameContext.currentGameStatus == .gameOver {
            gameOverNode.handleTouch(at: location)
        } else if gameContext.currentGameStatus == .notStarted {
            startNode.handleTouch(at: location)
        } else {
            handleTap()
        }
    }
    
    private func handleTap() {
        didTap = true
        
        if targetNode.glowWidth > 0 {
            handleSuccessfulTap()
        } else {
            handleFailedTap()
        }
    }
    
    private func handleSuccessfulTap() {
        gameContext.score += 1
        scoreNode.updateScore(to: gameContext.score)
        isReverse.toggle()
        
        
        // Randomize target node position
        repositionTargetNode()
        
        if Bool.random(){
            conditionManager.updateCondition(for: gameContext)
            conditionNode.updateAppearance(
                startAngle: CGFloat(gameContext.conditionPatchStartAngle),
                weather: gameContext.currentCondition
            )
        }
       
    }
    
    private func handleFailedTap() {
        gameContext.currentGameStatus = .gameOver
        setupScene()
    }
    
    private func repositionTargetNode() {
        let exclusionRange = 360.0 / 4
        var newAngle: Double
        repeat {
            newAngle = Double.random(in: 0..<360)
        } while abs(newAngle - gameContext.randomNodeAngle) < exclusionRange ||
                abs(newAngle - gameContext.randomNodeAngle) > 360 - exclusionRange
        
        gameContext.randomNodeAngle = newAngle
        targetNode.position = calculateTargetNodePosition()
    }
    
    private func calculateTargetNodePosition() -> CGPoint {
        let rotationAngle = CGFloat(gameContext.randomNodeAngle * .pi / 180)

        // Update bar node's position and rotation
        let x = frame.midX + CGFloat(GameConstants.circleTrackRadius * cos(rotationAngle - .pi / 2))
        let y = frame.midY + CGFloat(GameConstants.circleTrackRadius * sin(rotationAngle - .pi / 2))
        return CGPoint(x: x, y: y)
    }
    
    // Utility functions
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        return normalized
    }
    
    private func isAngleInRange(_ angle: Double, start: Double, end: Double) -> Bool {
        if start <= end {
            return angle >= start && angle <= end
        } else {
            return angle >= start || angle <= end
        }
    }
    
    private func isRectangleInRange() -> Bool {
        let normalizedProgress = normalizeAngle(gameContext.progress * 360)
        // else the inital node is off
        let startAngle = normalizeAngle((gameContext.score != 0 ? gameContext.randomNodeAngle: 90) - angleTolerance)
        let endAngle = normalizeAngle((gameContext.score != 0 ? gameContext.randomNodeAngle: 90) + angleTolerance)
        
        return startAngle < endAngle
            ? normalizedProgress >= startAngle && normalizedProgress <= endAngle
            : normalizedProgress >= startAngle || normalizedProgress <= endAngle
    }
    
    private static func calculateAngleTolerance() -> Double {
        return ((Double(GameConstants.nodeRadius) / Double(GameConstants.circleTrackRadius)) * 180 / .pi) * 1.75
    }
}
