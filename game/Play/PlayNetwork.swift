//
//  PlayNetwork.swift
//  game
//
//  Created by Matthew on 01/10/2021.
//

import Foundation
import SpriteKit
import GameKit

var creds: (url: URL, sig: Data, salt: Data, time: UInt64, id: String)?
extension Play{
    
    func critid(_ a: UInt8) -> UInt16{
        //low: a
        //high: SEQ
        if a > 127{
            fatalError("Message code cannot be higher than 127")
        }
        if SEQ < 255{SEQ += 1}else{SEQ = 0}
        return UInt16(a) + UInt16(SEQ)*256 + 128
    }
    func critical(_ dat: Data, resend: Double = 0.5, abandon: Int = 10, abandoned: @escaping () -> () = {}, sent: @escaping () -> () = {}){
        let s = SEQ
        crits.insert(s)
        var stop = {}
        send(dat)
        var tries = 1
        stop = interval(resend){ [self] in
            if ended{return stop()}
            if !crits.contains(s){stop();sent()}else if tries == abandon{
                print("Critical packet not ack'd after \(abandon) attempts, dropping")
                abandoned()
                stop()
                crits.remove(s)
            }else{
                send(dat)
                tries += 1
            }
        }
    }
    func gameCenterAuthed(){
        if gameAuthed{return}
        gotIp()
        gameAuthed = true
    }
    func gameGuest(){
        if gameAuthed{return}
        gotIp()
        gameAuthed = true
        loginFailed.setScale(0.5)
        loginFailed.zPosition = 3000
        cam.addChild(loginFailed)
    }
    func kill(_ n: Object){
        if n.death > 300{
            if n.death > 600{
                //killed by player
                if !n.asteroid{
                    let zKill = SKSpriteNode(imageNamed: "zKill")
                    zKill.anchorPoint = CGPoint(x: 1 , y: 0.5)
                    zKill.position = pos(mx: -0.5, my: 0.14, x: 0, y: 0)
                    zKill.zPosition = 10000
                    zKill.setScale(0.4)
                    zKill.alpha = 0
                    let killLabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
                    killLabel.horizontalAlignmentMode = .right
                    killLabel.position = pos(mx: -0.1, my: 0, x: 0, y: 0)
                    killLabel.fontSize = 40
                    killLabel.zPosition = 5000
                    killLabel.text = "\(killName)"
                    killLabel.fontColor = .red
                    
                    
                    cam.addChild(zKill)
                    zKill.addChild(killLabel)
                    
                    zKill.run(SKAction.sequence([
                        SKAction.moveBy(x: zKill.size.width/1.5, y: 0, duration: 0.5).ease(.easeOut),
                        .wait(forDuration: 5),
                        SKAction.moveBy(x: -zKill.size.width/1.5, y: 0, duration: 0.3),
                        SKAction.run {
                            zKill.removeFromParent()
                        }
                    ]))
                    zKill.run(SKAction.fadeIn(withDuration: 0.8).ease(.easeOut))
                    kills += 1
                }
                for _ in 1...Int(n.asteroid ? n.mass / 100 : SHOOTDAMAGES[n.id].reduce(0){(a, b) in return a + b} / 10){
                    emit(n.position, CGVector(dx: random(min: -100, max: 99), dy: random(min: -100, max: 99)))
                }
            }
            //explode
            for i in disappear(n.position){
                self.particles.append(i)
                self.addChild(i)
            }
        }else if n.death > 0{
            //fade
            n.run(SKAction.move(by: CGVector(dx: n.velocity.dx * gameFPS, dy: CGFloat(n.velocity.dy) * gameFPS), duration: 1))
            n.run(SKAction.sequence([SKAction.fadeOut(withDuration: 1), SKAction.fadeIn(withDuration: 0)]))
        }
    }
    func parseShip(_ data: inout Data, _ i: Int){
        guard i < objects.count else {
            let object = Object()
            object.decode(data: &data)
            if needsName{needsNames.insert(i)}
            needsName = false
            objects.append(object)
            if object.id != 0{
                for i in appear(object.position){
                    self.particles.append(i)
                    self.addChild(i)
                }
                self.addChild(object)
                object.alpha = 0
                let _ = timeout(1){
                    object.alpha = 1
                }
            }
            return
        }
        let object = objects[i]
        let oldid = object.id
        object.decode(data: &data)
        if needsName{needsNames.insert(i)}
        needsName = false
        if object.id == 0 && object.parent != nil{
            needsNames.remove(i)
            object.namelabel?.removeFromParent()
            object.namelabel = nil
            if let i = tracked.firstIndex(of: object){
                trackArrows[i].removeFromParent()
                tracked.remove(at: i)
                trackArrows.remove(at: i)
            }
            object.id = oldid
            kill(object)
            object.id = 0
            object.removeFromParent()
        }
        if object.id != 0 && object.parent == nil{
            if ship.death == 0{
                for i in appear(object.position){
                    self.particles.append(i)
                    self.addChild(i)
                }
                self.addChild(object)
                object.alpha = 0
                let _ = timeout(1){
                    object.alpha = 1
                }
            }
        }
    }
    func sectorpos(_ x: Int, _ y: Int){
        planets.removeAll()
        objects.removeAll()
        objects.append(ship)
        game.sector(x: x, y: y) { [self] data in
            self.ip = data.2.ip
            gotIp()
            sector = data
            loaded -= 1
            if sector.0.count < 1{
                MIN_NODES_TO_START = 65
            }
            if loaded == 0{didLoad()}
        } err: { a in
            dmessage = a
            self.end()
            DispatchQueue.main.async{Disconnected.renderTo(skview)}
        } load: { frac in
            self.loading.run(.scaleX(to: frac, duration: 0.1).ease(.easeOut))
            self.loading.run(.moveTo(x: (frac - 1) * 150, duration: 0.1).ease(.easeOut))
        }
    }
    func didLoad(){
        planets.append(contentsOf: sector.0)
        for p in sector.0{
            let a = SKSpriteNode(imageNamed: p.superhot ? "arrow0" : "arrow")
            planetindicators.append(a)
            a.anchorPoint = CGPoint(x: 0.5, y: 1)
            a.setScale(0.25)
            p.removeFromParent()
            self.addChild(p)
        }
        for p in planetindicators{
            p.alpha = 0
        }
        ssecx = secx
        ssecy = secy
        vvelo = velo
        zzrot = zrot
        if view != nil{
            didMove(to: view!)
        }
    }
    func startData(){
        datastop()
        datastop = interval(0.1, { [self] in
            //send playerdata
            myseq += 1
            var data = Data([5, UInt8(myseq & 255)])
            ship.encode(data: &data)
            if hits.count > 7{
                hits.removeLast(hits.count - 7)
            }
            if shotObj != nil && objects.firstIndex(of: shotObj!) == nil{shotObj = nil}
            if planetShot != nil && planets[planetShot!].angry < 1770{planetShot = nil} //resend for half a second
            let a = min(needsNames.count, 7) * 16 + Int(planetShot != nil ? 128 : 0)
            data.write(UInt8(hits.count + Int(shotObj != nil ? 8 : 0) + a))
            if ship.shootFrequency == 0{usedShoot = false}
            newShoot = false
            for hit in hits{
                data.write(hit)
            }
            if shotObj != nil{
                let i = objects.firstIndex(of: shotObj!) ?? 0
                data.write(UInt32(i))
            }
            for i in needsNames.prefix(7){
                data.write(UInt32(i))
            }
            if planetShot != nil{data.write(UInt16(planetShot!))}
            data.write(Int32(lastSentEnergy))
            energyAmount += lastSentEnergy
            lastSentEnergy = 0
            shotObj = nil
            hits = []
            send(data)
            if adWatched{
                var dat = Data([])
                dat.write(critid(125))
                critical(dat)
                adWatched = false
            }
        })
    }
    func startHB(){
        datastop()
        datastop = interval(1, { [self] in
            send(Data([3]))
        })
    }
    func ping(){
        stopPing()
        stopPing = timeout(5){
            dmessage = "Lost connection!"
            self.end()
            Disconnected.renderTo(skview)
        }
    }
    func end(){
        inlightSpeed.removeFromParent()
        //release texture objects
        if ended{ return }
        ended = true
        send(Data([127]))
        for p in sector.0{
            p.namelabel?.removeFromParent()
            p.namelabel = nil
            p.angry = 0
            for c in p.children{
                if c.name != nil{(c as? SKSpriteNode)?.texture = nil}
                else {c.removeFromParent()}
            }
            p.smallTextures = false
            p.items = [ColonizeItem?](repeating: nil, count: 256)
            p.namelabel?.removeFromParent()
            p.namelabel = nil
            p.healthNode1.removeFromParent()
            p.healthNode2.removeFromParent()
            p.collectibles = []
        }
        send = {(_:Data) in}
        stopPing()
        datastop()
        
    }
    func recieved(_ d: Data){
        if ended{return}
        ping()
        guard view == skview else{return}
        var data = d
        var code: UInt8 = data.readunsafe()
        if code > 127{
            code -= 128
            if data.count < 1{return}
            let seq = data.readunsafe() as UInt8

            if !crits.contains(seq){return}
            crits.remove(seq)
        }
        if code == 1{
            authed = true
            loaded -= 1
            startHB()
            if loaded == 0{didLoad()}
            energyAmount = data.readunsafe()
            researchAmount = data.readunsafe()
            gemCount = data.readunsafe()
            let d = data.readunsafe() as Float
            if d > 0{
                advert.alpha = 0.5 //no more adverts
                let _ = timeout(Double(d)){
                    self.advert.alpha = 1
                }
            }
            var i = data.readunsafe() as UInt32
            while(i > 0){
                let x = Int(data.readunsafe() as Int32)
                let y = Int(data.readunsafe() as Int32)
                myplanets.insert("\(x) \(y)")
                if let p = find(x, y){
                    p.circle?.fillColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
                    p.ownedState = .yours
                }
                i -= 1
            }
            let ticks = data.readunsafe() as Float
            for p in planets{
                p.zRotation = (p.angularVelocity * CGFloat(ticks)).truncatingRemainder(dividingBy: .pi*2)
            }
            unlockedpacks = data.readunsafe() as UInt32
        }else if code == 127{
            dmessage = data.read() ?? "Disconnected!"
            end()
            DispatchQueue.main.async{Disconnected.renderTo(skview)}
        }else if code == 4{
            last = .now()
        }
        if code == 6{
            var seq = Int(data.readunsafe() as UInt8) + (netseq & -256)
            if seq < netseq{seq += 256}
            let diff = seq - netseq
            if diff > 127{return}
            netseq = seq
            let now = DispatchTime.now()
            last = (last + Double(diff / 10)).clamp(now, now.advanced(by: DispatchTimeInterval.milliseconds(300)))
            physics.asyncAfter(deadline: last){ [self] in
                var i = 1
                while data.count > 15{parseShip(&data, i);i += 1}
                if data.count >= 4{
                    level = Int(data.readunsafe() as UInt16)
                    xp = Int(data.readunsafe() as UInt16)
                    refreshXp()
                }
                for obj in objects.suffix(max(objects.count - i, 0)){
                    if let i = tracked.firstIndex(of: obj){
                        trackArrows[i].removeFromParent()
                        for child in tracked[i].children{if child.zPosition == 9{child.removeFromParent()}}
                        tracked.remove(at: i)
                        trackArrows.remove(at: i)
                    }
                    kill(obj)
                    obj.namelabel?.removeFromParent()
                    obj.namelabel = nil
                    obj.removeFromParent()
                }
                objects.removeLast(max(objects.count - i, 0))
            }
        }else if code == 7{
            var seq = Int(data.readunsafe() as UInt8) + (netseq & -256)
            if seq < netseq{seq += 256}
            let diff = netseq - seq
            if diff > 127{return}
            netseq = seq
            let now = DispatchTime.now()
            last = (last + Double(diff / 10)).clamp(now, now.advanced(by: DispatchTimeInterval.milliseconds(300)))
            energyAmount = data.readunsafe()
            researchAmount = data.readunsafe()
            physics.asyncAfter(deadline: last){ [self] in
                var i = 0
                while data.count > 15{parseShip(&data, i);i += 1}
                for obj in objects.suffix(max(objects.count - i, 0)){
                    if let i = tracked.firstIndex(of: obj){
                        trackArrows[i].removeFromParent()
                        for child in tracked[i].children{if child.zPosition == 9{child.removeFromParent()}}
                        tracked.remove(at: i)
                        trackArrows.remove(at: i)
                    }
                    kill(obj)
                    obj.namelabel?.removeFromParent()
                    obj.namelabel = nil
                    obj.removeFromParent()
                }
                objects.removeLast(max(objects.count - i, 0))
            }
        }else if code == 8{
            while data.count > 0{
                let id = Int(data.readunsafe() as UInt32)
                let name = data.read() ?? "Player"
                //guard needsNames.contains(id) else {continue}
                needsNames.remove(id)
                objects[id].namelabel?.removeFromParent()
                let label = SKLabelNode(text: "...")
                let badge = SKSpriteNode(imageNamed: "blank")
                objects[id].namelabel = label
                self.label(node: label, name, pos: objects[id].position.add(y: 30), size: 20, color: .green, font: "Menlo", zPos: 6)
                badge.position = CGPoint(x: -label.frame.width/2 - 5, y: 10)
                badge.anchorPoint.x = 1
                badge.setScale(0.2)
                label.addChild(badge)
                objects[id].badgeNode = badge
            }
        }else if code == 11{
            energyAmount = data.readunsafe()
            researchAmount = data.readunsafe()
            self.didBuy(true)
        }else if code == 12{
            while data.count > 0{
                let id = Int(data.readunsafe() as UInt16)
                self.planets[id].decode(data: &data)
            }
        }else if code == 2{
            //STATS DATA
            travel = Double(data.readunsafe() as Float)
            gemCount = data.readunsafe()
            var i = 0
            var oldmap: [String: Int] = [:]
            for i in missions{
                oldmap[i.name] = Int(i.gems)
            }
            while true{
                let name = data.read(lentype: Int8.self) ?? ""
                if name == ""{break}
                let lvl = Int(data.readunsafe() as UInt8)
                let left = CGFloat(data.readunsafe() as Float)
                let dat = MISSIONS[name]![lvl]
                let total = CGFloat(dat["amount"]!.number!)
                let mission = (name: missionTXTS[0][name]!.string!.split(separator: "%").joined(separator: "\(Int(total))"), val: total - left, max: total, gems: CGFloat(dat["gems"]!.number!), xp: CGFloat(dat["xp"]!.number!))
                oldmap[mission.name] = nil
                if i < missions.count{
                    if missions[i].name == mission.name && i < stats.missions.count{
                        //just different value
                        stats.missions[i].fill.xScale = (mission.val / mission.max) * 5.9
                        let intval = Int(mission.val)
                        stats.missions[i].text.text = "\(CGFloat(intval) == mission.val ? "\(intval)" : String(format: "%.2f", mission.val)) / \(Int(mission.max))"
                    }
                    missions[i] = mission
                }else{
                    missions.append(mission)
                }
                i += 1
            }
            while i < missions.count{
                missions.removeLast()
            }
            for (n, g) in oldmap{
                missionCompleteNotification(missionTxt: n, gems: g)
                removeWallIcons();wallIcons()
                break
            }
        }else if code == 13{
            self.didBuy(false)
        }else if code == 15{
            energyAmount = data.readunsafe()
            researchAmount = data.readunsafe()
            didChangeItem(true)
        }else if code == 16{
            didChangeItem(false)
        }else if code == 18{
            energyAmount = data.readunsafe()
            researchAmount = data.readunsafe()
            didCollect(true)
        }else if code == 19{
            didCollect(false)
        }else if code == 21{
            didMake(false)
        }else if code == 22{
            energyAmount = data.readunsafe()
            researchAmount = data.readunsafe()
            didMake(true)
        }else if code == 24{
            gemCount = data.readunsafe()
            if !switch2{self.run(SKAction.playSoundFileNamed("gemcollect.mp3", waitForCompletion: false))}
        }else if code == 27{
            energyAmount = data.readunsafe()
            researchAmount = data.readunsafe()
        }else if code == 30{
            energyAmount = data.readunsafe()
        }else if code == 126{
            guard let g: Float = data.read() else {return}
            gemCount = g
            if !switch2{self.run(SKAction.playSoundFileNamed("gemcollect.mp3", waitForCompletion: false))}
            let d = data.readunsafe() as Float
            
            if d > 0{
                advert.alpha = 0.5 //no more adverts
                let _ = timeout(Double(d)){
                    self.advert.alpha = 1
                }
            }
        }else if code == 123 || code == 124{
            DisplayWARNING(code == 123 ? "pack bought successfully" : "error", code == 123 ? .achieved : .warning)
            if code == 123{
                let i = Int(data.readunsafe() as UInt8)
                unlockedpacks |= 1 << i
                packs[i - 1].alpha = 0.5
                gemCount = data.readunsafe()
                if !switch2{self.run(SKAction.playSoundFileNamed("gemcollect.mp3", waitForCompletion: false))}
            }
        }else if code == 120{
            let g = gemCount
            gemCount = data.readunsafe() as Float
            DisplayWARNING("+\(gemCount - g) gems", .achieved)
            if !switch2{self.run(SKAction.playSoundFileNamed("gemcollect.mp3", waitForCompletion: false))}
        }
    }
    
