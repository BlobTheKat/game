//
//  Constants.swift
//  game
//
//  Created by Matthew on 05/08/2021.
//

import Foundation
import SpriteKit
import Network

let MAX_DELAY = 300 //in milliseconds, the maximum amount of time a packet can be delayed for smoothness

//more = smoother, more delayed
//less = faster, rougher

let G: CGFloat = 0.0001
let fsmall: CGFloat = 32
let fmed: CGFloat = 48
let fbig: CGFloat = 72
let gameFPS = 60.0
let build = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "null"

//star texture size * 2
let SS: CGFloat = 2440

var stop: [() -> ()] = []

func bg(_ a: @escaping () -> ()){DispatchQueue.global(qos: .background).async(execute: a)}

struct servers{
    static let uswest = ""
    static let backup = ""
    static let home = "192.168.1.64"
}

extension SKTexture{
    static func named(_ a: String) -> SKTexture{
        return SKTexture(imageNamed: a)
    }
}
enum JSON{
    init(_ v: Any?){
        guard let a = v else{self = .null;return}
        if a is Double{
            self = .number(a as! Double)
        }else if a is String{
            self = .string(a as! String)
        }else if a is [Any]{
            let arr = a as! [Any]
            var res: [JSON] = []
            for a in arr{
                res.append(JSON(a))
            }
            self = .array(res)
        }else if a is Bool{
            self = .bool(a as! Bool)
        }else if a is [String: Any]{
            let arr = a as! [String: Any]
            var res: [String: JSON] = [:]
            for (k, a) in arr{
                res[k] = JSON(a)
            }
            self = .map(res)
        }else{
            self = .null
        }
    }
    
    case map([String: JSON])
    case array([JSON])
    case number(Double)
    case string(String)
    case bool(Bool)
    case null
}
typealias GameData = [[String: JSON]]
extension GameData{
    init?(_ path: String){
        guard let dat = FileManager.default.contents(atPath: Bundle.main.path(forResource: path, ofType: nil) ?? ""), let s = String(data: dat, encoding: .utf8) else {
            return nil
        }
        self.init(data: s)
    }
    init(data s: String){
        let text = s.split(separator: "\n", omittingEmptySubsequences: false).map { a in
            return String(a.prefix(upTo: a.firstIndex(of: "#") ?? a.endIndex))
        }
        var i = 0
        self = []
        while i < text.count{
            self.append([:])
            while i < text.count && text[i] != ""{
                let t = text[i].split(separator: ":")
                guard t.count > 1 else{self[self.count-1][String(t[0])] = .null;i+=1;continue}
                let value = t[1].trimmingCharacters(in: CharacterSet([" ", "\u{0009}"]))
                if let a = Double(value){
                    self[self.count-1][String(t[0])] = .number(a)
                }else if value.lowercased() == "yes" || value.lowercased() == "true"{
                    self[self.count-1][String(t[0])] = .bool(true)
                }else if value.lowercased() == "no" || value.lowercased() == "false"{
                    self[self.count-1][String(t[0])] = .bool(false)
                }else{
                    self[self.count-1][String(t[0])] = .string(String(value))
                }
                i += 1
            }
            i += 1
        }
    }
    static func from(location: String, completion: @escaping (GameData?) -> ()){
        fetch("https://aaa.blobkat.repl.co\(location)") { (d: String) in
            completion(GameData(data: d))
        } _: { s in
            completion(nil)
        }
    }
}
var smap = GameData("/map")!
var ships = GameData("/ships")!
var asteroids = GameData("/asteroids")!
let VERSION = 1
typealias SectorData = ([Planet], (pos: CGPoint, size: CGSize), (name:String,ip:String))
extension CGPoint: Hashable{
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
}
var sectors: [CGPoint: [SectorData]] = [:]
var mapnodes: [CGPoint: SKNode] = [:]
var loaded: Set<CGPoint> = []
var images: [String: Data] = [:]
var textures: [String: SKTexture] = [:]

