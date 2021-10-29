//
//  DPlay.swift
//  game
//
//  Created by Adam Reiner on 22/10/2021.
//

import Foundation
import SpriteKit

let doorOpen = [SKTexture(imageNamed: "door7"), SKTexture(imageNamed: "door6"), SKTexture(imageNamed: "door5"), SKTexture(imageNamed: "door4"), SKTexture(imageNamed: "door3"), SKTexture(imageNamed: "door2"), SKTexture(imageNamed: "door1")]
let doorClose: [SKTexture] = doorOpen.reversed()

class DPlay:PlayConvenience, SKPhysicsContactDelegate{
    
    
    let Dship = SKSpriteNode(imageNamed: "Dship")
    let player = SKSpriteNode(imageNamed: "player0")
    let boxes = SKSpriteNode(imageNamed: "boxes")
    let boxOutline = SKSpriteNode(imageNamed: "boxOutline")
    let outline = SKSpriteNode(imageNamed: "outline")
    let toEnter = SKSpriteNode(imageNamed: "toEnter")
    let inCockpit = SKSpriteNode(imageNamed: "inCockpitOff")
    let star1 = SKSpriteNode(imageNamed: "stars")
    let star2 = SKSpriteNode(imageNamed: "stars")
    let cam = SKCameraNode()
    let door = SKSpriteNode(imageNamed: "door7")
    //Sound
    
    let inShipSound = SKAudioNode(fileNamed: "inshipSound.wav")
    let playerWalking = SKAudioNode(fileNamed: "playerWalking.wav")
    
    struct physicscategory{
        
        static let player: UInt32 = 0b1
        static let outline: UInt32 = 0b10
        static let hitBox: UInt32 = 0b100
        
    }
    
