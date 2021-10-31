//
//  PlayNetwork.swift
//  game
//
//  Created by Matthew on 01/10/2021.
//

import Foundation
import SpriteKit

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
    var coolingDown = false
    var shotObj: Object? = nil
    var usingConstantLazer = false
    var tracked: [Object] = []
    var trackArrows: [SKSpriteNode] = []
    var loadstack: (p: [Planet]?, size: CGSize?, pos: CGPoint?) = (p: nil, size: nil, pos: nil)
    var delay: Double = 0
    let inlightSpeed = SKAudioNode(fileNamed: "InLightSpeed.wav")
    
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
    
    
    func parseShip(_ data: inout Data, _ i: Int){
        guard i < objects.count else {
            let object = Object()
            object.decode(data: &data)
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
        if object.id == 0 && object.parent != nil{
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
        } ipget: {ip in self.gotIp(ip)}
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
            data.write(UInt8(hits.count + (shotObj != nil ? 8 : 0)))
            if !usingConstantLazer || coolingDown{usedShoot = false}
            for hit in hits{
                data.write(hit)
            }
            if shotObj != nil, let i = objects.firstIndex(of: shotObj!){
                data.write(UInt32(i))
            }
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
            self.send(Data([127]))
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
        api.sector(completion: sectorpos)
    }
    var ended = false
    func end(){
        inlightSpeed.run(stopSound)
        //release texture objects
        for p in loadstack.p ?? []{
            p.texture = nil
        }
        send = {(_:Data) in}
        a()
        istop()
        ended = true
    }
    var last: DispatchTime = .now()
    func gotIp(_ ip: String){
        print("got ip")
        var stopAuth = {}
        var authed = false
        send = connect(ip){[self](d) in
            if ended{return}
            guard view == skview else{return}
            var data = d
            let code: UInt8 = data.readunsafe()
            if code == 1{
                if !authed{
                    authed = true
                    stopAuth()
                    loaded -= 1
                    if loaded == 0{didLoad()}
                    startHB()
                }
                return
            }
            guard ship.controls else {return}
            if code == 127{
                dmessage = data.read() ?? "Disconnected!"
                end()
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
            }else if code == 4{
                ping()
                last = .now()
            }else if code == 6{
                ping()
                delay = Double(data.readunsafe() as UInt8) / 100
                last = (last + delay).clamp(.now(), .now().advanced(by: DispatchTimeInterval.milliseconds(MAX_DELAY)))
                physics.asyncAfter(deadline: last){ [self] in
                    var i = 1
                    while data.count > 19{parseShip(&data, i);i += 1}
                }
                
            }else if code == 7{
                ping()
                delay = data.readunsafe()
                last = last + delay
                if .now().advanced(by: DispatchTimeInterval.milliseconds(MAX_DELAY)) < last || .now() > last{last = .now()}
                physics.asyncAfter(deadline: last){ [self] in
                    var i = 0
                    while data.count > 19{parseShip(&data, i);i += 1}
                    for e in objects.suffix(max(objects.count - i, 0)){
                        if let i = tracked.firstIndex(of: e){
                            trackArrows[i].removeFromParent()
                            tracked.remove(at: i)
                            trackArrows.remove(at: i)
                        }
                        kill(e)
                        e.removeFromParent()
                    }
                    objects.removeLast(max(objects.count - i, 0))
                }
            }
        }
        let hello = try! messages.hello(name: "BlobKat")
        var tries = 0
        stopAuth = interval(0.5) { [self] in
            tries += 1
            if tries > 10{
                stopAuth()
                dmessage = "Could not connect"
                end()
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
                return
            }
            send(hello)
        }
    }
}
