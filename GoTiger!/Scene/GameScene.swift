//
//  GameScene.swift
//  GoTiger!
//
//  Created by Thunpisit Amnuaikiatloet on 4/24/18.
//  Copyright © 2018 Thunpisit Amnuaikiatloet. All rights reserved.
//
import SpriteKit

class GoTigerGameScene: SKScene, SKPhysicsContactDelegate {
    struct spaceBetweenPlatforms {
        static let xSpace:CGFloat = 20
        static let ySpace:CGFloat = 4
    }
    
    var gameOver = false {
        willSet {
            if (newValue) {
                checkHighScoreAndStore()
                let gameOverLayer = childNode(withName: GoTigerGameSceneChildName.GameOverLayerName.rawValue) as SKNode?
                gameOverLayer?.run(SKAction.moveDistance(CGVector(dx: 0, dy: 100), fadeInWithDuration: 0.2))
            }
            
        }
    }
    
    let StackHeight:CGFloat = 400.0
    let StackMaxWidth:CGFloat = 300.0
    let StackMinWidth:CGFloat = 100.0
    let gravity:CGFloat = -100.0
    let StackGapMinWidth:Int = 80
    let HeroSpeed:CGFloat = 760
    
    let StoreScoreName = "com.stickHero.score"
    
    var isBegin = false
    var isEnd = false
    var leftStack:SKShapeNode?
    var rightStack:SKShapeNode?
    
    var nextLeftStartX:CGFloat = 0
    var tigerHeight:CGFloat = 0
    
