//
//  PlayerDied.swift
//  game
//
//  Created by Adam Reiner on 06/08/2021.
//

import Foundation
import SpriteKit

class PlayerDied: PlayConvenience{
    
    
    let charcter = SKSpriteNode(imageNamed: "characterDied")
    let stars = SKSpriteNode(imageNamed: "stars11")
    let planet2 = SKSpriteNode(imageNamed: "planet2.")
    let planet3 = SKSpriteNode(imageNamed: "planet3.")
    let rock1 = SKSpriteNode(imageNamed: "rock1")
    let rock2 = SKSpriteNode(imageNamed: "rock2")
    let rock3 = SKSpriteNode(imageNamed: "rock3")
    let rock4 = SKSpriteNode(imageNamed: "rock1")
    let shadeRight = SKSpriteNode(imageNamed: "shadeRight")
    let shadeLeft = SKSpriteNode(imageNamed: "shadeLeft")
    let reconnectLabel = SKLabelNode()
    let tapToReconnect = SKLabelNode()
    
    override func didMove(to view: SKView) {
        
        label(node: reconnectLabel, "", pos: pos(mx: 0.5, my: 0.6), size: fsmall, color: UIColor.white)
        
        label(node: tapToReconnect, "-tap to respawn-", pos: pos(mx: 0.5, my: 0.3, y: -50), size: fsmall - 3.5, color: UIColor.white)
        
        pulsate(node: tapToReconnect, amount: 0.6, duration: 3)
        
        
        
        charcter.position = pos(mx: -0.1, my: 0.6)
        charcter.setScale(0.2)
        charcter.zPosition = 4
        self.addChild(charcter)
        
        charcter.run(SKAction.sequence([
        
            SKAction.moveBy(x: 400, y: 0, duration: 5).ease{a in return 2*a - a*a},
            
            SKAction.moveBy(x: 625, y: 0, duration: 30).ease(.easeInEaseOut)
        
        ]))
        charcter.run(SKAction.scale(by: 0.1, duration: 40))
        charcter.run(SKAction.rotate(byAngle: -4, duration: 40))
        let _ = interval(4) {
            self.charcter.run(SKAction.moveBy(x: 0, y: 7, duration: 2).ease(.easeInEaseOut))
            
            let _ = self.timeout(2) {
                self.charcter.run(SKAction.moveBy(x: 0, y: -7, duration: 2).ease(.easeInEaseOut))
            }
        }
        let text = "You died!"
        var i = 0
        let _ = timeout(0.2){var a = {};a = self.interval(0.1){
            if i == text.count{
                a()
                return
            }
            self.reconnectLabel.text? += "\(text[i])"
            i += 1
        }}
        
        
        
        
        
        planet2.position = pos(mx: 0.9, my: 0.75)
        planet2.setScale(0.2)
        planet2.zPosition = 2
        self.addChild(planet2)
        
        planet3.position = pos(mx: 0.1, my: 0.2)
        planet3.setScale(0.2)
        planet3.zPosition = 2
        self.addChild(planet3)

        
        stars.position = pos(mx: 0.5, my: 0.5)
        stars.setScale(0.2)
        stars.zPosition = 1
        self.addChild(stars)
        
        rock1.position = pos(mx: 0.65, my: 0.4)
        rock1.setScale(0.2)
        rock1.zPosition = 3
        self.addChild(rock1)
        rock1.run(SKAction.moveBy(x: 90, y: -120, duration: 30).ease(.easeOut))
        rock1.run(SKAction.rotate(byAngle: 2, duration: 30))
        
        rock2.position = pos(mx: 0.55, my: 0.2)
        rock2.setScale(0.2)
        rock2.zPosition = 3
        self.addChild(rock2)
        rock2.run(SKAction.moveBy(x: 20, y: -120, duration: 45).ease(.easeOut))
        rock2.run(SKAction.rotate(byAngle:-2.5, duration: 45))
        
        rock3.position = pos(mx: 0.3, my: 0.4)
        rock3.setScale(0.2)
        rock3.zPosition = 3
        self.addChild(rock3)
        rock3.run(SKAction.moveBy(x: -90, y: -120, duration: 35).ease(.easeOut))
        
        rock4.position = pos(mx: 0.35, my: 0.75)
        rock4.setScale(0.2)
        rock4.zPosition = 3
        rock4.run(SKAction.moveBy(x: -90, y: 120, duration: 40).ease(.easeOut))
        rock4.run(SKAction.rotate(byAngle: -4, duration: 40))
       
        self.addChild(rock4)
        
        shadeRight.position = pos(mx: 0.54, my: 0.5)
        shadeRight.setScale(0.35)
        shadeRight.zPosition = 5
        self.addChild(shadeRight)
        
        shadeLeft.position = pos(mx: 0.54, my: 0.5)
        shadeLeft.setScale(0.35)
        shadeLeft.zPosition = 5
         self.addChild(shadeLeft)
    }
    
    
    override func nodeDown(_: SKNode, at _: CGPoint) {
        SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
        Play.renderTo(skview)
        SKScene.transition = SKTransition.crossFade(withDuration: 0)
    }
    
    
    
    
    
    
    
    
    
    
}
