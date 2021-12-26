//
//  Object.swift
//  game
//
//  Created by Matthew on 15/12/2021.
//

import Foundation
import SpriteKit

class Object: SKSpriteNode, DataCodable{
    
    //id: ID indicating the behaviour set of this object
    var id = 0
    //Is an asteroid?
    var asteroid: Bool
    
    //Particle Variables
    var producesParticles: Bool = false
    var particleFrequency = 0.2
    var particleQueue = 1.0 //Technical variable for calculating when to create a particle
    
    //Obeys the laws of physics. If turned off, the object will simply hang there and do absolutely nothing
    var dynamic = false
    
    //Control variables
    var thrust = false
    var thrustLeft = false
    var thrustRight = false
    
    //Whether the object can be controlled by thrust, thrustLeft, thrustRight, etc...
    var controls = false
    
    //Is the object landed on a Planet? (only applicable to ships)
    var landed = false
    
    //Radius, mass and speed vector of this object's physics
    var radius: CGFloat = 0
    var mass: CGFloat = 1
    
    //Speed for movement and rotation
    var velocity = CGVector()
    var angularVelocity: CGFloat = 0
    
    //Multipliers to make thrust and turning faster
    var thrustMultiplier: CGFloat = 1
    var angularThrustMultiplier: CGFloat = 1
    
    //Variables that control shooting
    var shootPoints: [CGPoint] = [] //Array of positions relative to this sprite
    var shootVectors: [CGFloat] = [] //Array of zRotations
    var shootDamages: [CGFloat] = [] //Array of numbers
    var shootFrequency: CGFloat = 0
    var shootQueue: CGFloat = 0 //Technical variable for calculating when to shoot
    
    //Technical variable that indicated the number of remaining shots that will be aimbotted to the player's ship
    var shlock: Int = 0
    
