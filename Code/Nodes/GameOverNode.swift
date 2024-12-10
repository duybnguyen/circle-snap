import SpriteKit

class GameOverNode: SKNode {
    let viewModel: CSGameScene
    
    private var playAgainButton: SKShapeNode!
    private let playAgainLabel = SKLabelNode(text: "Play again")
    
    init(viewModel: CSGameScene) {
        self.viewModel = viewModel
        super.init()
        
        setupGameOverUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGameOverUI() {
        // Frame for the "Game Over" overlay
        let frameWidth = UIScreen.main.bounds.width * 0.8
        let frameHeight = frameWidth
        
        let scoreFrame = SKShapeNode(rectOf: CGSize(width: frameWidth, height: frameHeight), cornerRadius: 10)
        scoreFrame.fillColor = .clear
        scoreFrame.lineWidth = 4
        scoreFrame.strokeColor = SKColor(named: "scoreFrameBorder")!
        scoreFrame.position = CGPoint(x: 0, y: 0) // Positioned relative to GameOverNode
        self.addChild(scoreFrame)
        
        // Play Again Button
        playAgainLabel.fontSize = 20
        playAgainLabel.fontColor = SKColor(named: "endScreenButton")!
        playAgainLabel.fontName = ".SFUIDisplay-Bold"
        playAgainLabel.zPosition = 1
        playAgainLabel.verticalAlignmentMode = .center
        playAgainLabel.name = "playAgainLabel" // Assign name for touch detection
        
        let textSize = playAgainLabel.frame.size
        playAgainButton = SKShapeNode(rectOf: CGSize(width: textSize.width + 80, height: textSize.height + 20), cornerRadius: 10)
        playAgainButton.fillColor = .white
        playAgainButton.lineWidth = 2
        playAgainButton.strokeColor = SKColor(named: "endScreenButton")!
        playAgainButton.zPosition = 0
        playAgainButton.name = "playAgainButton"
        
        playAgainButton.position = CGPoint(x: 0, y: -frameHeight / 2 - 40)
        playAgainLabel.position = playAgainButton.position
        
        // Add button and label
        self.addChild(playAgainButton)
        self.addChild(playAgainLabel)
    }
    
    // Handle Play Again Button
    func handlePlayAgainTapped() {
        // Reset game state
        viewModel.gameContext.reset()
        viewModel.gameContext.currentGameStatus = .inProgress
        viewModel.setupScene()
    }
    
    // Detect Touch on "Play Again" Button
    func handleTouch(at point: CGPoint) {
        let localPoint = self.convert(point, from: self.scene!)
        
        if playAgainButton.contains(localPoint) {
            // Animate button and label before handling tap
            animateButtonAndLabel(button: playAgainButton, label: playAgainLabel) {
                self.handlePlayAgainTapped()
            }
        }
    }
    
    // Animate Button and Label (Shrink and Expand)
    private func animateButtonAndLabel(button: SKShapeNode, label: SKLabelNode, completion: @escaping () -> Void) {
        // Create shrink and expand actions
        let shrinkAction = SKAction.scale(to: 0.8, duration: 0.1)
        let expandAction = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([shrinkAction, expandAction])
        
        // Run the animations in parallel
        let group = SKAction.group([sequence, SKAction.run(completion)])
        
        // Apply the same scaling sequence to both the button and the label
        button.run(sequence)
        label.run(sequence, completion: {
            completion()
        })
    }
}
