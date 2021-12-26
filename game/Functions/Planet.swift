//
//  Objects.swift
//  game
//
//  Created by BlobKat on 22/07/2021.
//

import Foundation
import SpriteKit

class Planet: Object{
    override func body(radius: CGFloat, mass: CGFloat, texture: SKTexture? = nil){
        zPosition = 2
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
    override class func defaultParticle(_ planet: Object) -> Particle{
        return Particle()
    }
    var angry = 0 //time in frames till planet forgives you. When you shoot it, goes up to 6000 (100 seconds)
    var emitq = 0.0
    var emitf = 0.1

    var ownedState: OwnedState = .unowned

    var collectibles = Set<SKSpriteNode>()
    func cook(_ point: CGPoint, to radius: CGFloat = .nan) -> CGVector{
        let radius = radius.isNaN ? self.radius : radius
        var x = point.x - self.position.x
        var y = point.y - self.position.y
                
        //now let's normalize these coordinates to the radius of the planet (minus some padding)
        let d = radius / sqrt(x * x + y * y)
        x *= d
        y *= d
        return CGVector(dx: x, dy: y)
    }
    func populate(with item: ColonizeItem, rot: UInt8, node: SKSpriteNode = SKSpriteNode()) -> SKSpriteNode{
        if node.userData == nil{node.userData = NSMutableDictionary(capacity: 2)}
        let colo = (node.userData!["type"] as? ColonizeItem)
        if colo?.type == item.type && colo?.lvl == item.lvl && colo?.capacity == item.capacity && node.userData?["rot"] as? UInt8 == rot{return node}
        node.userData!["type"] = item
        node.userData!["rot"] = rot
        node.removeAllActions()
        let rot = CGFloat(rot) * PI256
        node.setScale(1)
        let id = Int(item.type.rawValue)
        node.texture = SKTexture(imageNamed: "\(coloNames[id&127])\(item.lvl)\(id>127 ? "-upgrading" : "")")
        node.size = node.texture!.size()
        node.setScale((self.xScale + self.yScale) / 4)
        node.anchorPoint = CGPoint(x: 0.5, y: ((item.type == .satellite ? -170 : 10) - self.radius) / node.size.height)
        if let p = parent as? Play, item.type == .satellite && !(p.planetLanded == self && p.presence){
            node.run(.repeatForever(SKAction.rotate(byAngle: self.angularVelocity + 0.05, duration: 1)))
        }
        node.zRotation = -rot
        if node.parent == nil { self.addChild(node) }
        return node
    }
    func emit(_ p: CGVector){
        //we can make a particle node that will be added to the planet
        let randomTexture = random(min: 0, max: 8)
        let n = SKSpriteNode()
        n.position = CGPoint(x: p.dx + self.position.x, y: p.dy + self.position.y)
        n.texture = SKTexture(imageNamed: "particle\(randomTexture)")
        n.size = n.texture!.size()
        n.setScale(0.5)
        n.zPosition = -1.5
        self.parent?.addChild(n)
        
        //now we can animate the particle
        let d2 = (self.radius + random(min: 30, max: 120)) / (self.radius - 50) - 1
        n.run(.sequence([.move(by: CGVector(dx: p.dx * d2, dy: p.dy * d2), duration: 1.5).ease({t in return (2-t)*t}),.wait(forDuration: 18),.fadeOut(withDuration: 1),.run{n.removeFromParent();self.collectibles.remove(n)}]))
        collectibles.insert(n)
        angry = 1800
    }
    override func update() {}
    func update(_ node: SKSpriteNode?){
        if self.angry > 1{
            //count down timer and calculate shooting
            self.angry -= 1
            shootFrequency = 0
            shootVectors = []
            shootPoints = []
            guard let parent = parent as? Play else {return}
            for node in self.children.filter({a in return (a.userData?["type"] as? ColonizeItem)?.type == .shooter}){ //for each shooter
                guard let node = node as? SKSpriteNode else { continue }
                shootFrequency = 0.06
                let p = CGPoint(x: -sin(node.zRotation) * (self.radius - 27), y: cos(node.zRotation) * (self.radius - 27))
                let x = parent.ship.position.x - (self.position.x + -sin(node.zRotation + self.zRotation) * (self.radius / self.xScale - 27))
                let y = parent.ship.position.y - (self.position.y + cos(node.zRotation + self.zRotation) * (self.radius / self.yScale - 27))
                let dir = atan2(-x, y)
                let r = (node.children[0].zRotation * 0.95 + (dir - node.zRotation - zRotation).remainder(dividingBy: .pi * 2) / 20).remainder(dividingBy: .pi * 2)
                if abs(r) > 0.75{continue}
                node.children[0].zRotation = r
                shootPoints.append(p)
                shootVectors.append(node.children[0].zRotation + node.zRotation)
                shootDamages.append(shooters[Int((node.userData?["type"] as? ColonizeItem)?.lvl ?? 1)]["damage"]?.number ?? 2)
                
            }
        }else{self.shootFrequency = 0}
        shoot()
        if let i = node{
            guard let parent = parent as? Play else{return}
            guard let cam = parent.camera else {return}
            let size = CGSize(width: size.width / cam.xScale, height: size.height / cam.yScale)
            let frame = CGRect(origin: CGPoint(x: -parent.size.width / 2, y: -parent.size.height / 2), size: parent.size)
            let dx = (self.position.x - cam.position.x) / cam.xScale
            let dy = (self.position.y - cam.position.y) / cam.yScale
            if (dx * dx + dy * dy < 9000000) && (dx < frame.minX - size.width / 2 || dx > frame.maxX + size.width / 2 || dy < frame.minY - size.height / 2 || dy > frame.maxY + size.height / 2){
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
        guard n.dynamic else{ return }
        n.landed = false
        let mass: CGFloat = self.mass
        let x = n.position.x - self.position.x
        let y = n.position.y - self.position.y
        let d = x * x + y * y
        var r = self.radius * self.radius - n.radius * n.radius
        if r < 0{r=0}
        r += (2 * sqrt(r) + n.radius) * n.radius
        let M = mass * G
        let m = min(M / (16 * r) - M / d, 0)
        let deathzone = m * m * d > n.thrustMultiplier * n.thrustMultiplier / 900
        if d < r - radius{
            if n.asteroid || deathzone || superhot{
                let parent = n.parent as? Play
                if parent != nil{
                    if n == parent!.ship{
                        n.dynamic = false
                        n.controls = false
                        if let parent = (n.parent as? Play), let i = parent.objects.firstIndex(of: n){
                            n.namelabel?.removeFromParent()
                            n.namelabel = nil
                            parent.objects[i] = Object()
                        }
                        n.run(SKAction.sequence([SKAction.fadeOut(withDuration: 1),SKAction.run{n.removeFromParent()
                            DispatchQueue.main.async{parent!.end();SKScene.transition = .crossFade(withDuration: 0.5);PlayerDied.renderTo(skview);SKScene.transition = .crossFade(withDuration: 0);}
                        }]))
                        n.run(SKAction.move(by: CGVector(dx: n.velocity.dx * gameFPS, dy: CGFloat(n.velocity.dy) * gameFPS), duration: 1))
                    }else{
                        n.death = 100
                    }
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
            if n == (n.parent as? Play)?.ship{n.zRotation = atan2(y, x) - .pi/2}
            n.landed = true
        }else if d <= r + radius && !n.asteroid && !deathzone && !superhot{
            if n == (n.parent as? Play)?.ship{
                if n.landed{
                    n.zRotation += angularVelocity
                }else{
                    n.zRotation = atan2(y, x) - .pi/2
                }
            }
            let t = atan2(x,y) - angularVelocity
            n.velocity = CGVector(dx: sin(t)*sqrt(d)-x, dy: cos(t)*sqrt(d)-y)
            //resting on planet
            n.landed = true
            let parent = parent as? Play
            if parent != nil && n == parent!.ship{
                
                let circle = parent!.planetsMap[parent!.planets.firstIndex(of: self)!]
                circle.fillColor = UIColor.green
                parent?.playerArrow.removeFromParent()
                //TO DO WITH COLONISING
                if self.ownedState == .unowned{
                    parent!.coloPlanet.texture = self.texture
                    parent!.navArrow.texture = SKTexture(imageNamed: "navArrow2")
                    parent!.navBG.addChild(parent!.coloIcon)
                }
                
                if parent?.planetTouched == nil{parent?.planetTouched = self;parent?.landed()}
                else{parent?.planetTouched = self}
            }
        }else{
            let parent = parent as? Play
            if parent != nil && n == parent!.ship{
                
                let circle = parent!.planetsMap[parent!.planets.firstIndex(of: self)!]
                circle.fillColor = superhot ? .orange : .white
                //GANGE MAP HERE
                if parent!.playerArrow.parent == nil{
                    parent!.mainMap.addChild(parent!.playerArrow)
                    //TO DO WITH COLONISING
                    parent!.navArrow.texture = SKTexture(imageNamed: "navArrow")
                    parent!.coloIcon.removeFromParent()
                }
                
                if parent?.planetTouched == self{parent?.takeoff();parent?.planetTouched = nil}
                
            }
            if deathzone && !superhot{
                let parent = n.parent as? Play
                if parent != nil{
                    if n == parent!.ship{
                        n.dynamic = false
                        n.controls = false
                        if let parent = (n.parent as? Play), let i = parent.objects.firstIndex(of: n){
                            n.namelabel?.removeFromParent()
                            n.namelabel = nil
                            parent.objects[i] = Object()
                        }
                        n.run(SKAction.sequence([SKAction.fadeOut(withDuration: 1),SKAction.run{n.removeFromParent()
                            DispatchQueue.main.async{parent!.end();SKScene.transition = .crossFade(withDuration: 0.5);PlayerDied.renderTo(skview);SKScene.transition = .crossFade(withDuration: 0);}
                        }]))
                        n.run(SKAction.move(by: CGVector(dx: n.velocity.dx * gameFPS, dy: CGFloat(n.velocity.dy) * gameFPS), duration: 1))
                    }else{
                        n.death = 100
                    }
                }
                return
            }
            if m < 0 && n == parent?.ship && superhot{
                emitq += emitf
                while emitq > 1{
                    let dir = randDir(self.radius - 50)
                    self.emit(dir)
                    emitq -= 1
                }
            }
            if d < radius * radius + 300 * radius + 22500 && !n.asteroid{
                //check for collect
                let r = n.radius * n.radius + 30 * n.radius + 225
                for i in self.collectibles{
                    if i.zPosition != -1.5{continue}
                    let x = i.position.x - n.position.x
                    let y = i.position.y - n.position.y
                    if x * x + y * y < r{
                        //collect
                        energyAmount += 10
                        self.collectibles.remove(i)
                        i.run(.fadeOut(withDuration: 0.4).ease(.easeOut))
                        i.run(.sequence([.scale(to: 1.5, duration: 0.7),.run{i.removeFromParent()}]))
                        parent?.vibratePhone(.light)
                    }
                }
            }
            
            n.velocity.dx += x * m
            n.velocity.dy += y * m
            n.zRotation += angularVelocity * r / d
        }
    }
    var items = [ColonizeItem?](repeating: nil, count: 256)
    var last = 0.0
    var persec = CGFloat()
    override func decode(data: inout Data) {
        //decode things on the planet
        self.last = Double(data.readunsafe() as UInt32)
        let bits = data.readunsafe() as UInt8
        self.ownedState = .init(rawValue: bits & 192)!
        if bits & 32 == 32{return}
        var len = data.readunsafe() as UInt8 + 1
        if !((parent as? Play)?.dragRemainder.isNaN ?? true){
            //if is dragging, read rest of data but don't apply it
            while len > 0{
                len -= 1
                if (data.readunsafe() as UInt32) & 128 != 0{
                    let _ = data.readunsafe() as UInt32
                }
            }
            return
        }
        for i in 0..<self.items.count{ //remove items
            self.items[i] = nil
        }
        var i = 0, child_i = 0
        self.persec = 0
        while(i < len){
            while (self.children.count > child_i ? self.children[child_i].name : nil) != nil{child_i += 1;continue}
            let id: UInt8 = data.readunsafe()
            let item = (type: ColonizeItemType.init(rawValue: id & 127) ?? .lab, lvl: data.readunsafe() as UInt8, capacity: data.readunsafe() as UInt8)
            let rot = data.readunsafe() as UInt8
            if id > 127{
                //ITS UPGRADING
                let timeLeft = data.readunsafe() as UInt32
            }
            self.items[Int(rot)] = item
            let node = self.populate(with: item, rot: rot, node: self.children.count > child_i ? self.children[child_i] as! SKSpriteNode : SKSpriteNode())
            if item.type == .shooter{
                let n: SKSpriteNode
                if node.children.count == 0{
                    n = SKSpriteNode()
                    node.addChild(n)
                }else{n = (node.children.first as! SKSpriteNode)}
                n.texture = SKTexture(imageNamed: "head\(item.lvl)")
                n.size = n.texture!.size()
                n.anchorPoint = CGPoint(x: 0.5, y: 0)
                n.position.y = (self.radius * 4 / (self.xScale + self.yScale)) - (item.lvl == 2 ? 50 : 40)
                
            }else{
                node.removeAllChildren()
            }
            if item.type == .lab{
                self.persec += 1
            }
            i += 1
            child_i += 1
        }
        while child_i < self.children.count{
            let child = self.children[child_i]
            if child.name == nil{child.removeFromParent()}
            else {child_i += 1}
        }
    }
    override func encode(data: inout Data) {
        //not needed
    }
}
