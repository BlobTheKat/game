//
//  PlayConvenience.swift
//  game
//
//  Created by Adam Reiner on 30/07/2021.
//

import Foundation
import SpriteKit

class PlayConvenience: SKScene{    
    func vibrateObject(sprite: SKSpriteNode){

            sprite.run(SKAction.repeatForever(SKAction.sequence([
                    
                        SKAction.moveBy(x: -5, y: 0, duration: 0.05),
                        SKAction.moveBy(x: 5, y: 0, duration: 0.05),
                    ])), withKey: "vibratingObject")
                    sprite.run(SKAction.repeatForever(SKAction.sequence([
                        SKAction.moveBy(x: 0, y: -5, duration: 0.05),
                        SKAction.moveBy(x: 0, y: 5, duration: 0.05),
                    ])), withKey: "vibratingObjects")

    }
    func vibrateCamera(camera: SKCameraNode){

        camera.run(SKAction.repeatForever(SKAction.sequence([
                    
                        SKAction.moveBy(x: 0.5, y: 0, duration: 0.1),
                        SKAction.moveBy(x: -0.5, y: 0, duration: 0.1),
                        SKAction.moveBy(x: -0.5, y: 0, duration: 0.1),
                        SKAction.moveBy(x: 0.5, y: 0, duration: 0.1),
                    ])), withKey: "vibratingCamera")
        camera.run(SKAction.repeatForever(SKAction.sequence([
                        SKAction.moveBy(x: 0, y: 0.5, duration: 0.1),
                        SKAction.moveBy(x: 0, y: -0.5, duration: 0.1),
                        SKAction.moveBy(x: 0, y: 0.6, duration: 0.1),
                        SKAction.moveBy(x: 0, y: -0.6, duration: 0.1),
                    ])), withKey: "vibratingCameras")

    }    
    
    func pulsate(node: SKNode, amount: CGFloat, duration: CGFloat){
        
        
        
        let _ = interval(Double(duration)) {
            node.run(SKAction.fadeAlpha(by: -amount, duration: Double(duration)/2).ease(.easeInEaseOut))
            
            let _ = self.timeout(Double(duration)/2) {
                node.run(SKAction.fadeAlpha(by: amount, duration: Double(duration)/2).ease(.easeInEaseOut))
            }
        }
        
        
        
    }
}

func random() -> CGFloat{
    return CGFloat(Float(arc4random()) / 0x100000000)
}
func random(min: CGFloat, max: CGFloat) -> CGFloat{
    return floor(random() * (max - min) + min)
}

func randDir(_ radius: CGFloat) -> CGVector{
    let direction = random() * .pi * 2
    return CGVector(dx: sin(direction) * radius, dy: cos(direction) * radius)
}