func emptytextures(s: SectorData){
    textures.removeAll()
    for p in s.0{
        p.texture = nil
        for c in p.children{
            (c as? SKSpriteNode)?.texture = nil
        }
    }
}
/*func image(_ url: String, completion: @escaping (SKTexture) -> (), err: @escaping (String) -> ()){
    if let i = textures[url]{
        DispatchQueue.main.async{completion(i)}
        return
    }
    if let i = images[url]{
        DispatchQueue.main.async{
            textures[url] = SKTexture(image: UIImage(data: i)!)
            completion(textures[url]!)
        }
        return
    }
    
    fetch(url) { (data: Data) in
        if data[0] == 123{
            err("Missing Image")
            return
        }
        if let a = UIImage(data: data){
            images[url] = data
            textures[url] = SKTexture(image: a)
            completion(textures[url]!)
        }else{
            err("Broken Image")
            return
        }
    } _: {e in
        err(e)
    }

}*/
let REGIONSIZE = 500000
func exists(px: Int, py: Int) -> Bool{
    let delegated = CGPoint(x: 0, y: 0)//fdiv(px, REGIONSIZE), y: fdiv(py, REGIONSIZE))
    if let a = sectors[delegated]{
        if loaded.contains(delegated){
            return true
        }
        for i in a{
            if i.1.pos.x == CGFloat(px) && i.1.pos.y == CGFloat(py){
                return true
            }
        }
    }
    return false
}
func sector(x: Int, y: Int, completion: @escaping (SectorData) -> (), err: @escaping (String) -> (), ipget: @escaping (String) -> (), load: @escaping (CGFloat) -> (), _ a: [SectorData] = []){
    let regionx = 0//fdiv(x, REGIONSIZE)
    let regiony = 0//fdiv(y, REGIONSIZE)
    guard sectors[CGPoint(x: regionx, y: regiony)] == nil else {
        let x = CGFloat(x)
        let y = CGFloat(y)
        for sector in sectors[CGPoint(x: regionx, y: regiony)]!{
            let (_, (pos: pos, size: size), (name: _, ip: ip)) = sector
            let w2 = size.width / 2
            let h2 = size.height / 2
            if x > pos.x - w2 && x < pos.x + w2 && y > pos.y - h2 && y < pos.y + h2{
                ipget(ip)
                //reinstate textures
                for p in sector.0{
                    p.texture = SKTexture(imageNamed: p.name!)
                    for c in p.children{
                        (c as? SKSpriteNode)?.texture = SKTexture(imageNamed: c.name!)
                    }
                }
                completion(sector)
                return
            }
        }
        if !loaded.contains(CGPoint(x: regionx, y: regiony)){
            let a = sectors[CGPoint(x: regionx, y: regiony)]
            sectors[CGPoint(x: regionx, y: regiony)] = nil
            sector(x: Int(x), y: Int(y), completion: completion, err: err, ipget: ipget, load: load, a ?? [])
            return
        }
        err("Spacetime continuum ends here...")
        return
    }
    sectors[CGPoint(x: regionx, y: regiony)] = a
    fetch("https://region-\(regionx)-\(regiony).ksh3.tk") { (d: Data) in
        var data = d
        guard let _ = data.read() else {return}
        var found = false
        while data.count > 0{
            let xx = regionx * REGIONSIZE
            let yy = regiony * REGIONSIZE
            var px = Int(data.readunsafe() as Int16) * 1000 + xx
            var py = Int(data.readunsafe() as Int16) * 1000 + yy
            let w = Int(data.readunsafe() as UInt16) * 1000
            let h = Int(data.readunsafe() as UInt16) * 1000
            px += w / 2
            py += h / 2
            let exists = exists(px: px, py: py)
            let nl = data.readunsafe() as Int16
            let ipl = data.readunsafe() as Int16
            var len = data.readunsafe() as UInt32
            let name = String(bytes: data.read(count: Int(nl)) as [UInt8], encoding: .utf8)!
            let ip = String(bytes: data.read(count: Int(ipl)) as [UInt8], encoding: .utf8)!
            var planets = [Planet]()
            var s = (planets, (pos: CGPoint(x: px, y: py), size: CGSize(width: w, height: h)),(name:name,ip:ip))
            let current = x > px - w/2 && x < px + w/2 && y > py - h/2 && y < py + h/2
            found = found || current
            if current{ipget(ip)}
            while(len > 0){
                len -= 1
                let id = data.readunsafe() as UInt16
                if id & 1 == 1{
                    let _ = data.read(count: 8 + Int(id & 6) + Int(id & 8) / 2) as [UInt8]
                    continue
                }
                let x = Int(data.readunsafe() as Int32)
                let y = Int(data.readunsafe() as Int32)
                let p = Planet(radius: CGFloat(id / 16), mass: CGFloat(data.readunsafe() as Int32))
                p.position = CGPoint(x: x, y: y)
                if id & 2 != 0{
                    p.producesParticles = true
                    p.particle = particles[Int(data.readunsafe() as Int16)]
                }
                if id & 4 != 0{
                    p.angularVelocity = CGFloat(data.readunsafe() as Float)
                }
                p.superhot = id & 8 != 0
                if !exists{planets.append(p)}
                var img = (data.read(lentype: UInt8.self) ?? "none").split(separator: " ").map({a in return String(a)})
                if img.count < 1{img.append("none")}
                if current && !exists{
                    var i = 0
                    for img in img{
                        if i == 0{
                            p.texture = SKTexture(imageNamed: img)
                            p.size = p.texture!.size()
                            p.name = img
                        }else{
                            let node = SKSpriteNode()
                            p.addChild(node)
                            node.texture = SKTexture(imageNamed: img)
                            node.size = node.texture!.size()
                            node.name = img
                        }
                        i += 1
                    }
                }
            }
            s.0 = planets
            if px < xx || px > xx + REGIONSIZE || py < yy || py > yy + REGIONSIZE{
                let delegated = CGPoint(x: 0, y: 0)//fdiv(px, REGIONSIZE), y: fdiv(py, REGIONSIZE))
                if sectors[delegated] != nil{
                    sectors[delegated]!.append(s)
                }else{
                    sectors[delegated] = [s]
                }
            }else{sectors[CGPoint(x: regionx, y: regiony)]!.append(s)}
            if current{completion(s)}
        }
        if !found{err("Spacetime continuum ends here...");return}
        loaded.insert(CGPoint(x: regionx, y: regiony))
    } _: { e in
        err(e)
    }
    
}
