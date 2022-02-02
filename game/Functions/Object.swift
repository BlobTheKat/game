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
    var controls = true
    
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
    var particleOffset: CGFloat = 0
    //Technical variable that indicated the number of remaining shots that will be aimbotted to the player's ship
    var shlock: Int = 0
    
    //Variable for custom particles, initialized to a placeholder function
    var particle = {(_:Object) -> Particle in fatalError("particle() has not been defined")}
    //Technical variable. Used for figuring out what killed the ship (when it dies)
    //1-299: died from planet
    //301-599: died from another player/planet's bullets
    //601-899: died from player (used for awarding kills)
    var death: UInt16 = 0
    var asteroidDeathNote: Bool = false
    //floating name
    var namelabel: SKLabelNode? = nil
    var badgeNode: SKSpriteNode? = nil
    var target: (pos: CGPoint, vel: CGVector, z: CGFloat, dz: CGFloat)? = nil
    //Default particle (the red-yellow one)
    class func defaultParticle(_ ship: Object) -> Particle{
        var p = ship.position
        let c = cos(ship.zRotation), s = sin(ship.zRotation)
        p.x += c * ship.particleOffset + s * 7
        p.y += s * ship.particleOffset - c * 7
        
        let start = State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: p, alpha: 0.9)
        let endpos = CGPoint(x: p.x + ship.velocity.dx * gameFPS * 1.5 + sin(ship.zRotation) * gameFPS * 0.75, y: p.y + ship.velocity.dy * gameFPS * 1.5 - cos(ship.zRotation) * gameFPS * 0.75)
        
        let end = State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 20, height: 20), zRot: 5, position: endpos, alpha: 0, delay: TimeInterval(1.5))
        return Particle(states: [start, end])!
    }
    init(radius: CGFloat, mass: CGFloat = -1, texture: SKTexture = SKTexture(), asteroid: Bool = false){
        self.asteroid = asteroid
        super.init(texture: nil, color: UIColor.clear, size: CGSize.zero)
        self.body(radius: radius, mass: mass, texture: texture)
        particle = Object.defaultParticle
    }
    func update(){
        
    
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
        
        if target != nil{
            (position, target!.pos) = (target!.pos, position)
            (velocity, target!.vel) = (target!.vel, velocity)
            (zRotation, target!.z) = (target!.z, zRotation)
            (angularVelocity, target!.dz) = (target!.dz, angularVelocity)
        }
        if !asteroid{ //asteroids don't slow down
            self.angularVelocity *= 0.95
            if abs(velocity.dx) > 10{velocity.dx *= 0.997}
            if abs(velocity.dy) > 10{velocity.dy *= 0.997}
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
            if self.death % 300 == 0{
                self.death = 0
            }
        }
        shoot()
        if target != nil{
            (position, target!.pos) = (target!.pos, position)
            (velocity, target!.vel) = (target!.vel, velocity)
            (zRotation, target!.z) = (target!.z, zRotation)
            (angularVelocity, target!.dz) = (target!.dz, angularVelocity)
            position = (position * 9 + target!.pos) / 10
            velocity = (velocity * 9 + target!.vel) / 10
            let zdif = (target!.z - zRotation)
            zRotation += zdif.remainder(dividingBy: .pi * 2) / 4
            angularVelocity = (angularVelocity * 9 + target!.dz) / 10
            
        }
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
                let v: CGFloat = i < shootVectors.count ? shootVectors[i] : 0
                let damage = i < shootDamages.count ? shootDamages[i] : 5.0
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
                    obj.death = 600
                    if obj == parent.ship{
                        let _ = timeout((len - 10) / 1500){
                            parent.dealDamage(damage)
                        }
                        //code above DIE if you get hit
                    }else if self == parent.ship{
                        //IF IM A SHIP AND NOT IT
                        parent.shotObj = obj
                        obj.death = 900 //wasShot by me
                    }
                }
                let sdx = parent.ship.position.x - (planet?.position.x ?? .infinity)
                let sdy = parent.ship.position.y - (planet?.position.y ?? .infinity)
                if let planet = planet, !planet.superhot && sdx * sdx + sdy * sdy < planet.radius * planet.radius * 16 && planet.ownedState != .yours{
                    //planet was shot, it's not a star and we're in range
                    planet.emitq += damage * planet.emitf / 3
                    while planet.emitq > 1{
                        planet.emit(randDir(planet.radius - 50))
                        if self == parent.ship{planet.angry = 1800;parent.planetShot = planet}
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
        self.zPosition = 7
        self.mass = mass == -1 ? radius * radius : mass
        self.radius = radius
        self.setScale(1)
        if texture != nil{
            self.texture = texture!
            self.size = texture!.size()
        }
        self.setScale(asteroid ? 0.5 : 0.25)
    }
    convenience init(){ self.init(radius: 0, mass: 0) }
    required init?(coder aDecoder: NSCoder){ fatalError("init(coder:) has not been implemented") }
    func encode(data: inout Data){
        //See server protocol for more insight
        if self.id == 0{
            data.write(Int64(0))
            data.write(Int64(0))
            return
        }
        data.write(Float(self.position.x))
        data.write(Float(self.position.y))
        data.write(Int8(round(self.velocity.dx / 4).clamp(-128, 127)))
        data.write(Int8(round(self.velocity.dy / 4).clamp(-128, 127)))
        data.write(UInt8(Int(round(self.zRotation / PI256)) & 255))
        data.write(Int8(round(self.angularVelocity * 768).clamp(-128, 127)))
        let new = (parent as? Play)?.newShoot ?? false
        data.write(UInt16(thrust ? 1 : 0) + UInt16(thrustLeft ? 2 : 0) + UInt16(thrustRight ? 4 : 0) + UInt16(((parent as? Play)?.usedShoot ?? false) && !new ? 8 : 0) + UInt16(new ? 16 : 0) + UInt16(self.id * 32))
        data.write(UInt16(badge + nameColor * 1024))
    }
    
    func decode(data: inout Data){
        //See server protocol for more insight
        target = (pos: CGPoint(x: CGFloat(data.readunsafe() as Float), y: CGFloat(data.readunsafe() as Float)), vel: CGVector(dx: CGFloat(data.readunsafe() as Int8) * 4, dy: CGFloat(data.readunsafe() as Int8) * 4), z: CGFloat(data.readunsafe() as Int8) * PI256, dz: CGFloat(data.readunsafe() as Int8) / 768)
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
        let changed = id != self.id || oa != asteroid
        
        var color = data.readunsafe() as UInt16
        let badge = color & 1023
        color >>= 10
        if let p = parent as? Play, badge > 0 && asteroid{
            //destroy animation
            if !self.asteroidDeathNote{
                self.death = 599
                p.kill(self)
                self.asteroidDeathNote = true
            }
        }else{
            self.asteroidDeathNote = false
            self.namelabel?.fontColor = COLORS[Int(color)]
            if self.badgeNode != nil{
                self.badgeNode!.texture = (BADGES[Int(badge)].children[0] as! SKSpriteNode).texture
                self.badgeNode!.size = self.badgeNode!.texture!.size()
                self.badgeNode!.size.width /= 4
                self.badgeNode!.size.height /= 4
            }
            if changed{ self.setScale(asteroid ? 0.5 : 0.25); self.suit(id) }
        }
        
        if changed || id == 0 || self == (parent as? Play)?.ship || (target!.pos.x - position.x) * (target!.pos.x - position.x) + (target!.pos.y - position.y) * (target!.pos.y - position.y) > 1e6{
            if id != 0{self.position = target!.pos}
            self.velocity = target!.vel
            self.zRotation = target!.z
            self.angularVelocity = target!.dz
            target = nil
        }else if abs((zRotation - target!.z).remainder(dividingBy: .pi * 2)) > 0.5{
            self.zRotation = target!.z
        }
        self.controls = !asteroid
        self.dynamic = true
    }
    func suit(_ id: Int){
        //change ship. also changes the characteristics of the ship
        self.id = id
        if let p = (skview.scene as? Play){p.needsName = self != p.ship && id != 0 && !asteroid && namelabel == nil}
        if id >= (asteroid ? asteroids : ships).count{
            return
        }
        let sh = (asteroid ? asteroids : ships)[id]
        self.thrustMultiplier = sh["speed"]?.number ?? 1
        self.angularThrustMultiplier = sh["spin"]?.number ?? 1
        self.body(radius: CGFloat(sh["radius"]?.number ?? 15), mass: CGFloat(sh["mass"]?.number ?? 500), texture: SKTexture(imageNamed: sh["texture"]?.string ?? "ship1"))
        if !asteroid && id > 0{
            self.shootPoints = SHOOTPOINTS[id-1]
            self.shootVectors = SHOOTVECTORS[id-1]
            self.shootDamages = SHOOTDAMAGES[id-1]
            self.particleOffset = THRUSTPOINTS[id-1]
        }
        
    }
    
}
