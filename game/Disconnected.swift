//
//  Disconnected.swift
//  game
//
//  Created by Matthew on 05/08/2021.
//

import Foundation
import SpriteKit

class Disconnected: PlayConvenience{
    
    let charcter = SKSpriteNode(imageNamed: "character")
    let stars = SKSpriteNode(imageNamed: "stars11")
    let planet = SKSpriteNode(imageNamed: "planet")
    let rock1 = SKSpriteNode(imageNamed: "rock1")
    let rock2 = SKSpriteNode(imageNamed: "rock2")
    let rock3 = SKSpriteNode(imageNamed: "rock3")
    let rock4 = SKSpriteNode(imageNamed: "rock1")
    let shaders = SKSpriteNode(imageNamed: "shaders")
    let reconnectLabel = SKLabelNode()
    let tapToReconnect = SKLabelNode()
    
    override func didMove(to view: SKView) {
        
        label(node: reconnectLabel, dmessage, pos: pos(mx: 0.5, my: 0.3), size: fsmall, color: .white)
        dmessage = "Disconnected!"
        label(node: tapToReconnect, "-tap to reconnect-", pos: pos(mx: 0.5, my: 0.3, y: -50), size: fsmall - 3.5, color: .white)
        
        pulsate(node: tapToReconnect, amount: 0.6, duration: 3)
        
        
        
        charcter.position = pos(mx: 0.5, my: 0.65)
        charcter.setScale(0.2)
        charcter.zPosition = 4
        self.addChild(charcter)
        
        stop.append(interval(4) {
            self.charcter.run(SKAction.moveBy(x: 0, y: 7, duration: 2).ease(.easeInEaseOut))
            
            let _ = timeout(2) {
                self.charcter.run(SKAction.moveBy(x: 0, y: -7, duration: 2).ease(.easeInEaseOut))
            }
        })
    
        
        planet.position = pos(mx: 0.9, my: 0.85)
        planet.setScale(0.2)
        planet.zPosition = 2
        self.addChild(planet)
        
        
        
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
        
        shaders.position = pos(mx: 0.54, my: 0.5)
        shaders.fitTo(self)
        shaders.zPosition = 5
        self.addChild(shaders)
    }
    
    
    override func touch(at _: CGPoint) {
        SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
        Play.renderTo(skview)
        SKScene.transition = SKTransition.crossFade(withDuration: 0)
    }
    
}
