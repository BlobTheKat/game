//
//  PlayCore.swift
//  game
//
//  Created by Matthew on 03/10/2021.
//

import Foundation
import SpriteKit


var energyAmount = 2147483648.0
var energySpace = 100.0
var energyPercent = 0.0


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
    override func update(_ currentTime: TimeInterval){
        if view == nil{return}
        //this piece of code prevents speedhack and/or performance from slowing down gametime by running update more or less times based on delay (the currentTime parameter)
        let ti = 1/gameFPS
        if lastUpdate == nil{
            lastUpdate = currentTime - ti
        }
        framesQueued += currentTime - lastUpdate! - ti
        lastUpdate = currentTime
        
        
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
            collectedLabel.text = "\(Int(NSDate().timeIntervalSince1970 - planetLanded.last) * Int(planetLanded.persec))"
        }
        if presence{
            if planetLanded == nil{return planetEditMode()}
            planetLandedRot += planetLanded!.angularVelocity
            planetLanded!.zRotation -= planetLanded!.angularVelocity
            cam.position.x = (cam.position.x*9 + planetLanded!.position.x)/10
            cam.position.y = (cam.position.y*9 + planetLanded!.position.y + planetLanded!.radius - self.size.width / 15)/10
            if dragRemainder.isInfinite{
                var amount = sign(dragRemainder) * 2
                while planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] != nil{amount += sign(amount)}
                let l = planetLanded!.children.first(where: {$0.userData?["rot"] as? UInt8 == itemRot})
                planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] = planetLanded!.items[Int(itemRot)]
                planetLanded!.items[Int(itemRot)] = nil
                itemRot &+= UInt8(Int(amount) & 255)
                planetLanded!.run(.rotate(byAngle: amount * PI256, duration: abs(amount) / 10.0))
                l?.run(.rotate(byAngle: -amount * PI256, duration: abs(amount) / 10.0))
                l?.userData?["rot"] = itemRot
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
                let ts = min((stress / 0.6 - 1) * scale, 5 - scale)
                cam.setScale(scale + ts / 50)
            }else if stress < 0.3{
                let ts = max((stress / 0.4 - 1) * scale, (ship.landed ? 1 : 2) - scale)
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
    }
    func spaceUpdate(){
      
        
        energyCount.text = "k$ \(energyAmount)"
        
        energyPercent = floor((energyAmount / energySpace) * 8)
        
        var i = 0.0
        for node in energyNodes{
            node.texture = i < energyPercent ? SKTexture(imageNamed: "energyOn") : SKTexture(imageNamed: "energyOff")
            i += 1
        }
        
        if coolingDown{
            ship.shootFrequency = 0
        }
        playerArrow.position = CGPoint(x: (self.ship.position.x/10), y: (self.ship.position.y/10))
        playerArrow.zRotation = ship.zRotation
        
        var a = 0
        defer{
            for particle in particles{
                if particle.update(){
                    particles.remove(at: particles.firstIndex(of: particle)!)
                    particle.removeFromParent()
                }
            }
        }
        a = 0
        for s in objects{s.landed = false}
        for planet in planets{
            for s in objects{
                if s.landed{continue}
                planet.gravity(s)
            }
            planet.update(a < planetindicators.count ? planetindicators[a] : nil)
            a += 1
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
                    //s.velocity.dx = ((2 * ship.mass * ship.velocity.dx) - s.velocity.dx * diff) / sum
                    //s.velocity.dy = ((2 * ship.mass * ship.velocity.dy) - s.velocity.dy * diff) / sum
                    ship.velocity.dx = newvelx
                    ship.velocity.dy = newvely
                    hits.append(UInt32(a - 1))
                }
            }
            a += 1
        }
        let isX = abs(ship.position.x) > sector.1.size.width / 2 - border2.size.width
        let isY = abs(ship.position.y) > sector.1.size.height / 2 - border1.size.width
        if (abs(ship.position.x) > sector.1.size.width / 2 || abs(ship.position.y) > sector.1.size.height / 2) && ship.controls{
            //move
            ship.controls = false
            ship.dynamic = false
            objects[0] = Object()
            ship.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1),
                SKAction.run{ [self] in
                    ship.removeFromParent()
                    send(Data([9, 0, 0, 0, 0, 0, 0, 0, 0]))
                    end()
                    DispatchQueue.main.async{SKScene.transition = .crossFade(withDuration: 0.5);Play.renderTo(skview);SKScene.transition = .crossFade(withDuration: 0)}
                }
            ]))
            var sx = ship.position.x
            var sy = ship.position.y
            if isX{
                sx = (sx < 0 ? -1 : 1) * (sector.1.size.width / 2 + 2000)
            }
            if isY{
                sy = (sy < 0 ? -1 : 1) * (sector.1.size.height / 2 + 2000)
            }
            secx = Int(sx + sector.1.pos.x)
            secy = Int(sy + sector.1.pos.y)
            ship.run(SKAction.move(by: CGVector(dx: ship.velocity.dx * gameFPS, dy: ship.velocity.dy * gameFPS), duration: 1))
        }else if (isX || isY) && ship.controls && clock20 == 0{
            //calculate which sector you're gonna go to
            var sx = ship.position.x
            var sy = ship.position.y
            if isX{
                sx = (sx < 0 ? -1 : 1) * (sector.1.size.width / 2 + 2000)
            }
            if isY{
                sy = (sy < 0 ? -1 : 1) * (sector.1.size.height / 2 + 2000)
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
                    name //this is the label's text
                }
            }
            if !d{
                //THIS IS WHERE YOU HIDE THE LABEL
            }
        }
        clock20 = (clock20 + 1) % 20
        vel = CGFloat(sqrt(ship.velocity.dx*ship.velocity.dx + ship.velocity.dy*ship.velocity.dy)) * gameFPS
        speedLabel.text = %Float(vel / 2)
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
            lastU = SystemDataUsage.complete &- lastComplete
            lastComplete = lastComplete &+ lastU
            lastMem = report_memory()
        }
        DEBUG_TXT.text = "X: \(%ship.position.x) / Y: \(%ship.position.y)\nDX: \(%ship.velocity.dx) / DY: \(%ship.velocity.dy)\nA: \(%ship.zRotation), AV: \(%ship.angularVelocity)\nVEL: \(%vel) VER: \(build)\nMEM: \(lastMem)MB NET: \(Int(Double(lastU) * gameFPS / 20480.0))KB/s\n\(logs.joined(separator: "\n"))"
    }
    // USED FOR COLONIZING A PLANET
    func colonize(_ planet: Planet){
        var data = Data()
        data.write(critid(10))
        data.write(UInt32(planets.firstIndex(of: planet)!))
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
    
    //USED FOR COLLECTING ALL THE ITEMS FROM PLANET
    func collectFrom(_ planet: Planet){
        
        var dat = Data()
        dat.write(critid(17))
        dat.write(UInt16(planets.firstIndex(of: planet)!))
        critical(dat, abandoned: {
            self.didCollect(false)
        })
    }
    func didCollect(_ success: Bool){}
    func didMake(_ success: Bool){}
}