    var score:Int = 0 {
        willSet {
            let scoreBand = childNode(withName: GoTigerGameSceneChildName.ScoreName.rawValue) as? SKLabelNode
            scoreBand?.text = "\(newValue)"
            scoreBand?.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1, duration: 0.1)]))
            
            if (newValue == 1) {
                let tip = childNode(withName: GoTigerGameSceneChildName.TipName.rawValue) as? SKLabelNode
                tip?.run(SKAction.fadeAlpha(to: 0, duration: 0.4))
            }
        }
    }
    
    lazy var playAbleRect:CGRect = {
        let maxAspectRatio:CGFloat = 16.0/9.0 // iPhone 5"
        let maxAspectRatioWidth = self.size.height / maxAspectRatio
        let playableMargin = (self.size.width - maxAspectRatioWidth) / 2.0
        return CGRect(x: playableMargin, y: 0, width: maxAspectRatioWidth, height: self.size.height)
    }()
    
    lazy var walkAction:SKAction = {
        var textures:[SKTexture] = []
        for i in 0...1 {
            let texture = SKTexture(imageNamed: "tiger\(i + 1).png")
            textures.append(texture)
        }
        
        let action = SKAction.animate(with: textures, timePerFrame: 0.15, resize: true, restore: true)
        
        return SKAction.repeatForever(action)
    }()
    
    //MARK: - override
    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.contactDelegate = self
    }
    
    override func didMove(to view: SKView) {
        start()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver else {
            let gameOverLayer = childNode(withName: GoTigerGameSceneChildName.GameOverLayerName.rawValue) as SKNode?
            
            let location = touches.first?.location(in: gameOverLayer!)
            let retry = gameOverLayer!.atPoint(location!)
            
            if (retry.name == GoTigerGameSceneChildName.RetryButtonName.rawValue) {
                retry.run(SKAction.sequence([SKAction.setTexture(SKTexture(imageNamed: "button_retry_down"), resize: false), SKAction.wait(forDuration: 0.3)]), completion: {[unowned self] () -> Void in
                    self.restart()
                })
            }
            return
        }
        
        if !isBegin && !isEnd {
            isBegin = true
            
            let tiger = loadTiger()
            let hero = childNode(withName: GoTigerGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
            
            let action = SKAction.resize(toHeight: CGFloat(DefinedScreenHeight - StackHeight), duration: 1.5)
            tiger.run(action, withKey:GoTigerGameSceneActionKey.GoTigerGrowAction.rawValue)
            
            let scaleAction = SKAction.sequence([SKAction.scaleY(to: 0.9, duration: 0.05), SKAction.scaleY(to: 1, duration: 0.05)])
            let loopAction = SKAction.group([SKAction.playSoundFileNamed(GoTigerGameSceneEffectAudioName.GoTigerGrowAudioName.rawValue, waitForCompletion: true)])
            tiger.run(SKAction.repeatForever(loopAction), withKey: GoTigerGameSceneActionKey.GoTigerGrowAudioAction.rawValue)
            hero.run(SKAction.repeatForever(scaleAction), withKey: GoTigerGameSceneActionKey.GoTigerScaleAction.rawValue)
            
            return
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isBegin && !isEnd {
            isEnd  = true
            
            let hero = childNode(withName: GoTigerGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
            hero.removeAction(forKey: GoTigerGameSceneActionKey.GoTigerScaleAction.rawValue)
            hero.run(SKAction.scaleY(to: 1, duration: 0.04))
            
            let tiger = childNode(withName: GoTigerGameSceneChildName.TigerName.rawValue) as! SKSpriteNode
            tiger.removeAction(forKey: GoTigerGameSceneActionKey.GoTigerGrowAction.rawValue)
            tiger.removeAction(forKey: GoTigerGameSceneActionKey.GoTigerGrowAudioAction.rawValue)
            tiger.run(SKAction.playSoundFileNamed(GoTigerGameSceneEffectAudioName.GoTigerGrowOverAudioName.rawValue, waitForCompletion: false))
            
            tigerHeight = tiger.size.height;
            
            let action = SKAction.rotate(toAngle: CGFloat(-Double.pi / 2), duration: 0.4, shortestUnitArc: true)
            let playFall = SKAction.playSoundFileNamed(GoTigerGameSceneEffectAudioName.GoTigerFallAudioName.rawValue, waitForCompletion: false)
            
            tiger.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), action, playFall]), completion: {[unowned self] () -> Void in
                self.heroGo(self.checkPass())
            })
        }
    }
    
    func start() {
        loadBackground()
        loadScoreBackground()
        loadScore()
        loadTip()
        loadGameOverLayer()
        
        leftStack = loadStacks(false, startLeftPoint: playAbleRect.origin.x)
        self.removeMidTouch(false, left:true)
        loadHero()
        
        let maxGap = Int(playAbleRect.width - StackMaxWidth - (leftStack?.frame.size.width)!)
        
        let gap = CGFloat(randomInRange(StackGapMinWidth...maxGap))
        rightStack = loadStacks(false, startLeftPoint: nextLeftStartX + gap)
        
        gameOver = false
    }
    
    func restart() {
        isBegin = false
        isEnd = false
        score = 0
        nextLeftStartX = 0
        removeAllChildren()
        start()
    }
    
    fileprivate func checkPass() -> Bool {
        let tiger = childNode(withName: GoTigerGameSceneChildName.TigerName .rawValue) as! SKSpriteNode
        
        let rightPoint = DefinedScreenWidth / 2 + tiger.position.x + self.tigerHeight
        
        guard rightPoint < self.nextLeftStartX else {
            return false
        }
        
        guard ((leftStack?.frame)!.intersects(tiger.frame) && (rightStack?.frame)!.intersects(tiger.frame)) else {
            return false
        }
        
        self.checkTouchMidStack()
        
        return true
    }
    
    fileprivate func checkTouchMidStack() {
        let tiger = childNode(withName: GoTigerGameSceneChildName.TigerName.rawValue) as! SKSpriteNode
        let stackMid = rightStack!.childNode(withName: GoTigerGameSceneChildName.StackMidName.rawValue) as! SKShapeNode
        
        let newPoint = stackMid.convert(CGPoint(x: -10, y: 10), to: self)
        
        if ((tiger.position.x + self.tigerHeight) >= newPoint.x  && (tiger.position.x + self.tigerHeight) <= newPoint.x + 20) {
            loadPerfect()
            self.run(SKAction.playSoundFileNamed(GoTigerGameSceneEffectAudioName.GoTigerTouchMidAudioName.rawValue, waitForCompletion: false))
            score += 1
        }
        
    }
    
    fileprivate func removeMidTouch(_ animate:Bool, left:Bool) {
        let stack = left ? leftStack : rightStack
        let mid = stack!.childNode(withName: GoTigerGameSceneChildName.StackMidName.rawValue) as! SKShapeNode
        if (animate) {
            mid.run(SKAction.fadeAlpha(to: 0, duration: 0.3))
        }
        else {
            mid.removeFromParent()
        }
    }
    
    fileprivate func heroGo(_ pass:Bool) {
        let hero = childNode(withName: GoTigerGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        
        guard pass else {
            let tiger = childNode(withName: GoTigerGameSceneChildName.TigerName.rawValue) as! SKSpriteNode
            
            let dis:CGFloat = tiger.position.x + self.tigerHeight
            
            let overGap = DefinedScreenWidth / 2 - abs(hero.position.x)
            let disGap = nextLeftStartX - overGap - (rightStack?.frame.size.width)! / 2
            
            let move = SKAction.moveTo(x: dis, duration: TimeInterval(abs(disGap / HeroSpeed)))
            
            hero.run(walkAction, withKey: GoTigerGameSceneActionKey.WalkAction.rawValue)
            hero.run(move, completion: {[unowned self] () -> Void in
                tiger.run(SKAction.rotate(toAngle: CGFloat(-Double.pi), duration: 0.4))
                
                hero.physicsBody!.affectedByGravity = true
                hero.run(SKAction.playSoundFileNamed(GoTigerGameSceneEffectAudioName.DeadAudioName.rawValue, waitForCompletion: false))
                hero.removeAction(forKey: GoTigerGameSceneActionKey.WalkAction.rawValue)
                self.run(SKAction.wait(forDuration: 0.5), completion: {[unowned self] () -> Void in
                    self.gameOver = true
                })
            })
            
            return
        }
        
        let dis:CGFloat = nextLeftStartX - DefinedScreenWidth / 2 - hero.size.width / 2 - spaceBetweenPlatforms.xSpace
        
        let overGap = DefinedScreenWidth / 2 - abs(hero.position.x)
        let disGap = nextLeftStartX - overGap - (rightStack?.frame.size.width)! / 2
        
        let move = SKAction.moveTo(x: dis, duration: TimeInterval(abs(disGap / HeroSpeed)))
        
        hero.run(walkAction, withKey: GoTigerGameSceneActionKey.WalkAction.rawValue)
        hero.run(move, completion: { [unowned self]() -> Void in
            self.score += 1
            
            hero.run(SKAction.playSoundFileNamed(GoTigerGameSceneEffectAudioName.VictoryAudioName.rawValue, waitForCompletion: false))
            hero.removeAction(forKey: GoTigerGameSceneActionKey.WalkAction.rawValue)
            self.moveStackAndCreateNew()
        })
    }
    
    fileprivate func checkHighScoreAndStore() {
        let highScore = UserDefaults.standard.integer(forKey: StoreScoreName)
        if (score > Int(highScore)) {
            showHighScore()
            
            UserDefaults.standard.set(score, forKey: StoreScoreName)
            UserDefaults.standard.synchronize()
        }
    }
    
    fileprivate func showHighScore() {
        self.run(SKAction.playSoundFileNamed(GoTigerGameSceneEffectAudioName.HighScoreAudioName.rawValue, waitForCompletion: false))
        
        let wait = SKAction.wait(forDuration: 0.4)
        let grow = SKAction.scale(to: 1.5, duration: 0.4)
        grow.timingMode = .easeInEaseOut
        let explosion = starEmitterActionAtPosition(CGPoint(x: 0, y: 300))
        let shrink = SKAction.scale(to: 1, duration: 0.2)
        
        let idleGrow = SKAction.scale(to: 1.2, duration: 0.4)
        idleGrow.timingMode = .easeInEaseOut
        let idleShrink = SKAction.scale(to: 1, duration: 0.4)
        let pulsate = SKAction.repeatForever(SKAction.sequence([idleGrow, idleShrink]))
        
        let gameOverLayer = childNode(withName: GoTigerGameSceneChildName.GameOverLayerName.rawValue) as SKNode?
        let highScoreLabel = gameOverLayer?.childNode(withName: GoTigerGameSceneChildName.HighScoreName.rawValue) as SKNode?
        highScoreLabel?.run(SKAction.sequence([wait, explosion, grow, shrink]), completion: { () -> Void in
            highScoreLabel?.run(pulsate)
        })
    }
    
    fileprivate func moveStackAndCreateNew() {
        let action = SKAction.move(by: CGVector(dx: -nextLeftStartX + (rightStack?.frame.size.width)! + playAbleRect.origin.x - 2, dy: 0), duration: 0.3)
        rightStack?.run(action)
        self.removeMidTouch(true, left:false)
        
        let hero = childNode(withName: GoTigerGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        let tiger = childNode(withName: GoTigerGameSceneChildName.TigerName.rawValue) as! SKSpriteNode
        
        hero.run(action)
        tiger.run(SKAction.group([SKAction.move(by: CGVector(dx: -DefinedScreenWidth, dy: 0), duration: 0.5), SKAction.fadeAlpha(to: 0, duration: 0.3)]), completion: { () -> Void in
            tiger.removeFromParent()
        })
        
        leftStack?.run(SKAction.move(by: CGVector(dx: -DefinedScreenWidth, dy: 0), duration: 0.5), completion: {[unowned self] () -> Void in
            self.leftStack?.removeFromParent()
            
            let maxGap = Int(self.playAbleRect.width - (self.rightStack?.frame.size.width)! - self.StackMaxWidth)
            let gap = CGFloat(randomInRange(self.StackGapMinWidth...maxGap))
            
            self.leftStack = self.rightStack
            self.rightStack = self.loadStacks(true, startLeftPoint:self.playAbleRect.origin.x + (self.rightStack?.frame.size.width)! + gap)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - load node
private extension GoTigerGameScene {
    func loadBackground() {
        guard let _ = childNode(withName: "background") as! SKSpriteNode? else {
            let texture = SKTexture(image: UIImage(named: "columns_jesse.jpg")!)
            let node = SKSpriteNode(texture: texture)
            node.size = texture.size()
            node.zPosition = GoTigerGameSceneZposition.backgroundZposition.rawValue
            self.physicsWorld.gravity = CGVector(dx: 0, dy: gravity)
            
            addChild(node)
            return
        }
    }
    
    func loadScore() {
        let scoreBand = SKLabelNode(fontNamed: "Arial")
        scoreBand.name = GoTigerGameSceneChildName.ScoreName.rawValue
        scoreBand.text = "0"
        scoreBand.position = CGPoint(x: 0, y: DefinedScreenHeight / 2 - 200)
        scoreBand.fontColor = SKColor.white
        scoreBand.fontSize = 100
        scoreBand.zPosition = GoTigerGameSceneZposition.scoreZposition.rawValue
        scoreBand.horizontalAlignmentMode = .center
        
        addChild(scoreBand)
    }
    
    func loadScoreBackground() {
        let back = SKShapeNode(rect: CGRect(x: 0-120, y: 1024-200-30, width: 240, height: 140), cornerRadius: 20)
        back.zPosition = GoTigerGameSceneZposition.scoreBackgroundZposition.rawValue
        back.fillColor = SKColor.black.withAlphaComponent(0.3)
        back.strokeColor = SKColor.black.withAlphaComponent(0.3)
        addChild(back)
    }
    
    func loadHero() {
        let hero = SKSpriteNode(imageNamed: "tiger1")
        hero.name = GoTigerGameSceneChildName.HeroName.rawValue
        let x:CGFloat = nextLeftStartX - DefinedScreenWidth / 2 - hero.size.width / 2 - spaceBetweenPlatforms.xSpace
        let y:CGFloat = StackHeight + hero.size.height / 2 - DefinedScreenHeight / 2 - spaceBetweenPlatforms.ySpace
        hero.position = CGPoint(x: x, y: y)
        hero.zPosition = GoTigerGameSceneZposition.heroZposition.rawValue
        hero.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 18))
        hero.physicsBody?.affectedByGravity = false
        hero.physicsBody?.allowsRotation = false
        
        addChild(hero)
    }
    
    func loadTip() {
        let tip = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        tip.name = GoTigerGameSceneChildName.TipName.rawValue
        tip.text = "GO TIGER! 🐯"
        tip.position = CGPoint(x: 0, y: DefinedScreenHeight / 2 - 350)
        tip.fontColor = UIColor.black
        tip.fontSize = 52
        tip.zPosition = GoTigerGameSceneZposition.tipZposition.rawValue
        tip.horizontalAlignmentMode = .center
        
        addChild(tip)
    }
    
    func loadPerfect() {
        defer {
            let perfect = childNode(withName: GoTigerGameSceneChildName.PerfectName.rawValue) as! SKLabelNode?
            let sequence = SKAction.sequence([SKAction.fadeAlpha(to: 1, duration: 0.3), SKAction.fadeAlpha(to: 0, duration: 0.3)])
            let scale = SKAction.sequence([SKAction.scale(to: 1.4, duration: 0.3), SKAction.scale(to: 1, duration: 0.3)])
            perfect!.run(SKAction.group([sequence, scale]))
        }
        
        guard let _ = childNode(withName: GoTigerGameSceneChildName.PerfectName.rawValue) as! SKLabelNode? else {
            let perfect = SKLabelNode(fontNamed: "Arial")
            perfect.text = "Perfect +1 🎉"
            perfect.name = GoTigerGameSceneChildName.PerfectName.rawValue
            perfect.position = CGPoint(x: 0, y: -100)
            perfect.fontColor = SKColor.black
            perfect.fontSize = 50
            perfect.zPosition = GoTigerGameSceneZposition.perfectZposition.rawValue
            perfect.horizontalAlignmentMode = .center
            perfect.alpha = 0
            
            addChild(perfect)
            
            return
        }
        
    }
    
    func loadTiger() -> SKSpriteNode {
        let hero = childNode(withName: GoTigerGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        
        let tiger = SKSpriteNode(color: SKColor.black, size: CGSize(width: 12, height: 1))
        tiger.zPosition = GoTigerGameSceneZposition.GoTigerZposition.rawValue
        tiger.name = GoTigerGameSceneChildName.TigerName.rawValue
        tiger.anchorPoint = CGPoint(x: 0.5, y: 0);
        tiger.position = CGPoint(x: hero.position.x + hero.size.width / 2 + 18, y: hero.position.y - hero.size.height / 2)
        addChild(tiger)
        
        return tiger
    }
    
    func loadStacks(_ animate: Bool, startLeftPoint: CGFloat) -> SKShapeNode {
        let max:Int = Int(StackMaxWidth / 10)
        let min:Int = Int(StackMinWidth / 10)
        let width:CGFloat = CGFloat(randomInRange(min...max) * 10)
        let height:CGFloat = StackHeight
        let stack = SKShapeNode(rectOf: CGSize(width: width, height: height))
        stack.fillColor = SKColor.gray
        stack.strokeColor = SKColor.gray
        stack.zPosition = GoTigerGameSceneZposition.stackZposition.rawValue
        stack.name = GoTigerGameSceneChildName.StackName.rawValue
        
        if (animate) {
            stack.position = CGPoint(x: DefinedScreenWidth / 2, y: -DefinedScreenHeight / 2 + height / 2)
            
            stack.run(SKAction.moveTo(x: -DefinedScreenWidth / 2 + width / 2 + startLeftPoint, duration: 0.3), completion: {[unowned self] () -> Void in
                self.isBegin = false
                self.isEnd = false
            })
            
        }
        else {
            stack.position = CGPoint(x: -DefinedScreenWidth / 2 + width / 2 + startLeftPoint, y: -DefinedScreenHeight / 2 + height / 2)
        }
        addChild(stack)
        
        let mid = SKShapeNode(rectOf: CGSize(width: 20, height: 20))
        mid.fillColor = SKColor.yellow
        mid.strokeColor = SKColor.yellow
        mid.zPosition = GoTigerGameSceneZposition.stackMidZposition.rawValue
        mid.name = GoTigerGameSceneChildName.StackMidName.rawValue
        mid.position = CGPoint(x: 0, y: height / 2 - 20 / 2)
        stack.addChild(mid)
        
        nextLeftStartX = width + startLeftPoint
        
        return stack
    }
    
    func loadGameOverLayer() {
        let node = SKNode()
        node.alpha = 0
        node.name = GoTigerGameSceneChildName.GameOverLayerName.rawValue
        node.zPosition = GoTigerGameSceneZposition.gameOverZposition.rawValue
        addChild(node)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.text = "You got an 'F'"
        label.fontColor = UIColor.black //UIColor(red:0.95, green:0.72, blue:0.18, alpha:1.0)
        label.fontSize = 100
        label.position = CGPoint(x: 0, y: 100)
        label.horizontalAlignmentMode = .center
        node.addChild(label)
        
        let sublabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        sublabel.text = "F for Failure! 😂"
        sublabel.fontColor = UIColor.black //UIColor(red:0.95, green:0.72, blue:0.18, alpha:1.0)
        sublabel.fontSize = 50
        sublabel.position = CGPoint(x: 0, y: 0)
        sublabel.horizontalAlignmentMode = .center
        node.addChild(sublabel)
        
        let retry = SKSpriteNode(imageNamed: "button_retry_up")
        retry.name = GoTigerGameSceneChildName.RetryButtonName.rawValue
        retry.position = CGPoint(x: 0, y: -200)
        node.addChild(retry)
        
        let highScore = SKLabelNode(fontNamed: "AmericanTypewriter")
        highScore.text = "Highscore! 🏆"
        highScore.fontColor = UIColor.white
        highScore.fontSize = 50
        highScore.name = GoTigerGameSceneChildName.HighScoreName.rawValue
        highScore.position = CGPoint(x: 0, y: 300)
        highScore.horizontalAlignmentMode = .center
        highScore.setScale(0)
        node.addChild(highScore)
    }
    
    //MARK: - Action
    func starEmitterActionAtPosition(_ position: CGPoint) -> SKAction {
        let emitter = SKEmitterNode(fileNamed: "StarExplosion")
        emitter?.position = position
        emitter?.zPosition = GoTigerGameSceneZposition.emitterZposition.rawValue
        emitter?.alpha = 0.6
        addChild((emitter)!)
        
        let wait = SKAction.wait(forDuration: 0.15)
        
        return SKAction.run({ () -> Void in
            emitter?.run(wait)
        })
    }
    
}
