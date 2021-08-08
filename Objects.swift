//
//  Objects.swift
//  game
//
//  Created by BlobKat on 22/07/2021.
//

import Foundation
import SpriteKit

protocol DataCodable {
    func encode(data: inout Data)
    func decode(data: inout Data)
}

class Object: SKSpriteNode, DataCodable{
    var id = 0
    var dynamic = false
    var controls = false
    var thrust = false
    var thrustLeft = false
    var thrustRight = false
    var landed = false
    var radius: CGFloat = 0
    var mass: CGFloat = 1
    var velocity = CGVector()
    var thrustMultiplier: CGFloat = 1
    var angularThrustMultiplier: CGFloat = 1
    var angularVelocity: CGFloat = 0
    var particleOffset: Int = -1
    var producesParticles: Bool = false
    var particle = {() -> Particle in fatalError("particle() accessed before super.init call")}
    var asteroid: Bool
    func defParticle() -> Particle{
        return Particle(type: "fire", position: CGPoint(x: position.x, y: position.y), velocity: CGVector(dx: velocity.dx + sin(zRotation) / 2, dy: velocity.dy - cos(zRotation) / 2), color: UIColor.yellow, size: CGSize(width: 10, height: 10), alpha: 0.9, decayRate: 0.01, spin: 0.05, sizedif: CGVector(dx: 0.1, dy: 0.1), endcolor: UIColor.red)
    }
    var particleDelay = 5
    init(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture = SKTexture(), asteroid: Bool = false){
        self.asteroid = asteroid
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.body(radius: radius, mass: mass)
        particle = defParticle
        self.asteroid = asteroid
    }
    init(id: Int, asteroid: Bool){
        guard !asteroid else {fatalError("asteroids not yet implemented")}
        self.asteroid = false
        self.id = id
        let ship = ships.data[id]
        guard case .string(let t) = ship["texture"] else {fatalError("invalid texture")}
        super.init(texture: .named(t), color: UIColor.clear, size: t.size())
        guard case .number(let radius) = ship["radius"] else {fatalError("invalid radius")}
        guard case .number(let mass) = ship["mass"] else {fatalError("invalid mass")}
        self.body(radius: CGFloat(radius), mass: CGFloat(mass))
        particle = defParticle
    }
    func update(collisionNodes: ArraySlice<Object>){
        if !asteroid{
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
        if !asteroid{
            if velocity.dx > 10{velocity.dx *= 0.998}
            if velocity.dy > 10{velocity.dy *= 0.998}
        }
        for node in collisionNodes{
            let x = self.position.x - node.position.x
            let y = self.position.y - node.position.y
            let d = (x * x + y * y)
            if d < (self.radius + node.radius) * (self.radius + node.radius){
                //self and node collided
                //simplified elastic collision
                let sum = mass + node.mass
                let diff = mass - node.mass
                let newvelx = (velocity.dx * diff + (2 * node.mass * node.velocity.dx)) / sum
                let newvely = (velocity.dy * diff + (2 * node.mass * node.velocity.dy)) / sum
                node.velocity.dx = ((2 * mass * velocity.dx) - node.velocity.dx * diff) / sum
                node.velocity.dy = ((2 * mass * velocity.dy) - node.velocity.dy * diff) / sum
                velocity.dx = newvelx
                velocity.dy = newvely
            }
        }
        if controls{
            producesParticles = false
            if thrust{
                velocity.dx += -sin(zRotation) * thrustMultiplier / 30
                velocity.dy += cos(zRotation) * thrustMultiplier / 30
                producesParticles = true
            }
            if thrustLeft && thrustRight{thrustLeft = false; thrustRight = false}
            if thrustRight && !landed{
                angularVelocity -= 0.002 * angularThrustMultiplier
            }
            if thrustLeft && !landed{
                angularVelocity += 0.002 * angularThrustMultiplier
            }
        }
        position.x += velocity.dx
        position.y += velocity.dy
        zRotation += angularVelocity
    }
    func body(radius: CGFloat, mass: CGFloat, texture: SKTexture? = nil){
        zPosition = 1
        var m = mass
        if m == -1{
            m = radius * radius
        }
        self.mass = m
        self.radius = radius
        self.setScale(1)
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
    /*func decode(data: inout Data){
        self.body(radius: CGFloat(data.read() as Float), mass: CGFloat(data.read() as Float), texture: .from(data.read()))
        self.position = CGPoint(x: CGFloat(data.read() as Float), y: CGFloat(data.read() as Float))
        self.zRotation = CGFloat(data.read() as Float)
        self.velocity = CGVector(dx: CGFloat(data.read() as Float), dy: CGFloat(data.read() as Float))
        self.angularVelocity = CGFloat(data.read() as Float)
        self.thrustMultiplier = CGFloat(data.read() as Float)
        self.angularThrustMultiplier = CGFloat(data.read() as Float)
        let bits: UInt8 = data.read()
        thrust = bits & 1 != 0
        thrustLeft = bits & 2 != 0
        thrustRight = bits & 4 != 0
        asteroid = bits & 8 != 0
        landed = bits & 16 != 0
        producesParticles = bits & 32 != 0
        self.controls = true
        self.dynamic = true
    }
    func encode(data: inout Data){
        data.write(Float(self.radius))
        data.write(Float(self.mass))
        data.write(self.texture?.code() ?? 0)
        data.write(Float(self.position.x))
        data.write(Float(self.position.y))
        data.write(Float(self.zRotation))
        data.write(Float(self.velocity.dx))
        data.write(Float(self.velocity.dy))
        data.write(Float(self.angularVelocity))
        data.write(Float(self.thrustMultiplier))
        data.write(Float(self.angularThrustMultiplier))
        data.write(UInt8(thrust ? 1 : 0) + UInt8(thrustLeft ? 2 : 0) + UInt8(thrustRight ? 4 : 0) + UInt8(asteroid ? 8 : 0) + UInt8(landed ? 16 : 0) + UInt8(producesParticles ? 32 : 0))
    }*/
    func encode(data: inout Data){
        data.write(Float(self.position.x))
        data.write(Float(self.position.y))
        data.write(Float(self.velocity.dx))
        data.write(Float(self.velocity.dy))
        data.write(Int8(round((self.zRotation.remainder(dividingBy: .pi*2) + .pi*2).remainder(dividingBy: .pi*2) * 40)))
        data.write(UInt8(Int(self.angularVelocity * 768)&255))
        data.write(UInt16(thrust ? 1 : 0) + UInt16(thrustLeft ? 2 : 0) + UInt16(thrustRight ? 4 : 0) + UInt16(self.id * 8))
    }
    func decode(data: inout Data){
        self.position = CGPoint(x: CGFloat(data.read() as Float), y: CGFloat(data.read() as Float))
        self.velocity = CGVector(dx: CGFloat(data.read() as Float), dy: CGFloat(data.read() as Float))
        self.zRotation = CGFloat(data.read() as Int8) / 40
        self.angularVelocity = CGFloat(data.read() as Int8) / 768
        let bits: UInt16 = data.read()
        thrust = bits & 1 != 0
        thrustLeft = bits & 2 != 0
        thrustRight = bits & 4 != 0
        if thrustLeft && thrustRight{
            thrustLeft = false
            thrustRight = false
            asteroid = true
        }else if asteroid && (thrustLeft || thrustRight){
            asteroid = false
        }
        producesParticles = thrust
        self.id = Int(bits / 8)
        let ship = ships.data[id]
        guard case .string(let t) = ship["texture"] else {fatalError("invalid texture")}
        guard case .number(let radius) = ship["radius"] else {fatalError("invalid radius")}
        guard case .number(let mass) = ship["mass"] else {fatalError("invalid mass")}
        self.body(radius: CGFloat(radius), mass: CGFloat(mass), texture: .named(t))
        self.controls = true
        self.dynamic = true
    }
}

class Planet: Object{
    override init(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture = SKTexture(), asteroid: Bool = false){
        super.init(radius: radius, mass: mass, texture: texture, asteroid: asteroid)
    }
    func update(){
        zRotation += angularVelocity
    }
    func gravity(_ n: Object){
        guard n.dynamic else{return}
        n.landed = false
        let mass: CGFloat = self.mass
        let x = n.position.x - self.position.x
        let y = n.position.y - self.position.y
        let d = (x * x + y * y)
        var r = self.radius * self.radius - n.radius * n.radius
        r += (2 * sqrt(r) + n.radius) * n.radius
        if d < r - 1{
            if n.asteroid{
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
        }else if d <= r+2 && !n.asteroid{
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
    override func decode(data: inout Data) {
        body(radius: CGFloat(data.read() as Float), mass: CGFloat(data.read() as Float), texture: SKTexture(imageNamed: data.read()))
        self.position = CGPoint(x: CGFloat(data.read() as Float), y: CGFloat(data.read() as Float))
        self.zRotation = CGFloat(data.read() as Float)
        self.angularVelocity = CGFloat(data.read() as Float)
    }
    override func encode(data: inout Data) {
        data.write(Float(self.radius))
        data.write(Float(self.mass))
        data.write(self.texture?.code() ?? 0)
        data.write(Float(self.position.x))
        data.write(Float(self.position.y))
        data.write(Float(self.zRotation))
        data.write(Float(self.angularVelocity))
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class Ray{
    var position: CGPoint
    var direction: CGFloat
    init(position: CGPoint, direction: CGFloat){
        self.position = position
        self.direction = direction
    }
    func intersects(_ n: Object) -> Bool{
        let x = n.position.x - self.position.x
        let y = n.position.y - self.position.y
        let ang = atan2(y, x)
        let width = atan(n.radius / sqrt(x*x + y*y))
        let a = abs(ang - self.direction)
        return a < width || a > .pi*2 - width
    }
}
class Particle: SKSpriteNode{
    private var onupdate = {(_: Particle) -> () in}
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
    func updates(a: @escaping (Particle) -> ()) -> Particle{
        self.onupdate = a
        return self
    }
    func update(){
        self.onupdate(self)
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
        self.color = UIColor(red: (red + coldelta.r).clamp(0, 1), green: (green + coldelta.g).clamp(0, 1), blue: (blue + coldelta.b).clamp(0, 1), alpha: 1)
    }
}

extension Comparable{
    @inlinable func clamp(_ a: Self, _ b: Self) -> Self{
        return min(max(self, a), b)
    }
}
