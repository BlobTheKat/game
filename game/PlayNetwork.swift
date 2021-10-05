//
//  PlayNetwork.swift
//  game
//
//  Created by Matthew on 01/10/2021.
//

import Foundation
import SpriteKit

class PlayNetwork: PlayConvenience{
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
    var loadstack: (p: [Planet]?, size: CGSize?, pos: CGPoint?) = (p: nil, size: nil, pos: nil)
    var delay: UInt8 = 0
    func parseShip(_ data: inout Data, _ i: Int){
        guard i < objects.count else {
            let object = Object()
            object.decode(data: &data)
            objects.append(object)
            if object.id != 0{DispatchQueue.main.async{self.addChild(object)}}
            return
        }
        let object = objects[i]
        object.decode(data: &data)
        DispatchQueue.main.async{
            if object.id == 0 && object.parent != nil{object.removeFromParent()}
            if object.id != 0 && object.parent == nil{self.addChild(object)}
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
            Disconnected.renderTo(skview)
        } ipget: { ip in
            self.gotIp(ip)
        }
    }
    func didLoad(){
        planets.append(contentsOf: loadstack.p!)
        for p in loadstack.p!{
            planetindicators.append(SKSpriteNode(imageNamed: "arrow"))
            p.removeFromParent()
            self.addChild(p)
            p.zPosition = -1
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
            if hits.count > 10{
                hits.removeLast(hits.count - 10)
            }
            data.write(UInt8(hits.count))
            for hit in hits{
                data.write(hit)
            }
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
        a = timeout(5, {
            self.send(Data([127]))
            dmessage = "Lost connection!"
            Disconnected.renderTo(skview)
        })
    }
    func didInit(){
        api.sector(completion: sectorpos)
    }
    func gotIp(_ ip: String){
        var stopAuth = {}
        var authed = false
        send = connect(ip){[self](d) in
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
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
            }else if code == 4{
                ping()
            }else if code == 6{
                ping()
                delay = data.readunsafe()
                physics.async{ [self] in
                    var i = 1
                    while data.count > 19{parseShip(&data, i);i += 1}
                }
            }else if code == 7{
                ping()
                delay = data.readunsafe()
                physics.async { [self] in
                    var i = 0
                    while data.count > 19{parseShip(&data, i);i += 1}
                    objects.removeLast(objects.count - i - 1)
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
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
                return
            }
            send(hello)
        }
    }
}
