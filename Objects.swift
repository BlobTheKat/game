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
var d: [Int: Int] = [:]
class Object: SKSpriteNode, DataCodable{
    var shootPoints: [CGPoint] = []
    var shootVectors = {(_:CGFloat) -> [CGVector] in return []}
    var shootQueue: CGFloat = 0
    var shootFrequency: CGFloat = 0
    var state: UInt8 = 0
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
    var particleQueue = 1.0
    var producesParticles: Bool = false
    var shlock: Int = 0
    var particle = {(_:Object) -> Particle in fatalError("particle() accessed before super.init call")}
    var asteroid: Bool
    func defParticle(_ ship: Object) -> Particle{
        let d: CGFloat = CGFloat(1.5 * gameFPS)
        let start = State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: ship.position, alpha: 0.9)
        let endpos = CGPoint(x: ship.position.x + ship.velocity.dx * d + sin(zRotation) * d / 2, y: ship.position.y + ship.velocity.dy * d - cos(zRotation) * d / 2)
        let end = State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 20, height: 20), zRot: 5, position: endpos, alpha: 0, delay: TimeInterval(d) / gameFPS)
        return Particle(states: [start, end])!
    }
    var particleFrequency = 0.2
    init(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture = SKTexture(), asteroid: Bool = false){
        self.asteroid = asteroid
        super.init(texture: nil, color: UIColor.clear, size: CGSize.zero)
        self.body(radius: radius, mass: mass, texture: texture)
        particle = defParticle
        self.asteroid = asteroid
    }
    func update(){
        if !asteroid{
            self.angularVelocity *= 0.95
        }
        let parent = self.parent as? Play
        if let cam = parent?.camera{
            let cw = parent!.size.width * cam.xScale / 2
            let ch = parent!.size.height * cam.yScale / 2
            let cpos = cam.position
            let r = 1.25 * radius
            if producesParticles && (position.x + r > cpos.x - cw && position.x - r < cpos.x + cw) && (position.y + r > cpos.y - ch && position.y - r < cpos.y + ch){
                particleQueue += particleFrequency
                while particleQueue >= 1{
                    if parent != nil{
                        parent!.particles.append(self.particle(self))
                        parent!.addChild(parent!.particles.last!)
                    }
                    particleQueue -= 1
                }
            }else{particleQueue = 1}
        }
        if !asteroid{
            if abs(velocity.dx) > 10{velocity.dx *= 0.99}
            if abs(velocity.dy) > 10{velocity.dy *= 0.99}
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
        var i = 0
        guard let parent = parent else{return}
        shootQueue += shootFrequency
        if shlock != 0{
            zRotation = -atan2(parent.ship.position.x - position.x, parent.ship.position.y - position.y)
        }
        let shootVectors = shootVectors(self.zRotation)
        while shootQueue > 1{
            for p in shootPoints{
                var v = CGVector.zero
                if i < shootVectors.count{v = shootVectors[i]}
                let bullet = SKSpriteNode(imageNamed: "bullet")
                bullet.position = CGPoint(x: self.position.x, y: self.position.y)
                bullet.zPosition = 4
                bullet.anchorPoint = CGPoint(x: -p.x, y: -p.y)
                bullet.setScale(0.2)
                bullet.zRotation = self.zRotation
                parent.addChild(bullet)
                bullet.run(SKAction.moveBy(x: self.velocity.dx * CGFloat(gameFPS) + v.dx , y: self.velocity.dy * CGFloat(gameFPS) + v.dy, duration: 1).ease(.easeOut))
                bullet.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.8),
                    SKAction.fadeAlpha(to: 0, duration: 0.2),
                    SKAction.run{bullet.removeFromParent()}
                ]))
                i += 1
            }
            shootQueue -= 1
        }
    }
    func body(radius: CGFloat, mass: CGFloat, texture: SKTexture? = nil){
        zPosition = 1
        var m = mass
        if m == -1{
            m = radius * radius
        }
        self.mass = m
        self.radius = radius
        setScale(1)
        if texture != nil{
            self.texture = texture!
            self.texture!.filteringMode = .nearest
            self.size = texture!.size()
        }
        setScale(0.5)
    }
    convenience init(){
        self.init(radius: 0, mass: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func encode(data: inout Data){
        if self.id == 0{
            data.write(Int64(0))
            data.write(Int64(0))
            data.write(Int32(0))
            return
        }
        data.write(Float(self.position.x))
        data.write(Float(self.position.y))
        data.write(Float(self.velocity.dx))
        data.write(Float(self.velocity.dy))
        data.write(Int8(round((self.zRotation.remainder(dividingBy: .pi*2) + .pi*2).remainder(dividingBy: .pi*2) * 40)))
        data.write(UInt8(Int(self.angularVelocity * 768)&255))
        
        data.write(UInt16(thrust ? 1 : 0) + UInt16(thrustLeft ? 2 : 0) + UInt16(thrustRight ? 4 : 0) + UInt16(shootFrequency != 0 ? 8 : 0) + UInt16(self.id * 32))
    }
    func decode(data: inout Data){
        self.position = CGPoint(x: CGFloat(data.readunsafe() as Float), y: CGFloat(data.readunsafe() as Float))
        self.velocity = CGVector(dx: CGFloat(data.readunsafe() as Float), dy: CGFloat(data.readunsafe() as Float))
        self.zRotation = CGFloat(data.readunsafe() as Int8) / 40
        self.angularVelocity = CGFloat(data.readunsafe() as Int8) / 768
        let bits: UInt16 = data.readunsafe()
        let oa = asteroid
        thrust = bits & 1 != 0
        thrustLeft = bits & 2 != 0
        thrustRight = bits & 4 != 0
        let shoot = bits & 8 != 0
        self.shlock += Int((bits & 16) / 16)
        if !asteroid && thrustLeft && thrustRight{
            thrustLeft = false
            thrustRight = false
            asteroid = true
        }else if asteroid && !(thrustLeft && thrustRight){
            asteroid = false
        }
        producesParticles = thrust
        if !asteroid && id > 0{
            self.shootFrequency = shoot ? SHOOTFREQUENCIES[id-1] : 0
        }
        let id = Int(bits / 32)
        if id != self.id || oa != asteroid{
            self.id = id
            let ship = (asteroid ? asteroids : ships)[id]
            guard case .string(let t) = ship["texture"] else {fatalError("invalid texture")}
            guard case .number(let radius) = ship["radius"] else {fatalError("invalid radius")}
            guard case .number(let mass) = ship["mass"] else {fatalError("invalid mass")}
            self.body(radius: CGFloat(radius), mass: CGFloat(mass), texture: SKTexture(imageNamed: t))
            if !asteroid && id > 0{
                self.shootPoints = SHOOTPOINTS[id-1]
                self.shootVectors = SHOOTVECTORS[id-1]
            }
        }
        self.controls = !asteroid
        self.dynamic = true
    }
}

class Planet: Object{
    override func body(radius: CGFloat, mass: CGFloat, texture: SKTexture? = nil){
        zPosition = 1
        var m = mass
        if m == -1{
            m = radius * radius
        }
        self.mass = m
        self.radius = radius
        if texture != nil{
            self.texture = texture!
            self.texture!.filteringMode = .nearest
            self.size = texture!.size()
        }
    }
    var superhot = false
    override func defParticle(_ planet: Object) -> Particle{
        return Particle()
    }
    override func update() {}
    func update(_ node: SKSpriteNode?){
        //let node: SKSpriteNode? = nil
        if let i = node{
            guard let parent = parent as? Play else{return}
            guard let cam = parent.camera else {return}
            let size = CGSize(width: size.width / cam.xScale, height: size.height / cam.yScale)
            let frame = CGRect(origin: CGPoint(x: -parent.size.width / 2, y: -parent.size.height / 2), size: parent.size)
            let dx = (self.position.x - cam.position.x) / cam.xScale
            let dy = (self.position.y - cam.position.y) / cam.yScale
            if dx < frame.minX - size.width / 2 || dx > frame.maxX + size.width / 2 || dy < frame.minY - size.height / 2 || dy > frame.maxY + size.height / 2{
                let camw = frame.width / 2// - i.size.width
                let camh = frame.height / 2// - i.size.height
                if abs(dy / dx) > camh / camw{
                    //anchor top/bottom
                    i.position.x = (dx * camh / abs(dy))
                    i.position.y = (dy > 0 ? camh : -camh)
                }else{
                    //anchor left/right
                    i.position.y = (dy * camw / abs(dx))
                    i.position.x = (dx > 0 ? camw : -camw)
                }
                i.zRotation = -atan2(dx, dy)
                if i.parent == nil{cam.addChild(i)}
            }else if i.parent != nil{i.removeFromParent()}
        }
        let parent = self.parent as? Play
        if let cam = parent?.camera{
            let cw = parent!.size.width * cam.xScale / 2
            let ch = parent!.size.height * cam.yScale / 2
            let cpos = cam.position
            let r = 1.25 * radius
            if producesParticles && (position.x + r > cpos.x - cw && position.x - r < cpos.x + cw) && (position.y + r > cpos.y - ch && position.y - r < cpos.y + ch){
                particleQueue += particleFrequency
                while particleQueue >= 1{
                    if parent != nil{
                        parent!.particles.append(self.particle(self))
                        parent!.addChild(parent!.particles.last!)
                    }
                    particleQueue -= 1
                }
            }else{particleQueue = 1}
        }
        zRotation += angularVelocity
    }
    func gravity(_ n: Object){
    
        guard n.dynamic else{return}
        n.landed = false
        let mass: CGFloat = self.mass
        let x = n.position.x - self.position.x
        let y = n.position.y - self.position.y
        let d = x * x + y * y
        var r = self.radius * self.radius - n.radius * n.radius
        if r < 0{r=0}
        r += (2 * sqrt(r) + n.radius) * n.radius
        let deathzone = mass * mass * G * G / d > n.thrustMultiplier * n.thrustMultiplier / 900
        if d < r - radius{
            if n.asteroid || deathzone || superhot{
                let parent = n.parent as? Play
                if parent != nil{
                    n.dynamic = false
                    n.controls = false
                    if let parent = (n.parent as? Play), let i = parent.objects.firstIndex(of: n){
                        parent.objects[i] = Object()
                    }
                    n.run(SKAction.sequence([SKAction.fadeOut(withDuration: 1),SKAction.run{n.removeFromParent()
                        if n == parent!.ship{
                            parent!.send(Data([127]))
                            DispatchQueue.main.async{SKScene.transition = .crossFade(withDuration: 0.5);PlayerDied.renderTo(skview);SKScene.transition = .crossFade(withDuration: 0);}
                        }
                    }]))
                    n.run(SKAction.move(by: CGVector(dx: n.velocity.dx * CGFloat(gameFPS), dy: CGFloat(n.velocity.dy) * CGFloat(gameFPS)), duration: 1))
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
        }else if d <= r + radius && !n.asteroid && !deathzone && !superhot{
            if n.landed{
                n.zRotation += angularVelocity
            }else{
                n.zRotation = atan2(y, x) - .pi/2
            }
            let t = atan2(x,y) - angularVelocity
            n.velocity = CGVector(dx: sin(t)*sqrt(d)-x, dy: cos(t)*sqrt(d)-y)
            //resting on planet
            n.landed = true
            let parents = parent as? Play
            if parents != nil && n == parents!.ship{
                let circle = parents!.planetsMP[parents!.planets.firstIndex(of: self)!]
                circle.fillColor = UIColor.green
                parents?.playerArrow.removeFromParent()
                //GANGE MAP HERE
            }
        }else{
            let parents = parent as? Play
            if parents != nil && n == parents!.ship{
                let circle = parents!.planetsMP[parents!.planets.firstIndex(of: self)!]
                circle.fillColor = UIColor.white
                //GANGE MAP HERE
                if parents?.playerArrow.parent == nil{
                    parents!.mainMap.addChild(parents!.playerArrow)
                }
            }
            if deathzone && !superhot{
                let parent = n.parent as? Play
                if parent != nil{
                    n.dynamic = false
                    n.controls = false
                    if let parent = (n.parent as? Play), let i = parent.objects.firstIndex(of: n){
                        parent.objects[i] = Object()
                    }
                    n.run(SKAction.sequence([SKAction.fadeOut(withDuration: 1),SKAction.run{n.removeFromParent()
                        if n == parent!.ship{
                            parent!.send(Data([127]))
                            DispatchQueue.main.async{SKScene.transition = .crossFade(withDuration: 0.5);PlayerDied.renderTo(skview);SKScene.transition = .crossFade(withDuration: 0);}
                        }
                    }]))
                    n.run(SKAction.move(by: CGVector(dx: n.velocity.dx * CGFloat(gameFPS), dy: CGFloat(n.velocity.dy) * CGFloat(gameFPS)), duration: 1))
                }
                return
            }
            let M = mass * G
            let m = min(M / (16 * r) - M / d, 0)
            n.velocity.dx += x * m
            n.velocity.dy += y * m
            n.zRotation += angularVelocity * r / d
        }
    }
    override func decode(data: inout Data) {
        body(radius: CGFloat(data.readunsafe() as Float), mass: CGFloat(data.readunsafe() as Float), texture: SKTexture(imageNamed: data.readunsafe()))
        self.position = CGPoint(x: CGFloat(data.readunsafe() as Float), y: CGFloat(data.readunsafe() as Float))
        self.zRotation = CGFloat(data.readunsafe() as Float)
        self.angularVelocity = CGFloat(data.readunsafe() as Float)
    }
    override func encode(data: inout Data) {
        data.write(Float(self.radius))
        data.write(Float(self.mass))
        //data.write(self.texture?.code() ?? 0)
        data.write(Float(self.position.x))
        data.write(Float(self.position.y))
        data.write(Float(self.zRotation))
        data.write(Float(self.angularVelocity))
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
    var states: [State]
    var delta = State.zero
    @inline(__always) static subscript(_ a: State...) -> Particle{
        return Particle(states: a) ?? Particle()
    }
    init?(states: [State]){
        self.states = states
        super.init(texture: nil, color: UIColor.clear, size: CGSize.zero)
        if nextState(){return nil}
    }
    init(){
        self.states = []
        super.init(texture: nil, color: UIColor.clear, size: CGSize.zero)
    }
    func nextState() -> Bool{
        if states.count < 1{
            return true
        }
        let state = states.removeFirst()
        delta = (state - State.of(node: self)) / CGFloat(state.delay * gameFPS)
        delta.delay = state.delay
        if delta.delay < 0.5 / gameFPS{
            state.apply(to: self)
            return nextState()
        }
        return false
    }
    func update() -> Bool{
        delta.add(to: self)
        delta.delay -= 1 / gameFPS
        if delta.delay < 0.5 / gameFPS{
            return nextState()
        }
        return false
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct State{
    static let zero = State(color: (r: 0, g: 0, b: 0), size: CGSize.zero, zRot: 0, position: CGPoint.zero, alpha: 0)
    var color: (r: CGFloat, g: CGFloat, b: CGFloat)
    var size: CGSize
    var zRot: CGFloat
    var position: CGPoint
    var alpha: CGFloat
    var delay: TimeInterval = 0
    func delta(to state: State) -> State{
        return State(color: (r: state.color.r - self.color.r, g: state.color.g - self.color.g, b: state.color.b - self.color.b), size: CGSize(width: state.size.width - self.size.width, height: state.size.height - self.size.height), zRot: state.zRot - self.zRot, position: CGPoint(x: state.position.x - self.position.x, y: state.position.y - self.position.y), alpha: state.alpha - self.alpha)
    }
    static func -(_ state: State, _ this: State) -> State{
        return State(color: (r: state.color.r - this.color.r, g: state.color.g - this.color.g, b: state.color.b - this.color.b), size: CGSize(width: state.size.width - this.size.width, height: state.size.height - this.size.height), zRot: state.zRot - this.zRot, position: CGPoint(x: state.position.x - this.position.x, y: state.position.y - this.position.y), alpha: state.alpha - this.alpha)
    }
    static func /(_ this: State, _ d: CGFloat) -> State{
        return State(color: (r: this.color.r / d, g: this.color.g / d, b: this.color.b / d), size: CGSize(width: this.size.width / d, height: this.size.height / d), zRot: this.zRot / d, position: CGPoint(x: this.position.x / d, y: this.position.y / d), alpha: this.alpha / d)
    }
    static func +(_ a: State, _ b: State) -> State{
        return State(color: (r: a.color.r + b.color.r, g: a.color.g + b.color.g, b: a.color.b + b.color.b), size: CGSize(width: a.size.width + b.size.width, height: a.size.height + b.size.height), zRot: a.zRot + b.zRot, position: CGPoint(x: a.position.x + b.position.x, y: a.position.y + b.position.y), alpha: a.alpha + b.alpha)
    }
    static func +=(_ this: inout State, _ state: State){
        this.color.r += state.color.r
        this.color.g += state.color.g
        this.color.b += state.color.b
        this.size.width += state.size.width
        this.size.height += state.size.height
        this.zRot += state.zRot
        this.position.x += state.position.x
        this.position.y += state.position.y
        this.alpha += state.alpha
    }
    var uicolor: UIColor{
        return UIColor(red: self.color.r, green: self.color.g, blue: self.color.b, alpha: 1)
    }
    var debugDescription: String{
        return "(\(String(format:"%02X", color.r) + String(format:"%02X", color.g) + String(format:"%02X", color.b) + ", " + String(format:"%02X", Int(alpha * 255)))) [\(size.width)x\(size.height)] (x: \(position.x), y: \(position.y), z: \(zRot))"
    }
    func apply(to node: SKSpriteNode){
        node.alpha = alpha
        node.color = uicolor
        node.size = size
        node.zRotation = zRot
        node.position = position
    }
    func add(to node: SKSpriteNode){
        
        node.alpha += alpha
        var red = CGFloat()
        var green = CGFloat()
        var blue = CGFloat()
        node.color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        node.color = UIColor(red: red + color.r, green: green + color.g, blue: blue + color.b, alpha: 1)
        node.size.width += size.width
        node.size.height += size.height
        node.zRotation += zRot
        node.position.x += position.x
        node.position.y += position.y
        
    }
    static func of(node: SKSpriteNode) -> State{
        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        node.color.getRed(&r, green: &g, blue: &b, alpha: nil)
        return State(color: (r: r, g: g, b: b), size: node.size, zRot: node.zRotation, position: node.position, alpha: node.alpha)
    }
}