    func gotIp(){
        
        if !step1Completed{step1Completed = true;return}
        let player = GKLocalPlayer.local
        if player.isAuthenticated && creds == nil{
            player.fetchItems(forIdentityVerificationSignature: { url, sig, salt, time, err in
                if err != nil || url == nil || sig == nil{
                    creds = (url: URL(string: "http://apple.com")!, sig: Data(), salt: Data(), time: 1, id: ID)
                }else{
                    creds = (url: url!, sig: sig!, salt: salt ?? Data(), time: time, id: GKLocalPlayer.local.teamPlayerID)
                }
                self.gotIp()
            })
            return
        }else if creds == nil{
            creds = (url: URL(string: "http://apple.com")!, sig: Data(), salt: Data(), time: 1, id: ID)
        }
        send = connect(IPOVERRIDE ?? ip, recieved)
        var data = Data()
        data.write(critid(0))
        data.write(UInt16(VERSION))
        data.write(creds!.url.absoluteString, lentype: UInt8.self)
        data.write([UInt8](creds!.sig), lentype: UInt16.self)
        data.write([UInt8](creds!.salt), lentype: UInt8.self)
        data.write(creds!.id, lentype: UInt8.self)
        data.write(creds!.time)
        var local = GKLocalPlayer.local.alias
        if local == "Unknown"{
            let id = ID.prefix(NAMES.count)
            var i = 0
            local = ""
            for id in id.map({ e in return "0123456789abcdef".index(of: e) ?? ("ABCDEF".index(of: e)! + 10)}){
                local += NAMES[i][Int(id)]
                i += 1
            }
        }
        self.name = local
        data.write(local, lentype: UInt8.self)
        data.write(UInt16(self.size.width + self.size.height))
        critical(data, abandoned: {
            dmessage = "Could not connect"
            //end()
            DispatchQueue.main.async{Disconnected.renderTo(skview)}
        })
    }
}
