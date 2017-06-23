//
//  GameScene.swift
//  Hoppy Bunny
//
//  Created by Campbell CRAVENS on 6/20/17.
//  Copyright © 2017 Campbell CRAVENS. All rights reserved.
//

import SpriteKit

var hero: SKSpriteNode!
var sinceTouch: CFTimeInterval = 0
var spawnTimer: CFTimeInterval = 0
let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */
let scrollSpeed: CGFloat = 100
var scrollLayer: SKNode!
var obstacleSource: SKNode!
var obstacleLayer: SKNode!
var buttonRestart: MSButtonNode!
var scoreLabel: SKLabelNode!



enum GameSceneState {
    case active, gameOver
}



class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameState: GameSceneState = .active
    var points = 0
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        
        /* Recursive node search for 'hero' (child of referenced node) */
        hero = self.childNode(withName: "//hero") as! SKSpriteNode
        
        // Set reference to scroll layer node
        scrollLayer = self.childNode(withName: "scrollLayer")
        
        // Set reference to obstacle node
        obstacleSource = self.childNode(withName: "obstacle")
        
        // Set reference to obstacle layer node
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        
        // set reference to button restart node
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        
        // set reference to score label node
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        // Set physics contact delegate
        physicsWorld.contactDelegate = self
        
        // set up restart button selected handler
        buttonRestart.selectedHandler = {
            // define the spritekit view
            let skView = self.view as SKView!
            // load GameScene
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            // Ensure correct scale
            scene?.scaleMode = .aspectFill
            // Restart gamescene
            skView?.presentScene(scene)
        }
        
        // Hide Button
        buttonRestart.state = .MSButtonNodeStateHidden
        
        // Set score label
        scoreLabel.text = "\(points)"
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if gameState != .active {
            return
        }
        
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        // Apply falling rotation
        if sinceTouch > 0.2 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        // Clamp Rotation
        hero.zRotation.clamp(v1: CGFloat(-90).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(v1: -1, 3)
        
        // Update last touch timer
        sinceTouch += fixedDelta
        
        // Update spawn timer
        spawnTimer += fixedDelta
        
        // run scroll world function
        scrollWorld()
        
        // run update obstacles function
        updateObstacles()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        
        if gameState != .active {
            return
        }
        
        // reset velocity to 0 on touch for smoothness
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
        
        // Apply subtle rotation
        hero.physicsBody?.applyAngularImpulse(1)
        
        // Reset touch timer
        sinceTouch = 0
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Detect contact
        
        // define two bodies in collision
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        // get references to the body parent nodes
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if nodeA.name == "goal" || nodeB.name == "goal" {
            points += 1
            scoreLabel.text = "\(points)"
            return
        }
        
        
        // only allow when game is active
        if gameState != .active {
            print ("not active")
            return
        }
        // change state to gameOver
        gameState = .gameOver
        // allow no more movement after death, stop all animations
        hero.physicsBody?.allowsRotation = false
        hero.physicsBody?.angularVelocity = 0
        hero.removeAllActions()
        
        // face plant
        let heroDeath = SKAction.run ({
            hero.zRotation = CGFloat(-90).degreesToRadians()
        })
        
        hero.run(heroDeath)
        
        // show restart button
        buttonRestart.state = .MSButtonNodeStateActive
        
        // shake screen
        let shakeScene: SKAction = SKAction.init(named: "Shake")!
        
        for node in children {
            node.run(shakeScene)
        }
        
    }
    
    
    func scrollWorld() {
        // Scroll World
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        // Scroll ground 
        for ground in scrollLayer.children as! [SKSpriteNode] {
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            if groundPosition.x <= -ground.size.width / 2 {
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        // create endless obstacles
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            if obstaclePosition.x <= -26 {
            obstacle.removeFromParent()
            }
        }
        // Time to add new obstacle
        if spawnTimer > 1.5 {
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            // Random generate obstacle positions
            let randomPosition = CGPoint(x: 352, y: CGFloat.random(min: 234, max: 382))
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            spawnTimer = 0
        }
    }
}