    //Variable for custom particles, initialized to a placeholder function
    var particle = {(_:Object) -> Particle in fatalError("particle() has not been defined")}
    //Technical variable. Used for figuring out what killed the ship (when it dies)
    var death: UInt16 = 0
    //floating name
    var namelabel: SKLabelNode? = nil
    //Default particle (the red-yellow one)
    class func defaultParticle(_ ship: Object) -> Particle{
        let start = State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: ship.position, alpha: 0.9)
        let endpos = CGPoint(x: ship.position.x + ship.velocity.dx * gameFPS * 1.5 + sin(ship.zRotation) * gameFPS * 0.75, y: ship.position.y + ship.velocity.dy * gameFPS * 1.5 - cos(ship.zRotation) * gameFPS * 0.75)
        let end = State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 20, height: 20), zRot: 5, position: endpos, alpha: 0, delay: TimeInterval(1.5))
        return Particle(states: [start, end])!
    }
    init(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture = SKTexture(), asteroid: Bool = false){
        self.asteroid = asteroid
        super.init(texture: nil, color: UIColor.clear, size: CGSize.zero)
        self.body(radius: radius, mass: mass, texture: texture)
        particle = Object.defaultParticle
        self.asteroid = asteroid
    }
    func update(){
        if !asteroid{ //asteroids don't slow down
            self.angularVelocity *= 0.95
            if abs(velocity.dx) > 10{velocity.dx *= 0.997}
            if abs(velocity.dy) > 10{velocity.dy *= 0.997}
        }
        let parent = self.parent as? Play
        
        if let cam = parent?.camera{
            //calculate cam position so we only create a particle if it's in the scene
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
        //move
        position.x += velocity.dx
        position.y += velocity.dy
        zRotation += angularVelocity
        //death timer
        if self.death > 0{
            self.death -= 1
            if self.death % 100 == 0{
                self.death = 0
            }
        }
        shoot()
    }
    //checks whether it should shoot, and shoots if yes
    func shoot(){
        guard let parent = (parent as? Play) else{return}
        shootQueue += shootFrequency
        var i = 0
        while shootQueue > 1{
            let x = self.position.x - parent.cam.position.x
            let y = self.position.y - parent.cam.position.y
            if x * x + y * y <= 3e6{
                self.run(parent.shootSound)
                if self == parent.ship{parent.vibratePhone(.heavy)}
            }
            if shlock > 0{
                zRotation = -atan2(parent.ship.position.x - position.x, parent.ship.position.y - position.y)
                shlock -= 1
            }
            for p in shootPoints{
                var v: CGFloat = 0
                if i < shootVectors.count{v = shootVectors[i]}
                let bullet = SKSpriteNode(imageNamed: "bullet")
                let d = sqrt(p.x * p.x + p.y * p.y)
                let r = atan2(p.x, -p.y) + self.zRotation
                bullet.position = CGPoint(x: self.position.x + sin(r) * d, y: self.position.y - cos(r) * d)
                bullet.zPosition = 1
                bullet.setScale(0.2)
                bullet.zRotation = self.zRotation + v
                parent.addChild(bullet)
                var dx = self.velocity.dx / 25 - sin(bullet.zRotation)
                var dy = self.velocity.dy / 25 + cos(bullet.zRotation)
                let div = sqrt(dx * dx + dy * dy)
                dx /= div
                dy /= div
                let (obj: obj, len: len, planet: planet) = raylength(objs: parent.planets, objs2: parent.objects, rayorigin: bullet.position, raydir: CGVector(dx: dx, dy: dy), this: position)
                if let obj = obj{
                    //obj wasShot
                    obj.death = 200
                    var damage = 5.0
                    if i < shootDamages.count{damage = shootDamages[i]}
                    if obj == parent.ship{
                        let _ = timeout((len - 10) / 1500){
                            if parent.health > damage{
                                parent.health -= damage
                                let ratio = parent.health / parent.maxHealth
                                if ratio < 0.25{
                                    if parent.warningLabel.parent == nil{
                                        parent.DisplayWARNING("warning: low health",1,true)
                                    }
                                }
                                parent.healthBar.texture = SKTexture(imageNamed: "health\(Int8(round(ratio * 13)))")
                                self.run(SKAction.sequence([
                                    SKAction.run{
                                        let cam = parent.cam
                                        vibrateCamera(camera: cam, amount: 5)
                                    },
                                    SKAction.wait(forDuration: 0.5),
                                    SKAction.run {
                                        parent.cam.removeAction(forKey: "vibratingCamera")
                                        parent.cam.removeAction(forKey: "vibratingCameras")
                                    }
                                ]))
                            }else if parent.ship.dynamic{
                                parent.health = 0
                                parent.healthBar.texture = SKTexture(imageNamed: "health0")
                                self.death = 200
                                parent.kill(parent.ship)
                                parent.ship.removeFromParent()
                                parent.ship.controls = false
                                parent.ship.dynamic = false
                                let _ = timeout(1){
                                    parent.end()
                                    parent.stars1.removeFromParent()
                                    parent.stars2.removeFromParent()
                                    parent.stars3.removeFromParent()
                                    SKScene.transition = .crossFade(withDuration: 0.5)
                                    PlayerDied.renderTo(skview)
                                    SKScene.transition = .crossFade(withDuration: 0)
                                }
                            }
                        }
                        //code above DIE if you get hit
                    }else{
                        //IF ITS NOT A SHIP
                        parent.shotObj = obj
                    }
                }
                let sdx = parent.ship.position.x - (planet?.position.x ?? .infinity)
                let sdy = parent.ship.position.y - (planet?.position.y ?? .infinity)
                if let planet = planet, !planet.superhot && sdx * sdx + sdy * sdy < planet.radius * planet.radius * 16{
                    //planet was shot, it's not a star and we're in range
                    planet.emitq += planet.emitf * 2
                    while planet.emitq > 1{
                        planet.emit(randDir(planet.radius - 50))
                        planet.emitq -= 1
                        let cam = parent.cam
                        vibrateCamera(camera: cam, amount: 5)
                        let _ = timeout(0.5){
                            cam.removeAction(forKey: "vibratingCamera")
                            cam.removeAction(forKey: "vibratingCameras")
                        }
                    }
                    
                }
                //tricky algorithm to make shooting easier
                let count = (len / 2 - 20) * gameFPS / 1500
                let o = obj ?? self
                var offsetx = bullet.position.x - o.position.x
                var offsety = bullet.position.y - o.position.y
                bullet.run(.sequence([SKAction.repeat(SKAction.sequence([SKAction.wait(forDuration: 2 / gameFPS), SKAction.run{
                    offsetx += dx * (len - 40) / count
                    offsety += dy * (len - 40) / count
                    bullet.position.x = offsetx + o.position.x
                    bullet.position.y = offsety + o.position.y
                }]), count: Int(count)), SKAction.run{bullet.removeFromParent()}]))
                i += 1
            }
            shootQueue -= 1
        }
    }
    //change the physics and texture of the planet
    func body(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture? = nil){
        self.zPosition = 2
        self.mass = mass == -1 ? radius * radius : mass
        self.radius = radius
        self.setScale(1)
        if texture != nil{
            self.texture = texture!
            self.texture!.filteringMode = .nearest
            self.size = texture!.size()
        }
        self.setScale(0.5)
    }
    convenience init(){ self.init(radius: 0, mass: 0) }
    required init?(coder aDecoder: NSCoder){ fatalError("init(coder:) has not been implemented") }
    func encode(data: inout Data){
        //See server protocol for more insight
        if self.id == 0{
            data.write(Int64(0))
            data.write(Int32(0))
            data.write(Int16(0))
            return
        }
        data.write(Float(self.position.x))
        data.write(Float(self.position.y))
        data.write(Int8(round(self.velocity.dx * gameFPS / 16).clamp(-128, 127)))
        data.write(Int8(round(self.velocity.dy * gameFPS / 16).clamp(-128, 127)))
        data.write(Int8(round(self.zRotation.remainder(dividingBy: .pi*2) * 40)))
        data.write(Int8(round(self.angularVelocity * 768)))
        let new = (parent as? Play)?.newShoot ?? false
        data.write(UInt16(thrust ? 1 : 0) + UInt16(thrustLeft ? 2 : 0) + UInt16(thrustRight ? 4 : 0) + UInt16(((parent as? Play)?.usedShoot ?? false) && !new ? 8 : 0) + UInt16(new ? 16 : 0) + UInt16(self.id * 32))
    }
    
    func decode(data: inout Data){
        //See server protocol for more insight
        let pos = CGPoint(x: CGFloat(data.readunsafe() as Float), y: CGFloat(data.readunsafe() as Float))
        self.velocity = CGVector(dx: CGFloat(data.readunsafe() as Int8) / gameFPS * 16, dy: CGFloat(data.readunsafe() as Int8) / gameFPS * 16)
        self.zRotation = CGFloat(data.readunsafe() as Int8) / 40
        self.angularVelocity = CGFloat(data.readunsafe() as Int8) / 768
        let bits: UInt16 = data.readunsafe()
        let oa = asteroid
        thrust = bits & 1 != 0
        thrustLeft = bits & 2 != 0
        thrustRight = bits & 4 != 0
        var shoot = bits & 8 != 0
        let sadd = Int((bits & 16) / 16)
        if sadd == 1 && !shoot{
            self.shootQueue = 1
            shoot = true
        }else if sadd == 1{self.shlock += sadd}
        if !asteroid && thrustLeft && thrustRight{
            thrustLeft = false
            thrustRight = false
            asteroid = true
        }else if asteroid && !(thrustLeft && thrustRight){
            asteroid = false
        }
        producesParticles = thrust
        if !asteroid && id > 0{
            if case .number(let f) = ships[self.id]["shootspeed"]{
                self.shootFrequency = shoot ? f : 0
            }
        }
        let id = Int(bits / 32)
        if id != 0{self.position = pos}
        if id != self.id || oa != asteroid{
            self.id = id
            (skview.scene as? Play)?.needsName = id != 0 && !asteroid && namelabel == nil
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
