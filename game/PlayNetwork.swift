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
class PlayNetwork: PlayConvenience{
    var DEBUG_TXT = SKLabelNode(fontNamed: "Menlo")
    var MIN_NODES = 70
    var ship = Object(radius: 15, mass: 100, texture: .named("ship1"))
    var hits: [UInt32] = []
    var planets: [Planet] = []
    var planetindicators: [SKSpriteNode] = []
    var cam = SKCameraNode()
    var particles: [Particle] = []
    var objects: [Object] = []
    var a = {}
    var send = {(_: Data) -> () in}
    var ready = false
    var sector: UInt32 = 0
    var istop = {}
    var loaded = 2
    var usedShoot = false
    var newShoot = false
    var coolingDown = false
    var shotObj: Object? = nil
    var usingConstantLazer = false
    var tracked: [Object] = []
    var trackArrows: [SKSpriteNode] = []
    var loadstack: (p: [Planet]?, size: CGSize?, pos: CGPoint?) = (p: nil, size: nil, pos: nil)
    var delay: Double = 0
    let inlightSpeed = SKAudioNode(fileNamed: "InLightSpeed.wav")
    var thrustSound = SKAudioNode(fileNamed: "thrust.wav")
    let loading = SKShapeNode(rect: CGRect(x: -150, y: 0, width: 300, height: 3))
    var needsNames = Set<Int>()
    var auth_ = false
    var SEQ = UInt8(255)
    var crits = Set<UInt8>()
    var lastSentEnergy = 0.0
    func critid(_ a: UInt8) -> UInt16{
        //low: a
        //high: SEQ
        if a > 127{
            fatalError("Message code cannot be higher than 127")
        }
        if SEQ < 255{SEQ += 1}else{SEQ = 0}
        return UInt16(a + (SEQ<<8) + 128)
    }
    func critical(_ dat: Data, resend: Double = 0.5, abandon: Int = 10, abandoned: @escaping () -> () = {}, sent: @escaping () -> () = {}){
        let s = SEQ
        crits.insert(s)
        var a = {}
        send(dat)
        var tries = 1
        a = interval(resend){ [self] in
            if ended{return a()}
            if !crits.contains(s){a();sent()}else if tries == abandon{
                abandoned()
                a()
            }else{
                send(dat)
                tries += 1
            }
        }
    }
    func gameAuthed(){
        if auth_{return}
        gotIp()
        auth_ = true
    }
    func gameGuest(){
        if auth_{return}
        gotIp()
        auth_ = true
    }
    func kill(_ n: Object){
        if n.death > 100{
            //explode
            for i in disappear(n.position){
                self.particles.append(i)
                self.addChild(i)
            }
        }else if n.death > 0{
            //fade
            n.run(SKAction.move(by: CGVector(dx: n.velocity.dx * CGFloat(gameFPS), dy: CGFloat(n.velocity.dy) * CGFloat(gameFPS)), duration: 1))
        }else{n.removeFromParent()}
    }
    var needsName = false
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
            kill(object)
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
            (loadstack.p, (pos: loadstack.pos, size: loadstack.size), _) = data
            loaded -= 1
            if loadstack.p!.count < 1{
                MIN_NODES = 65
            }
            if loaded == 0{didLoad()}
        } err: { a in
            dmessage = a
            self.end()
            DispatchQueue.main.async{Disconnected.renderTo(skview)}
        } ipget: {self.ip = $0;self.gotIp()} load: { frac in
            self.loading.run(.scaleX(to: frac, duration: 0.1).ease(.easeOut))
            self.loading.run(.moveTo(x: (frac - 1) * 150, duration: 0.1).ease(.easeOut))
        }
    }
    func didLoad(){
        planets.append(contentsOf: loadstack.p!)
        for p in loadstack.p!{
            let a = SKSpriteNode(imageNamed: "arrow")
            planetindicators.append(a)
            a.anchorPoint = CGPoint(x: 0.5, y: 1)
            a.setScale(0.25)
            p.removeFromParent()
            self.addChild(p)
        }
        for p in planetindicators{
            p.alpha = 0
        }
        ready = true
        if view != nil{
            didMove(to: view!)
        }
    }
    func startData(){
        istop()
        istop = interval(0.1, { [self] in
            //send playerdata
            var data = Data([5])
            ship.encode(data: &data)
            if hits.count > 7{
                hits.removeLast(hits.count - 7)
            }
            if shotObj != nil && objects.firstIndex(of: shotObj!) == nil{shotObj = nil}
            data.write(UInt8(hits.count + (shotObj != nil ? 8 : 0) + min(needsNames.count, 15) * 16))
            if !usingConstantLazer || coolingDown{usedShoot = false}
            newShoot = false
            for hit in hits{
                data.write(hit)
            }
            if shotObj != nil, let i = objects.firstIndex(of: shotObj!){
                data.write(UInt32(i))
            }
            for i in needsNames.prefix(15){
                data.write(UInt32(i))
            }
            data.write(Int16(energyAmount - lastSentEnergy))
            lastSentEnergy = energyAmount
            shotObj = nil
            hits = []
            send(data)
        })
    }
    func startHB(){
        istop()
        istop = interval(1, { [self] in
            send(Data([3]))
        })
    }
    let physics = DispatchQueue.main
    func ping(){
        a()
        a = timeout(5){
            dmessage = "Lost connection!"
            self.end()
            Disconnected.renderTo(skview)
        }
    }
    func didInit(){
        DEBUG_TXT.fontSize = 15
        DEBUG_TXT.position = pos(mx: -0.5, my: 0.5, x: 20, y: -20)
        DEBUG_TXT.color = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        DEBUG_TXT.fontColor = .white
        DEBUG_TXT.horizontalAlignmentMode = .left
        DEBUG_TXT.verticalAlignmentMode = .top
        DEBUG_TXT.numberOfLines = 20
        DEBUG_TXT.zPosition = .infinity
        cam.addChild(DEBUG_TXT)
        api.sector(completion: sectorpos)
    }
    var ended = false
    func end(){
        if !ended{send(Data([127]))}
        inlightSpeed.removeFromParent()
        //release texture objects
        for p in loadstack.p ?? []{
            p.texture = nil
            for c in p.children{
                if c.name != nil{(c as? SKSpriteNode)?.texture = nil}
            }
        }
        send = {(_:Data) in}
        a()
        istop()
        ended = true
    }
    func didBuy(_ success: Bool){}
    func didChangeItem(_ success: Bool){}
    func didCollect(_ success: Bool){}
    var p = false
    var last: DispatchTime = .now()
    var authed = false
    var ip: String = ""
    
    func recieved(_ d: Data){
        if ended{return}
        guard view == skview else{return}
        var data = d
        var code: UInt8 = data.readunsafe()
        if code > 127{
            code -= 128
            if data.count < 1{return}
            let s = data.readunsafe() as UInt8
            if !crits.contains(s){return}
            crits.remove(s)
        }
        if code == 1{
            ping()
            authed = true
            loaded -= 1
            if loaded == 0{didLoad()}
            startHB()
            let a: UInt64 = data.readunsafe()
            energyAmount = Double(a & 0x0000FFFFFFFFFFFF)
            lastSentEnergy = energyAmount
        }else if code == 127{
            dmessage = data.read() ?? "Disconnected!"
            end()
            DispatchQueue.main.async{Disconnected.renderTo(skview)}
        }else if code == 4{
            ping()
            last = .now()
        }
        guard ship.controls else {return}
        if code == 6{
            ping()
            delay = Double(data.readunsafe() as UInt8) / 100
            last = (last + delay).clamp(.now(), .now().advanced(by: DispatchTimeInterval.milliseconds(MAX_DELAY)))
            physics.asyncAfter(deadline: last){ [self] in
                var i = 1
                while data.count > 13{parseShip(&data, i);i += 1}
                for e in objects.suffix(max(objects.count - i, 0)){
                    if let i = tracked.firstIndex(of: e){
                        trackArrows[i].removeFromParent()
                        for a in tracked[i].children{if a.zPosition == 9{a.removeFromParent()}}
                        tracked.remove(at: i)
                        trackArrows.remove(at: i)
                    }
                    kill(e)
                    e.namelabel?.removeFromParent()
                    e.namelabel = nil
                    e.removeFromParent()
                }
                objects.removeLast(max(objects.count - i, 0))
            }
        }else if code == 7{
            ping()
            delay = Double(data.readunsafe() as UInt8) / 100
            last = (last + delay).clamp(.now(), .now().advanced(by: DispatchTimeInterval.milliseconds(MAX_DELAY)))
            physics.asyncAfter(deadline: last){ [self] in
                var i = 0
                while data.count > 13{parseShip(&data, i);i += 1}
                for e in objects.suffix(max(objects.count - i, 0)){
                    if let i = tracked.firstIndex(of: e){
                        trackArrows[i].removeFromParent()
                        for a in tracked[i].children{if a.zPosition == 9{a.removeFromParent()}}
                        tracked.remove(at: i)
                        trackArrows.remove(at: i)
                    }
                    kill(e)
                    e.namelabel?.removeFromParent()
                    e.namelabel = nil
                    e.removeFromParent()
                }
                objects.removeLast(max(objects.count - i, 0))
            }
        }else if code == 8{
            while data.count > 0{
                let id = Int(data.readunsafe() as UInt32)
                let name = data.read() ?? "Player"
                //guard needsNames.contains(id) else {continue}
                needsNames.remove(id)
                objects[id].namelabel = SKLabelNode(text: "...")
                label(node: objects[id].namelabel!, name, pos: CGPoint(x: objects[id].position.x, y: objects[id].position.y + 30), size: 20, color: .green, font: "Menlo")
                
            }
        }else if code == 11{
            print("colonize ok")
            self.didBuy(true)
            //complete colonization
        }else if code == 12{
            while data.count > 0{
                let id = Int(data.readunsafe() as UInt16)
                planets[id].decode(data: &data)
            }
        }else if code == 13{
            print("colonize not ok")
            self.didBuy(false)
        }else if code == 15 || code == 16{
            didChangeItem(code == 15)
        }else if code == 18{
            let a = Double(data.readunsafe() as UInt32)
            energyAmount += a
            lastSentEnergy += a
            didCollect(true)
        }else if code == 19{
            didCollect(false)
        }
    }
    
    func gotIp(){
        if !p{p = true;return}
        let player = GKLocalPlayer.local
        if player.isAuthenticated && creds == nil{
            player.fetchItems(forIdentityVerificationSignature: { url, sig, salt, time, err in
                if err != nil || url == nil || sig == nil{
                    creds = (url: URL(string: "http://example.com")!, sig: Data(), salt: Data(), time: 1, id: "")
                }else{
                    creds = (url: url!, sig: sig!, salt: salt ?? Data(), time: time, id: GKLocalPlayer.local.teamPlayerID)
                }
                self.gotIp()
            })
            return
        }else if creds == nil{
            creds = (url: URL(string: "http://example.com")!, sig: Data(), salt: Data(), time: 1, id: "")
        }
        send = connect("192.168.1.248:65152", recieved)
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
            let id = UIDevice.current.identifierForVendor?.uuidString.prefix(2) ?? "00"
            local = "Guest \(%(UInt8(id, radix: 16) ?? 0))"
        }
        data.write(local, lentype: UInt8.self)
        data.write(UInt16(self.size.width + self.size.height))
        critical(data, abandoned: { [self] in
            dmessage = "Could not connect"
            end()
            DispatchQueue.main.async{Disconnected.renderTo(skview)}
        })
    }
}
