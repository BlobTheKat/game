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
    var ship = true
    var landed = false
    var radius: CGFloat = 0
    var mass: CGFloat = 1
    var velocity: CGVector = CGVector()
    var angularVelocity: CGFloat = 0
    var particleOffset: Int = -1
    var producesParticles: Bool = false
    var particle = {() -> Particle in fatalError("particle() accessed before super.init call")}
    var asteroid: Asteroid{
        guard ship else { fatalError("Attempt to get asteroid value from non-asteroid object") }
        return self as! Asteroid
    }
    var particleDelay = 5
    init(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture = SKTexture()){
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.body(radius: radius, mass: mass)
        particle = { [self]() -> Particle in return Particle(type: "fire", position: CGPoint(x: position.x - velocity.dx, y: position.y - velocity.dy), velocity: CGVector(dx: velocity.dx + sin(zRotation) / 2, dy: velocity.dy - cos(zRotation) / 2), color: UIColor.yellow, size: CGSize(width: 10, height: 10), alpha: 0.9, decayRate: 0.01, spin: 0.05, sizedif: CGVector(dx: 0.1, dy: 0.1), endcolor: UIColor.red)}
    }
    func update(collisionNodes: ArraySlice<Ship>){
        if ship{
            self.angularVelocity *= 0.95
        }
        let parent = self.parent as? Play
        if producesParticles{
            particleOffset = (particleOffset + 1) % particleDelay
            if particleOffset == 0{
                parent?.particles.append(self.particle())
                parent?.addChild(parent?.particles.last! ?? self.particle())
            }
        }else{particleOffset = -1}
        velocity.dx *= 0.998
        velocity.dy *= 0.998
        for node in collisionNodes{
            let x = self.position.x - node.position.x
            let y = self.position.y - node.position.y
            let d = (x * x + y * y)
            if d < (self.radius + node.radius) * (self.radius + node.radius){
                //self and node collided
                //simplified elastic collision
                let dx = self.velocity.dx - node.velocity.dx
                let dy = self.velocity.dy - node.velocity.dx
                let m = node.mass / self.mass
                node.velocity.dx += 0.5 * dx / m
                node.velocity.dy += 0.5 * dy / m
                self.velocity.dx += (node.velocity.dx * m * -0.5 - dx)
                self.velocity.dy += (node.velocity.dy * m * -0.5 - dy)
                
                
            }
        }
        position.x += velocity.dx
        position.y += velocity.dy
        zRotation += angularVelocity
    }
    func body(radius: CGFloat, mass: CGFloat, texture: SKTexture? = nil){
        var m = mass
        if m == -1{
            m = radius * radius
        }
        self.mass = m
        self.radius = radius
        if let t = texture{
            self.texture = t
            self.size = t.size()
        }
        self.setScale(0.25)
    }
    
    convenience init(){
        self.init(radius: 0, mass: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
class Asteroid: Ship{
    override init(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture = SKTexture()){
        super.init(radius: radius, mass: mass, texture: texture)
        self.ship = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Planet: Ship{
    func update(){
        zRotation += angularVelocity
    }
    func gravity(_ n: Ship){
        let mass: CGFloat = self.mass
        let x = n.position.x - self.position.x
        let y = n.position.y - self.position.y
        let d = (x * x + y * y)
        var r = self.radius * self.radius - n.radius * n.radius
        r += (2 * sqrt(r) + n.radius) * n.radius
        if d < r - 1{
            if !n.ship{
                let parent = n.parent as? Play
                if parent != nil, let i = parent!.objects.firstIndex(of: n){
                    parent!.objects.remove(at: i)
                    n.run(SKAction.sequence([SKAction.fadeOut(withDuration: 1),SKAction.run{n.removeFromParent()}]))
                    n.run(SKAction.move(by: CGVector(dx: n.velocity.dx * CGFloat(parent!.gameFPS), dy: n.velocity.dy * CGFloat(parent!.gameFPS)), duration: 1))
                }
                
                return
            }
            //collided
            let m = sqrt(r / d) - 1
            n.position.x += x * m
            n.position.y += y * m
            n.velocity.dx = 0
            n.velocity.dy = 0
            n.angularVelocity = 0
            n.zRotation = atan2(y, x) - .pi/2
            n.landed = true
        }else if d <= r+2 && n.ship{
            n.zRotation += angularVelocity
            let t = atan2(x,y) - angularVelocity
            n.velocity = CGVector(dx: sin(t)*sqrt(d)-x, dy: cos(t)*sqrt(d)-y)
            //resting on planet
            n.landed = true
        }else{
            let m = -(mass*G)/d
            n.velocity.dx += x * m
            n.velocity.dy += y * m
            n.zRotation += angularVelocity * r / d
        }
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
class Particle: SKSpriteNode{
    var velocity: CGVector
    var type: String
    var decayRate: CGFloat
    var spin: CGFloat
    var sizedif: CGVector
    var coldelta: (r: CGFloat, g: CGFloat, b: CGFloat)
    init(type: String, position: CGPoint, velocity: CGVector, color: UIColor, size: CGSize, alpha: CGFloat, decayRate: CGFloat, spin: CGFloat, sizedif: CGVector, endcolor: UIColor){
        let lifetime = alpha / decayRate
        self.sizedif = sizedif
        var red = CGFloat()
        var green = CGFloat()
        var blue = CGFloat()
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        var red2 = CGFloat()
        var green2 = CGFloat()
        var blue2 = CGFloat()
        endcolor.getRed(&red2, green: &green2, blue: &blue2, alpha: nil)
        self.coldelta = (r: (red2 - red) / lifetime, g: (green2 - green) / lifetime, b: (blue2 - blue) / lifetime)
        self.type = type
        self.velocity = velocity
        self.decayRate = decayRate
        self.spin = spin
        super.init(texture: nil, color: color, size: size)
        self.alpha = alpha
        self.position = position
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func update(){
        self.position.x += velocity.dx
        self.position.y += velocity.dy
        self.alpha -= decayRate
        self.zRotation += spin
        self.size.width += sizedif.dx
        self.size.height += sizedif.dy
        var red = CGFloat()
        var green = CGFloat()
        var blue = CGFloat()
        self.color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        self.color = UIColor(red: red + coldelta.r, green: green + coldelta.g, blue: blue + coldelta.b, alpha: 1)
    }
}