    func contact(_ body1: SKPhysicsBody, _ body2: SKPhysicsBody){}
    func didBegin(_ contact: SKPhysicsContact){
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask <  contact.bodyB.categoryBitMask{
            body1 = contact.bodyA
            body2 = contact.bodyB
        }else{
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == physicscategory.player && body2.categoryBitMask == physicscategory.hitBox{
            inCockpit.alpha = 1
            print("hi")
        }
        
        
    }
    override func didMove(to view: SKView) {

        self.addChild(inShipSound)
        self.addChild(playerWalking)
        playerWalking.run(stopSound)
        
        self.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.run{ self.inShipSound.run(playSound)},
            SKAction.wait(forDuration: 49)
        ])))
        vibrateCamera(camera: cam, amount: 1)
        //SCENE
        self.addChild(cam)
        self.camera = cam
        Dship.setScale(0.3)
        Dship.position = pos(mx: 0, my: 0)
        Dship.zPosition = -10000
        self.addChild(Dship)
        
        cam.addChild(star1)
        star1.setScale(2)
        star1.zPosition = -10001
        cam.addChild(star2)
        star2.setScale(2)
        star2.zPosition = -10001
        star2.position.y = SS
        
        boxes.setScale(0.3)
        boxes.position.y = -150
        boxes.zPosition = 150
        self.addChild(boxes)
        
        inCockpit.setScale(0.5)
        inCockpit.position = pos(mx: 0.5, my: 0.5, x: -100, y: -40)
        inCockpit.zPosition = 4
        inCockpit.alpha = 1
        
        outline.setScale(0.3)
        outline.position = pos(mx: 0, my: 0, y: -40)
        outline.zPosition = 5
        outline.alpha = 0
        
        outline.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "outline"), size: outline.size)
        outline.physicsBody!.categoryBitMask = physicscategory.outline
        outline.physicsBody!.collisionBitMask = physicscategory.player
        outline.physicsBody!.affectedByGravity = false
        outline.physicsBody!.allowsRotation = false
        outline.physicsBody!.isDynamic = false
        
        self.addChild(outline)
        
        
        boxOutline.setScale(0.3)
        boxOutline.position.y = -170
        boxOutline.zPosition = 5
        boxOutline.alpha = 0
        
        boxOutline.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "boxOutline"), size: boxOutline.size)
        boxOutline.physicsBody!.categoryBitMask = physicscategory.outline
        boxOutline.physicsBody!.collisionBitMask = physicscategory.player
        boxOutline.physicsBody!.affectedByGravity = false
        boxOutline.physicsBody!.allowsRotation = false
        boxOutline.physicsBody!.isDynamic = false
        
        self.addChild(boxOutline)
        
        
        toEnter.setScale(0.3)
        toEnter.position = pos(mx: 0, my: 0.48)
        toEnter.zPosition = 5
        toEnter.alpha = 0
        
        toEnter.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "toEnter"), size: toEnter.size)
        toEnter.physicsBody!.categoryBitMask = physicscategory.hitBox
        toEnter.physicsBody!.contactTestBitMask = physicscategory.player | physicscategory.hitBox
        toEnter.physicsBody!.affectedByGravity = false
        toEnter.physicsBody!.allowsRotation = false
        toEnter.physicsBody!.isDynamic = false
        
        self.addChild(toEnter)
        
        
        
        
        
        player.setScale(0.2)
        player.position = pos(mx: 0, my: 0, y: 150)
        player.zPosition = 3
        
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 35, height: 10))//SKPhysicsBody(texture: SKTexture(imageNamed: "player0"), size: player.size)
        player.physicsBody!.categoryBitMask = physicscategory.player
        player.physicsBody!.collisionBitMask = physicscategory.outline
        player.physicsBody!.contactTestBitMask = physicscategory.player | physicscategory.hitBox
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.isDynamic = true
        player.anchorPoint = CGPoint(x: 0.5, y: 0)
        self.addChild(player)
        
        cam.addChild(dPad)
        dPad.position = pos(mx: 0.4, my: -0.4, x: -50, y: 50)
        dPad.zPosition = 10
        dPad.setScale(1.5)
        
        self.addChild(door)
        door.position.y = 262
        door.zPosition = -262
        door.setScale(0.3)
    }
    var latency = 0.0
    var lastUpdate: TimeInterval? = nil
    let border1 = SKSpriteNode(imageNamed: "tunnel1")
    let border2 = SKSpriteNode(imageNamed: "tunnel1")
    var started = false
    var camOffset = CGPoint(x: 0, y: 0.2)
    
    func cameraUpdate(){
        let x = player.position.x - cam.position.x - camOffset.x
        let y = player.position.y - cam.position.y - camOffset.y
        cam.position.x += x / 10
        cam.position.y += y / 10
            /*let xStress = abs(x / (self.size.width * cam.xScale))
            let yStress = abs(y / (self.size.height * cam.yScale))
            let stress = xStress*2 + yStress*2

            let scale = (cam.xScale + cam.yScale) / 2
            
                let ts = min((stress / 0.6 - 1) * scale, 5 - scale)
                cam.setScale(scale + ts / 50)*/
    }
    
    var movingUp = false
    var movingDown = false
    var movingRight = false
    var movingLeft = false
    var playerSpriteNumber = 0.0
    let dPad = SKSpriteNode(imageNamed: "dPad")
    override func nodeDown(_ node: SKNode, at point: CGPoint) {
        if dPad == node{
            let T = dPad.size.width / 7
            movingRight = point.x > dPad.position.x + T
            movingLeft = point.x < dPad.position.x - T
            movingUp = point.y > dPad.position.y + T
            movingDown = point.y < dPad.position.y - T
            if movingRight{
                player.xScale = 0.2
                dPad.texture = SKTexture(imageNamed: "dPadRight")
            }else if movingLeft{
                player.xScale = -0.2
                dPad.texture = SKTexture(imageNamed: "dPadLeft")
            }else{
                dPad.texture = SKTexture(imageNamed: "dPad")
            }
            
        }
        if inCockpit == node{
            
            SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
            Play.renderTo(skview)
            SKScene.transition = SKTransition.crossFade(withDuration: 0)
            
        }
    }
    override func nodeMoved(_ node: SKNode, at point: CGPoint) {
        if dPad == node{
            let T = dPad.size.width / 7
            movingRight = point.x > dPad.position.x + T
            movingLeft = point.x < dPad.position.x - T
            movingUp = point.y > dPad.position.y + T
            movingDown = point.y < dPad.position.y - T
            if movingRight{
                player.xScale = 0.2
                dPad.texture = SKTexture(imageNamed: "dPadRight")
            }else if movingLeft{
                dPad.texture = SKTexture(imageNamed: "dPadLeft")
                player.xScale = -0.2
            }else{
                dPad.texture = SKTexture(imageNamed: "dPad")
            }
            
        }
    }
    override func nodeUp(_ node: SKNode, at point: CGPoint) {
        
        
        if dPad == node{
            movingRight = false
            movingLeft = false
            movingUp = false
            movingDown = false
            dPad.texture = SKTexture(imageNamed: "dPad")
            
        }
    }
    var isOpen: Bool = false
    
    var playingWalkingSound = false
    override func update(_ currentTime: TimeInterval){
        
        if (movingRight || movingLeft || movingUp || movingDown) && !playingWalkingSound{
            
            playingWalkingSound = true
            self.playerWalking.run(playSound)
        }
        if !movingRight && !movingLeft && !movingUp && !movingDown{
            
            self.playerWalking.run(stopSound)
            playingWalkingSound = false
        }
        
        
        
        
        if view == nil{return}
        let ti = 1/gameFPS
        if lastUpdate == nil{
            lastUpdate = currentTime - ti
        }
        latency += currentTime - lastUpdate! - ti
        lastUpdate = currentTime
        
        
        if latency > ti{
            latency -= ti
            update(currentTime)
        }else if latency < -ti{
            latency += ti
            return
        }
        DispatchQueue.main.async{
            self.cameraUpdate()
        
        }
        
        //MOVEMENT
        if movingUp == true{
            player.position.y += 3
        }
        if movingDown == true{
            player.position.y -= 3
        }
        if movingRight == true{
            player.position.x += 3
        }
        if movingLeft == true{
            player.position.x -= 3
        }
        
        if movingUp || movingDown || movingRight || movingLeft{
            player.texture = SKTexture(imageNamed: "player\(Int(playerSpriteNumber) + 1)")
            playerSpriteNumber = (playerSpriteNumber + 0.1).truncatingRemainder(dividingBy: 4)
        }else{
            player.texture = SKTexture(imageNamed: "player0")
        }
        star1.position.y -= 1.5
        star2.position.y -= 1.5
        if star1.frame.maxY < -self.size.height / 2{
            star1.position.y += SS * 2
        }
        if star2.frame.maxY < -self.size.height / 2{
            star2.position.y += SS * 2
        }
        let inRange = player.position.y > 170 && abs(player.position.x) < 80
        if inRange && !isOpen{
            isOpen = true
            //open
            door.removeAction(forKey: "anim")
            door.run(.animate(with: [SKTexture](doorOpen.dropFirst(doorOpen.firstIndex(of: door.texture!) ?? 0)), timePerFrame: 0.05), withKey: "anim")
            cam.addChild(inCockpit)
        }else if isOpen && !inRange{
            isOpen = false
            //close
            door.removeAction(forKey: "anim")
            door.run(.animate(with: [SKTexture](doorClose.dropFirst(doorClose.firstIndex(of: door.texture!) ?? 0)), timePerFrame: 0.05), withKey: "anim")
            inCockpit.removeFromParent()
        }
        player.zPosition = -player.position.y
    }
    
    override func keyDown(_ key: UIKeyboardHIDUsage) {
        if key == .keyboardUpArrow || key == .keyboardW{
            movingUp = true
           
        }else if key == .keyboardRightArrow || key == .keyboardD{
          movingRight = true
          
            player.xScale = 0.2
        }else if key == .keyboardLeftArrow || key == .keyboardA{
            movingLeft = true
           
            player.xScale = -0.2
        }else if key == .keyboardDownArrow || key == .keyboardS{
           movingDown = true
           
        }
    }
    
    override func keyUp(_ key: UIKeyboardHIDUsage) {
        
        
        
        if key == .keyboardUpArrow || key == .keyboardW{
          movingUp = false
           
        }else if key == .keyboardRightArrow || key == .keyboardD{
           movingRight = false
           
        }else if key == .keyboardLeftArrow || key == .keyboardA{
           movingLeft = false
           
        }else if key == .keyboardDownArrow || key == .keyboardS{
           movingDown = false
            
        }
    }
    
    
}

