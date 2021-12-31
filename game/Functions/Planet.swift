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
        if colo?.type == item.type && colo?.lvl == item.lvl && colo?.capacity == item.capacity && colo?.upgradeEnd == item.upgradeEnd && node.userData?["rot"] as? UInt8 == rot{return node}
        node.userData!["type"] = item
        node.userData!["rot"] = rot
        if let parent = parent as? Play{
            if rot == parent.itemRot && self == parent.planetLanded{
                DispatchQueue.main.async(execute: parent.renderUpgradeUI)
            }
        }
        node.removeAllActions()
        node.removeAllChildren()
        
        let id = Int(item.type.rawValue)
        let rot = CGFloat(rot) * PI256
        node.setScale(1)
        node.texture = item.lvl > 0 ? SKTexture(imageNamed: "\(coloNames[id])\(item.lvl)") : SKTexture(imageNamed: "blank")
        node.size = node.texture!.size()
        node.setScale(0.5)
        node.anchorPoint = CGPoint(x: 0.5, y: (10 - self.radius) / node.size.height)
        if item.type == .shooter && item.upgradeEnd == 0{
            let n = SKSpriteNode(imageNamed: "head\(item.lvl)")
            node.addChild(n)
            n.anchorPoint = CGPoint(x: 0.5, y: 0)
            n.position.y = (self.radius * 2) - 50 + node.size.height / 5 + (shooters[Int(item.lvl)]["_head"]!.number!)
            
        }
        if item.upgradeEnd > 0{
           let n = SKSpriteNode(imageNamed: "upgradingoverlay")
           node.addChild(n)
           n.anchorPoint = CGPoint(x: 0.5, y: 0)
           n.position.y = self.radius * 2 - 20
           n.zPosition = 10
           n.setScale(node.size.width / n.size.width * 2)
        }else if let p = parent as? Play, item.type == .satellite && !(p.planetLanded == self && p.presence){
            node.anchorPoint.y = (-170 - self.radius) / node.size.height
            node.run(.repeatForever(SKAction.rotate(byAngle: self.angularVelocity + 0.05, duration: 1)))
        }else if parent as? Play != nil, item.type == .satellite{
            node.anchorPoint.y = (-170 - self.radius) / node.size.height - 2
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
            for node in self.children{ //for each shooter
                guard let node = node as? SKSpriteNode else { continue }
                guard let itm = (node.userData?["type"] as? ColonizeItem) else {continue}
                if itm.upgradeEnd > 0{ continue }
                switch itm.type{
                case .shooter:
                    let item = shooters[Int(itm.lvl)]
                    let p = CGPoint(x: -sin(node.zRotation) * (self.radius - 27), y: cos(node.zRotation) * (self.radius - 27))
                    let x = parent.ship.position.x - (self.position.x + -sin(node.zRotation + self.zRotation) * (self.radius / self.xScale - 27))
                    let y = parent.ship.position.y - (self.position.y + cos(node.zRotation + self.zRotation) * (self.radius / self.yScale - 27))
                    let dir = (atan2(-x, y) - node.zRotation - zRotation).remainder(dividingBy: .pi * 2)
                    
                    let acc = item["accuracy"]?.number ?? 0.05
                    let r = (node.children[0].zRotation * (1-acc) + dir * acc).remainder(dividingBy: .pi * 2)
                    if abs(r) > 0.75{continue}
                    node.children[0].zRotation = r
                    if abs(dir) > 0.75{continue}
                    shootFrequency = 0.06
                    node.children[0].zRotation = r
                    shootPoints.append(p)
                    shootVectors.append(node.children[0].zRotation + node.zRotation)
                    shootDamages.append(item["damage"]?.number ?? 2)
                    break
                case .electro:
                    if self.angry % 60 != 0{break}
                    let item = electros[Int(itm.lvl)]
                    var a = -sin(node.zRotation + self.zRotation)
                    var b = cos(node.zRotation + self.zRotation)
                    var x = parent.ship.position.x - (self.position.x + a * (self.radius / self.xScale + 60))
                    var y = parent.ship.position.y - (self.position.y + b * (self.radius / self.yScale + 60))
                    (a, b) = (b * 10, a * -10)
                    var x0 = x - a, y0 = y - b, x1 = x + a, y1 = y + b
                    (x, y) = x0 * x0 + y0 * y0 < x1 * x1 + y1 * y1 ? (x0, y0) : (x1, y1)
                    let size = sqrt(x * x + y * y)
                    if size > item["linereach"]?.number ?? 200{break}
                    if x > 0{ x1 = parent.ship.position.x; x0 = x1 - x }
                    else{ x0 = parent.ship.position.x; x1 = x0 - x }
                    if y > 0{ y1 = parent.ship.position.y; y0 = y1 - y }
                    else{ y0 = parent.ship.position.y; y1 = y0 - y }
                    let z = atan2(-x, y)
                    x = (x0 + x1) / 2
                    y = (y0 + y1) / 2
                    let ray = SKSpriteNode(imageNamed: "ray\(random(min: 1, max: 4))")
                    ray.position = CGPoint(x: x, y: y)
                    ray.yScale = size / 220
                    ray.zRotation = z
                    ray.zPosition = node.zPosition - 1
                    parent.addChild(ray)
                    parent.dealDamage(item["damage"]?.number ?? 1)
                    let _ = timeout(0.2){ray.removeFromParent()}
                    break
                default:
                    break
                }
                
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
                        lastSentEnergy += 10
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
    var persec: CGFloat = 0
    var capacity = 0
    var inbank = 0
    var persec2: CGFloat = 0
    var capacity2 = 0
    var inbank2 = 0
    override func decode(data: inout Data) {
        //decode things on the planet
        self.last = Double(data.readunsafe() as UInt32)
        self.inbank = Int(data.readunsafe() as Float)
        self.inbank2 = Int(data.readunsafe() as Float)
        self.namelabel?.removeFromParent()
        self.namelabel = SKLabelNode(text: "...")
        (parent as? Play)?.label(node: self.namelabel!, data.read(lentype: UInt8.self) ?? "", pos: CGPoint(x: position.x, y: position.y - 15), size: 30, color: .green, font: "Menlo", zPos: 3)
        let bits = data.readunsafe() as UInt8
        let ownedState = OwnedState(rawValue: bits & 192)!
        if self.ownedState != ownedState{
            self.ownedState = ownedState
            if let parent = parent as? Play{
                parent.editColoIcon.removeFromParent()
                parent.collectedLabel.removeFromParent()
                parent.collect.removeFromParent()
                parent.coloArrow.removeFromParent()
                parent.buildBG.removeFromParent()
                if parent.presence{parent.planetEditMode()}
                parent.planetLanded = nil
                parent.landed()
                
            }
        }
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
        self.capacity = 0
        self.persec2 = 0
        self.capacity2 = 0
        while(i < len){
            while (self.children.count > child_i ? self.children[child_i].name : nil) != nil{child_i += 1;continue}
            let id: UInt8 = data.readunsafe()
            var item = (type: ColonizeItemType.init(rawValue: id & 127) ?? .drill, lvl: data.readunsafe() as UInt8, capacity: data.readunsafe() as UInt8, upgradeEnd: UInt32())
            let rot = data.readunsafe() as UInt8
            if id > 127{
                //ITS UPGRADING
                item.upgradeEnd = data.readunsafe() as UInt32
            }
            let _ = self.populate(with: item, rot: rot, node: self.children.count > child_i ? self.children[child_i] as! SKSpriteNode : SKSpriteNode())
            self.items[Int(rot)] = item
            if item.type == .drill && id < 128{
                self.persec += drills[Int(item.lvl)]["persec"]?.number ?? 0
                self.capacity += Int(drills[Int(item.lvl)]["storage"]?.number ?? 0)
            }else if item.type == .dish && id < 128{
                self.persec2 += dishes[Int(item.lvl)]["persec"]?.number ?? 0
                self.capacity2 += Int(dishes[Int(item.lvl)]["storage"]?.number ?? 0)
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
