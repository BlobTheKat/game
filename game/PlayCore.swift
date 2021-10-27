//
//  PlayCore.swift
//  game
//
//  Created by Matthew on 03/10/2021.
//

import Foundation
import SpriteKit

class PlayCore: PlayNetwork{
    var latency = 0.0
    var lastUpdate: TimeInterval? = nil
    let border1 = SKSpriteNode(imageNamed: "tunnel1")
    let border2 = SKSpriteNode(imageNamed: "tunnel1")
    var started = false
    var camOffset = CGPoint(x: 0, y: 0.2)
    var vel: CGFloat = 0
    
    var tracked: [Object] = []
    var trackArrows: [SKSpriteNode] = []
    
    let shipDirection = SKSpriteNode(imageNamed: "direction")
    let star1 = SKSpriteNode(imageNamed: "stars")
    let star2 = SKSpriteNode(imageNamed: "stars")
    let star3 = SKSpriteNode(imageNamed: "stars")
    let star4 = SKSpriteNode(imageNamed: "stars")
    let speedLabel =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var coolingDown = false
    let playerArrow = SKSpriteNode(imageNamed: "playerArrow")
    override func update(_ currentTime: TimeInterval){
        if view == nil{return}
        //this piece of code prevents speedhack and/or performance from slowing down gametime by running update more or less times based on delay (the currentTime parameter)
        let ti = 1/gameFPS
        if lastUpdate == nil{
            lastUpdate = currentTime - ti
        }
        latency += currentTime - lastUpdate! - ti
        lastUpdate = currentTime
        
        
        if latency > ti{
            latency -= ti
            update(currentTime)
        }else if latency < -ti{
            latency += ti
            return
        }
        physics.async{
            self.cameraUpdate()
            self.spaceUpdate()
        }
    }
    func cameraUpdate(){
        let cx = cam.xScale * self.size.width / 2
        let cy = cam.yScale * self.size.height / 2
        let bx = ((loadstack.size?.width ?? CGFloat.infinity) + border2.size.width) / 2 - 100
        let by = ((loadstack.size?.height ?? CGFloat.infinity) + border1.size.width) / 2 - 100
        
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
        
        
        let shipX = floor((ship.position.x)/2440)
        let shipY = floor((ship.position.y)/2440)
        
        star1.position = CGPoint(x: shipX * 2440 ,y: shipY * 2440 )
        star2.position = CGPoint(x: shipX * 2440 + 2440 ,y: shipY * 2440 )
        star3.position = CGPoint(x: shipX * 2440 ,y: shipY * 2440 + 2440 )
        star4.position = CGPoint(x: shipX * 2440 + 2440 ,y: shipY * 2440 + 2440)
        
        if (cam.position.y < 0) != (border1.position.y < 0){
            border1.position.y *= -1
            border1.xScale *= -1
        }
        if (cam.position.x < 0) != (border2.position.x < 0){
            border2.position.x *= -1
            border2.xScale *= -1
        }
        border1.position.x = cam.position.x
        border2.position.y = cam.position.y
        drawDebug()
    }
    var _a = 0
    func spaceUpdate(){
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
                trackArrows.remove(at: a)
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
            if s != ship && s.id > 0{
                let x = ship.position.x - s.position.x
                let y = ship.position.y - s.position.y
                let d = (x * x + y * y)
                let r = (ship.radius + s.radius) * (ship.radius + s.radius)
                if d < r{
                    let q = sqrt(r / d)
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
        let isX = abs(ship.position.x) > (loadstack.size?.width ?? CGFloat.infinity) / 2 - border2.size.width
        let isY = abs(ship.position.y) > (loadstack.size?.height ?? CGFloat.infinity) / 2 - border1.size.width
        if (abs(ship.position.x) > (loadstack.size?.width ?? CGFloat.infinity) / 2 || abs(ship.position.y) > (loadstack.size?.height ?? CGFloat.infinity) / 2) && ship.controls{
            //move
            ship.controls = false
            ship.dynamic = false
            objects[0] = Object()
            ship.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1),
                SKAction.run{ [self] in
                    ship.removeFromParent()
                    send(Data([8, 0, 0, 0, 0]))
                    end()
                    DispatchQueue.main.async{SKScene.transition = .crossFade(withDuration: 0.5);Play.renderTo(skview);SKScene.transition = .crossFade(withDuration: 0)}
                }
            ]))
            var sx = ship.position.x
            var sy = ship.position.y
            if isX{
                sx = (sx < 0 ? -1 : 1) * (loadstack.size!.width / 2 + 2000)
            }
            if isY{
                sy = (sy < 0 ? -1 : 1) * (loadstack.size!.height / 2 + 2000)
            }
            secx = Int(sx + loadstack.pos!.x)
            secy = Int(sy + loadstack.pos!.y)
            ship.run(SKAction.move(by: CGVector(dx: ship.velocity.dx * CGFloat(gameFPS), dy: ship.velocity.dy * CGFloat(gameFPS)), duration: 1))
        }else if (isX || isY) && ship.controls && _a == 0{
            //calculate which sector you're gonna go to
            var sx = ship.position.x
            var sy = ship.position.y
            if isX{
                sx = (sx < 0 ? -1 : 1) * (loadstack.size!.width / 2 + 2000)
            }
            if isY{
                sy = (sy < 0 ? -1 : 1) * (loadstack.size!.height / 2 + 2000)
            }
            let x = loadstack.pos!.x + sx, y = loadstack.pos!.y + sy
            let regionx = 0, regiony = 0//fdiv(Int(x), REGIONSIZE), regiony = fdiv(Int(y), REGIONSIZE)
            var d = false
            for sector in sectors[CGPoint(x: regionx, y: regiony)]!{
                let (_, (pos: pos, size: size), (name: name, ip: _, bucket: _)) = sector
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
        _a = (_a + 1) % 20
        vel = CGFloat(sqrt(ship.velocity.dx*ship.velocity.dx + ship.velocity.dy*ship.velocity.dy)) * CGFloat(gameFPS)
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
    var lastComplete: UInt64 = SystemDataUsage.complete
    var lastU: UInt64 = 0
    var lastMem: UInt16 = 0
    func drawDebug(){
        if _a == 0{
            lastU = SystemDataUsage.complete &- lastComplete
            lastComplete = lastComplete &+ lastU
            lastMem = report_memory()
        }
        DEBUG_TXT.text = "X: \(%ship.position.x) / Y: \(%ship.position.y)\nDX: \(%ship.velocity.dx) / DY: \(%ship.velocity.dy)\nA: \(%ship.zRotation), AV: \(%ship.angularVelocity)\nVEL: \(%vel) VER: \(build)\nMEM: \(lastMem)MB NET: \(Int(Double(lastU) * gameFPS / 20480.0))KB/s\n\(logs.joined(separator: "\n"))"
    }
}
