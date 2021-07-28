//
//  Objects.swift
//  game
//
//  Created by BlobKat on 22/07/2021.
//

import Foundation
import SpriteKit

let G: CGFloat = 0.04

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
        var m = mass
        if m == -1{
            m = radius * radius
        }
        self.body(radius: radius, mass: m)
    }
    func update(){
        position.x += velocity.dx
        position.y += velocity.dy
        zRotation += angularVelocity
    }
    func body(radius: CGFloat, mass: CGFloat){
        self.mass = mass
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


class Planet: SKSpriteNode{
    var radius: CGFloat = 0
    var mass: CGFloat = 0
    var angularVelocity: CGFloat = 0
    func gravity(_ n: Ship){
        let mass: CGFloat = self.physicsBody?.mass ?? self.size.width * self.size.height / 4
        let x = n.position.x - self.position.x
        let y = n.position.y - self.position.y
        let m = -(mass*G)/(x * x + y * y)
        n.velocity.dx += x * m
        n.velocity.dy += y * m
    }
    
    init(radius: CGFloat, mass: CGFloat = -1){
        super.init(texture: SKTexture(), color: UIColor.clear, size: CGSize(width: radius * 2, height: radius * 2))
        self.body(radius: radius, mass: mass)
    }
    func body(radius: CGFloat, mass: CGFloat = -1){
        var m = mass
        if mass == -1{m = radius * radius}
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody!.mass = m
        self.physicsBody!.isDynamic = false
        self.physicsBody!.categoryBitMask = bitmask.planet
        self.physicsBody!.collisionBitMask = bitmask.ship
        self.physicsBody!.restitution = 0
    }
    
    convenience init(){
        self.init(radius: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
