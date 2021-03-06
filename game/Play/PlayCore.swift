//
//  PlayCore.swift
//  game
//
//  Created by Matthew on 03/10/2021.
//

import Foundation
import SpriteKit
import StoreKit

enum impactType{
    case light
    case medium
    case heavy
    case error
    case success
    case warning
    case none
}

extension Play{
    func vibratePhone(_ impact: impactType) {
         
        if !switch3{
        switch impact{
        case .error:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)

            case .success:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

            case .warning:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)

            case .light:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()

            case .medium:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

            case .heavy:
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()

            default:
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                
            }
    }
    }
    override func update(_ currentTime: TimeInterval){
        if view == nil{return}
        //this piece of code prevents speedhack and/or performance from slowing down gametime by running update more or less times based on delay (the currentTime parameter)
        let ti = 1/gameFPS
        if lastUpdate == nil{
            lastUpdate = currentTime - ti
        }
        framesQueued += currentTime - lastUpdate! - ti
        lastUpdate = currentTime
        framesQueued = min(framesQueued, 60)
        
        if framesQueued > ti{
            framesQueued -= ti
            update(currentTime)
        }else if framesQueued < -ti{
            framesQueued += ti
            return
        }
        physics.async{
            self.cameraUpdate()
            self.spaceUpdate()
        }
    }
    func cameraUpdate(){
        if ship.landed && camBasicZoom < 1{camBasicZoom = 1}
        if statsLabel.count >= 5 && shipSuit == -1{
            var kdr = (Float(kills) / Float(deaths)).clamp(0.01,999)
            if kdr.isNaN{kdr = 0}
            statsLabel2[0].text = "\(kills)"
            statsLabel2[1].text = "\(deaths)"
            statsLabel2[2].text = "\(String(format: "%.2f", kdr))"
            statsLabel2[3].text = "\(myplanets.count)"
            statsLabel2[4].text = "\(Int(travel/1000))ly"
        }
        if !swiping && badgeCropNode.parent != nil && badgeCropNode.children.count > 0{
            var x = appleSwipe * 2
            var correct = badgeCropNode.children.first!.position.x + x - badgeCropNode.children.first!.frame.width
            if correct > 0{x -= correct}else{
                correct = badgeCropNode.children.last!.position.x + x - (self.size.width * 0.8) + badgeCropNode.children.last!.frame.width
                if correct < 0{x -= correct}
            }
            for node in badgeCropNode.children{
                node.position.x += x
            }
            appleSwipe *= 0.95
        }else{appleSwipe *= 0.7}
        border1.position.x = cam.position.x
        border2.position.y = cam.position.y
        drawDebug()
        stars1.position = CGPoint(x: cam.position.x / 2.6, y: cam.position.y / 2.6)
        stars1.update()
        stars2.position = CGPoint(x: cam.position.x / 2, y: cam.position.y / 2)
        stars2.update()
        stars3.position = CGPoint(x: cam.position.x / 1.6, y: cam.position.y / 1.6)
        stars3.update()
        stars4.update()
        stars4.position = CGPoint(x: cam.position.x / 4, y: cam.position.y / 4)
        if let planetLanded = planetLanded{
            if planetLanded.health >= 1{
                collect.texture = collectImg
                let dif: Double = NSDate().timeIntervalSince1970 - planetLanded.last
                collectedLabel.text = "\(min(planetLanded.capacity, Int(dif * planetLanded.persec)) + planetLanded.inbank)"
                collectedLabel2.text = "\(min(planetLanded.capacity2, Int(dif * planetLanded.persec2)) + planetLanded.inbank2)"
            }else if planetLanded.restoring{
                collect.texture = SKTexture(imageNamed: "blank")
                collectedLabel2.text = ""
                collectedLabel.text = "Restoring... (\(Int(32.99 - planetLanded.health * 32))m)"
            }else{
                collect.texture = restoreImg
                collectedLabel2.text = ""
                collectedLabel.text = "Heal (\(Int(10000 - planetLanded.health*10000)) energy)"
            }
        }
        if presence{
            if planetLanded == nil{ return planetEditMode() }
            planetLandedRot += planetLanded!.angularVelocity
            planetLanded!.zRotation -= planetLanded!.angularVelocity
            cam.position.x = (cam.position.x*9 + planetLanded!.position.x)/10
            cam.position.y = (cam.position.y*9 + planetLanded!.position.y + planetLanded!.radius - self.size.width / 15)/10
            if dragRemainder.isInfinite{
                var amount = sign(dragRemainder) * 2
                while planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] != nil{amount += sign(amount)}
                let newRot = UInt8((Int(itemRot) + Int(amount)) & 255)
                let box = UInt8(min(32, ceil(3000 / planetLanded!.radius)))
                var red = false
                var i = newRot &- box &+ 1
                while i != newRot &+ box{
                    if planetLanded!.items[Int(i)] != nil && i != itemRot{ red = true }
                    i &+= 1
                }
                guard let l = planetLanded!.children.first(where: {$0.userData?["rot"] as? UInt8 == itemRot}) as? SKSpriteNode else {return}
                planetLanded!.items[Int(newRot)] = planetLanded!.items[Int(itemRot)]
                planetLanded!.items[Int(itemRot)] = nil
                itemRot &+= UInt8(Int(amount) & 255)
                planetLanded!.run(.rotate(byAngle: amount * PI256, duration: abs(amount) / 10.0))
                l.run(.rotate(byAngle: -amount * PI256, duration: abs(amount) / 10.0))
                l.userData?["rot"] = itemRot
                if red{
                    l.colorBlendFactor = 0.5
                    l.color = .red
                }else{
                    l.colorBlendFactor = 0
                    l.color = .clear
                }
            }
            return
        }
        let cx = cam.xScale * self.size.width / 2
        let cy = cam.yScale * self.size.height / 2
        let bx = ((sector.1.size.width) + border2.size.width) / 2 - 100
        let by = ((sector.1.size.height) + border1.size.width) / 2 - 100
        
        let x = min(max(ship.position.x, cx - bx), bx - cx) - cam.position.x - camOffset.x * cx * 2
        let y = min(max(ship.position.y, cy - by), by - cy) - cam.position.y - camOffset.y * cy * 2
        cam.position.x += x / 30
        cam.position.y += y / 30
        if started{
            let xStress = abs(x / (self.size.width * cam.xScale))
            let yStress = abs(y / (self.size.height * cam.yScale))
            let stress = xStress*2 + yStress*2

            let scale = (cam.xScale + cam.yScale) / 2
            if stress > 0.5{
                let ts = (stress / 0.6 * scale).clamp((ship.landed ? camBasicZoom : 2 * camBasicZoom), 5) - scale
                cam.setScale(scale + ts / 50)
            }else if stress < 0.3{
                let ts = (stress / 0.4 * scale).clamp((ship.landed ? camBasicZoom : 2 * camBasicZoom), 5) - scale
                cam.setScale(scale + ts / 50)
            }
        }
        
        
        shipDirection.zRotation = -atan2(ship.velocity.dx, ship.velocity.dy)
        
        if (cam.position.y < 0) != (border1.position.y < 0){
            border1.position.y *= -1
            border1.xScale *= -1
        }
        if (cam.position.x < 0) != (border2.position.x < 0){
            border2.position.x *= -1
            border2.xScale *= -1
        }
        vel = CGFloat(sqrt(ship.velocity.dx*ship.velocity.dx + ship.velocity.dy*ship.velocity.dy)) * gameFPS
        speedLabel.text = ship.landed ? "0.000" : %Float(vel / 2)
    }
    func spaceUpdate(){
        heal(0.1 / 60) //1 hp every 10s
        
        energyCount.text = "\(Int(energyAmount))"
        researchCount.text = "\(Int(researchAmount))"
        gemLabel.text = "\(Int(gemCount))"
        
        /*if tutorialProgress == .shootPlanet && energyAmount > 99{
            nextStep()
        }*/
        
        var i = 100.0
        for node in energyNodes{
            node.texture = i < energyAmount ? SKTexture(imageNamed: "energyOn") : SKTexture(imageNamed: "energyOff")
            i *= 10
        }
        i = 10
        for node in researchNodes{
            node.texture = Float(i) < researchAmount ? SKTexture(imageNamed: "energyOn") : SKTexture(imageNamed: "energyOff")
            i *= 10
        }
        
        if coolingDown{
            ship.shootFrequency = 0
        }
        playerArrow.position = CGPoint(x: (self.ship.position.x/10), y: (self.ship.position.y/10))
        playerArrow.zRotation = ship.zRotation
        
        var a = 0
        defer{
            var i = 0
            for particle in particles{
                if particle.update(){
                    particles.remove(at: i)
                    i -= 1
                    particle.removeFromParent()
                }
                i += 1
            }
        }
        a = 0
        for s in objects{s.landed = false}
        var d = CGFloat.infinity, closestStar: Planet? = nil
        var canSave = ship.controls
        for planet in planets{
            var a2 = -1
            for s in objects{
                a2 += 1
                if s.landed{continue}
                planet.gravity(s, a2)
            }
            planet.update(a < planetindicators.count ? planetindicators[a] : nil)
            let x = planet.position.x - ship.position.x
            let y = planet.position.y - ship.position.y
            let d2 = sqrt(x * x + y * y)
            if d2 < d && planet.superhot{d = d2;closestStar = planet}
            if d2 < planet.radius + self.size.width{canSave = false}
            a += 1
        }
        if canSave && ship.controls{
            secx = Int(ship.position.x + sector.1.pos.x)
            secy = Int(ship.position.y + sector.1.pos.y)
            UserDefaults.standard.set(secx, forKey: "sx")
            UserDefaults.standard.set(secy, forKey: "sy")
        }
        if closestStar != nil{
            let v = 1 / (0.001 * d).clamp(1, 2) - 0.35
            ambient.run(.changeVolume(to: Float(v), duration: 0))
        }
        a = 0
        for t in tracked{
            if t.parent == nil{
                tracked.remove(at: a)
                trackArrows[a].removeFromParent()
                trackArrows.remove(at: a)
                for i in t.children{
                    if i.zPosition == 9{i.removeFromParent()}
                }
                continue
            }
            let i = trackArrows[a]
            let size = CGSize(width: t.size.width / cam.xScale, height: t.size.height / cam.yScale)
            let frame = CGRect(origin: CGPoint(x: -self.size.width / 2, y: -self.size.height / 2), size: self.size)
            let dx = (t.position.x - cam.position.x) / cam.xScale
            let dy = (t.position.y - cam.position.y) / cam.yScale
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
            a += 1
        }
        a = 0
        for s in objects{
            s.update()
            s.namelabel?.position = CGPoint(x: s.position.x, y: s.position.y + 30)
            if s != ship && s.id > 0{
                let x = ship.position.x - s.position.x
                let y = ship.position.y - s.position.y
                let d = (x * x + y * y)
                let r = (ship.radius + s.radius) * (ship.radius + s.radius)
                if d < r{
                    let q = min(500, sqrt(r / d))
                    ship.position.x = s.position.x + x * q
                    ship.position.y = s.position.y + y * q
                    //self and node collided
                    //simplified elastic collision
                    let sum = ship.mass + s.mass
                    let diff = ship.mass - s.mass
                    let newvelx = (ship.velocity.dx * diff + (2 * s.mass * s.velocity.dx)) / sum
                    let newvely = (ship.velocity.dy * diff + (2 * s.mass * s.velocity.dy)) / sum
                    s.velocity.dx = ((2 * ship.mass * ship.velocity.dx) - s.velocity.dx * diff) / sum
                    s.velocity.dy = ((2 * ship.mass * ship.velocity.dy) - s.velocity.dy * diff) / sum
                    hits.append((UInt32(a), Float(ship.velocity.dx), Float(ship.velocity.dy)))
                    ship.velocity.dx = newvelx
                    ship.velocity.dy = newvely
                }
            }
            
            if a == objBoxes.count{
                objBoxes.append(SKShapeNode(rectOf: CGSize(width: 20, height: 20)))
                objBoxes.last!.fillColor = .green
                objBoxes.last!.lineWidth = 0
                mainMap.addChild(objBoxes.last!)
            }
            if s.id != 0 && !s.asteroid && a > 0{
                if objBoxes[a].parent == nil{mainMap.addChild(objBoxes.last!)}
                objBoxes[a].position = s.position / 10
            }else{
                objBoxes[a].removeFromParent()
            }
            
            let r = ship.radius * ship.radius + 30 * ship.radius + 225
            for i in collectibles{
                let x = i.position.x - ship.position.x
                let y = i.position.y - ship.position.y
                if x * x + y * y < r{
                    //collect
                    lastSentEnergy += random(min: 100, max: 200)
                    self.collectibles.remove(i)
                    heal(2)
                    i.run(.fadeOut(withDuration: 0.4).ease(.easeOut))
                    i.run(.sequence([.scale(to: 1.5, duration: 0.7),.run{i.removeFromParent()}]))
                    vibratePhone(.light)
                }
            }
            a += 1
        }
        while a < objBoxes.count{
            objBoxes.last!.removeFromParent()
            objBoxes.removeLast()
        }
        let isX = abs(ship.position.x) > sector.1.size.width / 2
        let isY = abs(ship.position.y) > sector.1.size.height / 2
        if (isX || isY) && ship.controls{
            //move
            ship.controls = false
            ship.dynamic = false
            objects[0] = Object()
            ship.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1),
                SKAction.run{ [self] in
                    movemode = true
                    zrot = ship.zRotation
                    velo = ship.velocity
                    ship.removeFromParent()
                    send(Data([9, 0, 0, 0, 0, 0, 0, 0, 0]))
                    end()
                    DispatchQueue.main.async{SKScene.transition = .crossFade(withDuration: 0.5);Play.renderTo(skview);SKScene.transition = .crossFade(withDuration: 0)}
                }
            ]))
            var sx = ship.position.x
            var sy = ship.position.y
            if isX{
                sx = (sx < 0 ? -1 : 1) * (sector.1.size.width / 2 + 1)
            }
            if isY{
                sy = (sy < 0 ? -1 : 1) * (sector.1.size.height / 2 + 1)
            }
            secx = Int(sx + sector.1.pos.x)
            secy = Int(sy + sector.1.pos.y)
            UserDefaults.standard.set(secx, forKey: "sx")
            UserDefaults.standard.set(secy, forKey: "sy")
            ship.run(SKAction.move(by: CGVector(dx: ship.velocity.dx * gameFPS, dy: ship.velocity.dy * gameFPS), duration: 1))
        }else if (isX || isY) && ship.controls && clock20 == 0{
            //calculate which sector you're gonna go to
            var sx = ship.position.x
            var sy = ship.position.y
            if isX{
                sx = (sx < 0 ? -1 : 1) * (sector.1.size.width / 2 + 1)
            }
            if isY{
                sy = (sy < 0 ? -1 : 1) * (sector.1.size.height / 2 + 1)
            }
            let x = sector.1.pos.x + sx, y = sector.1.pos.y + sy
            let regionx = 0, regiony = 0//fdiv(Int(x), REGIONSIZE), regiony = fdiv(Int(y), REGIONSIZE)
            var d = false
            for sector in regions[CGPoint(x: regionx, y: regiony)]!{
                let (_, (pos: pos, size: size), (name: name, ip: _)) = sector
                let w2 = size.width / 2
                let h2 = size.height / 2
                if x > pos.x - w2 && x < pos.x + w2 && y > pos.y - h2 && y < pos.y + h2 && !d{
                    d = true
                    //THIS IS WHERE YOU SHOW THE LABEL
                    let _ = name //this is the label's text
                }
            }
            if !d{
                //THIS IS WHERE YOU HIDE THE LABEL
            }
        }
        clock20 = (clock20 + 1) % 20
    }
    func emit(_ pos: CGPoint, _ p: CGVector){
        //we can make a particle node that will be added to the planet
        let randomTexture = random(min: 0, max: 8)
        let n = SKSpriteNode()
        n.position = pos
        n.texture = SKTexture(imageNamed: "particle\(randomTexture)")
        n.size = n.texture!.size()
        n.setScale(0.5)
        n.zPosition = 1
        self.addChild(n)
        
        //now we can animate the particle
        n.run(.sequence([.move(by: CGVector(dx: p.dx, dy: p.dy), duration: 1).ease(.easeOut),.wait(forDuration: 18),.fadeOut(withDuration: 1),.run{n.removeFromParent();self.collectibles.remove(n)}]))
        collectibles.insert(n)
    }
    func report_memory() -> UInt16{
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo){
            $0.withMemoryRebound(to: integer_t.self, capacity: 1){
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS{
            return UInt16(taskInfo.resident_size / 1048576)
        }else{
            return 0
        }
    }
    
    func drawDebug(){
        if clock20 == 0{
            lastU = dataUsage
            dataUsage = 0
            lastMem = report_memory()
        }
        DEBUG_TXT.text = "X: \(%ship.position.x) / Y: \(%ship.position.y)\nDX: \(%ship.velocity.dx) / DY: \(%ship.velocity.dy)\nA: \(%ship.zRotation), AV: \(%ship.angularVelocity)\nVEL: \(%vel) P: \(planets.count) O: \(objects.count)/\(objects.filter({return !$0.asteroid}).count)\nMEM: \(lastMem)MB \"\(name ?? "nil")\"" + (planetLanded == nil ? "" : "\n\(Int(sector.1.pos.x+planetLanded!.position.x))_\(Int(sector.1.pos.y+planetLanded!.position.y)).json A:\(planetLanded!.angry/60)") + (advancedDebug ? "\nIP: \(IPOVERRIDE ?? ip) (\(Int(Double(lastU) * gameFPS / 20480.0))KB/s)\n\(logs.joined(separator: "\n"))" + (fiddlenode?.parent != nil ? "\nx: \(Float(reg.x.value)), y: \(rnd(reg.y.value)), s: \(rnd(reg.s.value))\nmx: \(rnd(reg.mx.value)), my: \(rnd(reg.my.value)), z: \(rnd(reg.z.value))\nsx: \(rnd(reg.sx.value)), sy: \(rnd(reg.sy.value)), o: \(rnd(reg.o.value))\nr: \(reg.r.str), g: \(reg.g.str), b: \(reg.b.str)\ni: \(reg.i.str) p: \(reg.p.str)" : "") : "")
    }
    // USED FOR COLONIZING A PLANET
    func colonize(_ planet: Planet){
        var data = Data()
        data.write(critid(10))
        data.write(UInt32(planets.firstIndex(of: planet)!))
        planetColonizing = "\(Int(planet.position.x)) \(Int(planet.position.y))"
        critical(data, abandoned: {
            //Error: NOT_ACK'D
            self.didBuy(false)
        })
    }
    //USED FOR MOVING ITEMS AND UPGRADING THEM
    //changeItem(_ planet: Planet, _ rot: Int, _ newrot: Int) is for MOVING item to newrot
    //changeItem(_ planet: Planet, _ rot: Int) is for UPGRADING item
    func changeItem(_ planet: Planet, _ rot: Int, _ newrot: Int = -1){
        var dat = Data()
        dat.write(critid(14))
        dat.write(UInt16(planets.firstIndex(of: planet)!))
        dat.write(UInt8(rot))
        if newrot != -1{dat.write(UInt8(newrot))}
        critical(dat, abandoned: {
            self.didChangeItem(false)
        })
    }
    func makeItem(_ planet: Planet, _ rot: UInt8, _ id: ColonizeItemType){
        
        guard planet.items[Int(rot)] == nil else {return}
        
        var dat = Data()
        dat.write(critid(20))
        dat.write(UInt16(planets.firstIndex(of: planet)!))
        dat.write(UInt8(rot))
        dat.write(id.rawValue)
        
        critical(dat, abandoned: {
            self.didChangeItem(false)
        })
    }
    func skipBuild(_ planet: Planet, _ rot: UInt8){
        
        var dat = Data()
        dat.write(critid(23))
        dat.write(UInt16(planets.firstIndex(of: planet)!))
        dat.write(UInt8(rot))
        critical(dat)
    }
    
    func repair(_ planet: Planet, _ rot: UInt8){
        
        var dat = Data()
        dat.write(critid(26))
        dat.write(UInt16(planets.firstIndex(of: planet)!))
        dat.write(UInt8(rot))
        critical(dat)
    }
    
    //USED FOR COLLECTING ALL THE ITEMS FROM PLANET
    func collectFrom(_ planet: Planet){
        
        var dat = Data()
        dat.write(critid(17))
        dat.write(UInt16(planets.firstIndex(of: planet)!))
        critical(dat, abandoned: {
            self.didCollect(false)
        })
    }
    func restore(_ planet: Planet){
        
        var dat = Data()
        dat.write(critid(29))
        dat.write(UInt16(planets.firstIndex(of: planet)!))
        critical(dat, abandoned: {
            self.didCollect(false)
        })
    }
    func didCollect(_ success: Bool){}
    func didMake(_ success: Bool){renderUpgradeUI()}
    func dealDamage(_ damage: Double, silent: Bool = false){
        if health > damage{
            let oldRatio = health / maxHealth
            health -= damage
            let ratio = health / maxHealth
            if ratio < 0.25{
                if warningLabel.parent == nil{
                    DisplayWARNING("warning: low health",.warning,true)
                }
            }
            let r = Int8(round(ratio * 13))
            if r != Int8(round(oldRatio * 13)){
                healthBar.texture = SKTexture(imageNamed: "health\(r)")
            }
            if !silent{
                self.run(SKAction.sequence([
                    SKAction.run{
                        let cam = self.cam
                        vibrateCamera(camera: cam, amount: 5)
                    },
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run {
                        self.cam.removeAction(forKey: "vibratingCamera")
                        self.cam.removeAction(forKey: "vibratingCameras")
                    }
                ]))
            }
        }else if ship.dynamic{
            health = 0
            healthBar.texture = SKTexture(imageNamed: "health0")
            ship.death = 600
            kill(ship)
            ship.removeFromParent()
            ship.controls = false
            ship.dynamic = false
            let _ = timeout(1){ [self] in
                end()
                stars1.removeFromParent()
                stars2.removeFromParent()
                stars3.removeFromParent()
                SKScene.transition = .crossFade(withDuration: 0.5)
                PlayerDied.renderTo(skview)
                SKScene.transition = .crossFade(withDuration: 0)
            }
        }
    }
    func heal(_ amount: Double){
        let oldRatio = health / maxHealth
        health += amount
        if health > maxHealth{
            health = maxHealth
        }
        let ratio = health / maxHealth
        if ratio > 0.25 && warningLabel.text == "warning: low health"{warning.removeFromParent()}
        let r = Int8(round(ratio * 13))
        if r != Int8(round(oldRatio * 13)){
            healthBar.texture = SKTexture(imageNamed: "health\(r)")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func initInAppPurchases() {
        SKPaymentQueue.default().add(self)
        if request == nil {
            request = SKProductsRequest(productIdentifiers: Set(["1", "2", "3", "4"]))
            request.delegate = self
            request.start()
        }
    }
 
    func buy(_ i: Int, _ cb: @escaping () -> ()) {
        if cbProductIdentifier != ""{ return }
        let payment = SKPayment(product: products[i])
        SKPaymentQueue.default().add(payment)
        boughtCB = cb
        cbProductIdentifier = products[i].productIdentifier
    }
 
    // did successfully get the products
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        self.request = nil
    }
 
    // couldnt get products
    func request(request: SKRequest, didFailWithError error: NSError?) {
        if let error = error{print(error)}
        self.request = nil
    }
    // StoreKit protocol method. Called after the purchase
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
 
            case .purchased:
                if cbProductIdentifier == transaction.payment.productIdentifier{ boughtCB(); cbProductIdentifier = "" }
                queue.finishTransaction(transaction)
            case .restored:
                if cbProductIdentifier == transaction.payment.productIdentifier{ boughtCB(); cbProductIdentifier = "" }
                queue.finishTransaction(transaction)
            case .failed:
                print("Payment Error:", transaction.error!)
                queue.finishTransaction(transaction)
            default:
                print("Transaction State:", transaction.transactionState)
            }
        }
    }
}
