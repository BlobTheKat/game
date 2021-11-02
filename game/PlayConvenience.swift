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
        sprite.position.x += 5
        sprite.position.y += 5
            sprite.run(SKAction.repeatForever(SKAction.sequence([
                    
                        SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                        SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                    ])), withKey: "vibratingObject")
                    sprite.run(SKAction.repeatForever(SKAction.sequence([
                        SKAction.moveBy(x: 0, y: -10, duration: 0.05),
                        SKAction.moveBy(x: 0, y: 10, duration: 0.05),
                    ])), withKey: "vibratingObjects")

    }
    func vibrateCamera(camera: SKCameraNode, amount: CGFloat = 0.5){
        camera.run(SKAction.repeatForever(SKAction.sequence([
                    
                        SKAction.moveBy(x: amount, y: 0, duration: 0.1),
                        SKAction.moveBy(x: -amount, y: 0, duration: 0.1),
                        SKAction.moveBy(x: -amount, y: 0, duration: 0.1),
                        SKAction.moveBy(x: amount, y: 0, duration: 0.1),
                    ])), withKey: "vibratingCamera")
        camera.run(SKAction.repeatForever(SKAction.sequence([
                        SKAction.moveBy(x: 0, y: amount, duration: 0.1),
                        SKAction.moveBy(x: 0, y: -amount, duration: 0.1),
                        SKAction.moveBy(x: 0, y: amount, duration: 0.1),
                        SKAction.moveBy(x: 0, y: -amount, duration: 0.1),
                    ])), withKey: "vibratingCameras")

    }    
    
    func pulsate(node: SKNode, amount: CGFloat, duration: CGFloat){
        
        
        
        stop.append(interval(Double(duration)) {
            node.run(SKAction.fadeAlpha(by: -amount, duration: Double(duration)/2).ease(.easeInEaseOut))
            
            let _ = timeout(Double(duration)/2) {
                node.run(SKAction.fadeAlpha(by: amount, duration: Double(duration)/2).ease(.easeInEaseOut))
            }
        })
        
        
        
    }
    func closest(_ test: CGPoint, _ a: CGPoint, _ b: CGPoint) -> Bool{
        //a = true
        //b = false
        let q1 = abs(a.x - test.x) + abs(a.y - test.y)
        let q2 = abs(b.x - test.x) + abs(b.y - test.y)
        return q1 < q2 //if a is closer
    }
}

func random() -> CGFloat{
    return CGFloat(Double(arc4random()) / 0x100000000)
}
func random(min: CGFloat, max: CGFloat) -> CGFloat{
    return floor(random() * (max - min) + min)
}

func randDir(_ radius: CGFloat) -> CGVector{
    let direction = random() * .pi * 2
    return CGVector(dx: sin(direction) * radius, dy: cos(direction) * radius)
}

func dir(_ direction: CGFloat, _ radius: CGFloat) -> CGVector{
    return CGVector(dx: sin(direction) * radius, dy: cos(direction) * radius)
}
