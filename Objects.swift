//
//  Objects.swift
//  game
//
//  Created by BlobKat on 22/07/2021.
//

import Foundation
import SpriteKit

let G: CGFloat = 0.0001

struct bitmask{
    static let ship: UInt32 = 1
    static let planet: UInt32 = 2
    static let asteroid: UInt32 = 4
}

class Ship: SKSpriteNode{
    var radius: CGFloat = 0
    var mass: CGFloat = 1
    var velocity: CGVector = CGVector()
    var angularVelocity: CGFloat = 0
    init(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture = SKTexture()){
        super.init(texture: texture, color: UIColor.clear, size: CGSize(width: radius * 2, height: radius * 2))
        self.body(radius: radius, mass: mass)
    }
    func update(){
        position.x += velocity.dx
        position.y += velocity.dy
        zRotation += angularVelocity
    }
    func body(radius: CGFloat, mass: CGFloat){
        var m = mass
        if m == -1{
            m = radius * radius
        }
        self.mass = m
        self.radius = radius
        self.size.width = radius * 2
        self.size.height = radius * 2
    }
    
    convenience init(){
        self.init(radius: 0, mass: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class Planet: Ship{
    override func update(){
        self.zRotation += angularVelocity
    }
    func gravity(_ n: Ship) -> Bool{
        let mass: CGFloat = self.physicsBody?.mass ?? self.size.width * self.size.height / 4
        let x = n.position.x - self.position.x
        let y = n.position.y - self.position.y
        let d = (x * x + y * y)
        var r = self.radius * self.radius - n.radius * n.radius
        r += (2 * sqrt(r) + n.radius) * n.radius
        if d < r - 1{
            //collided
            let m = sqrt(r / d) - 1
            n.position.x += x * m
            n.position.y += y * m
            n.velocity.dx = 0
            n.velocity.dy = 0
            n.angularVelocity = 0
            n.zRotation = atan2(y, x) - .pi/2
            return true
        }else if d < r{
            //resting on planet
            return true
        }else{
            let m = -(mass*G)/d
            n.velocity.dx += x * m
            n.velocity.dy += y * m
        }
        return false
    }
}
class Ray{
    var position: CGPoint
    var direction: CGFloat
    init(position: CGPoint, direction: CGFloat){
        self.position = position
        self.direction = direction
    }
    func intersects(_ n: Ship) -> Bool{
        let x = n.position.x - self.position.x
        let y = n.position.y - self.position.y
        let ang = atan2(y, x)
        let width = atan(n.radius / sqrt(x*x + y*y))
        let a = abs(ang - self.direction)
        return a < width || a > .pi*2 - width
    }
}
