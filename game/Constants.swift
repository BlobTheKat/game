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
func sectori(_ id: Int, completion: @escaping ([Planet], CGSize) -> (), err: @escaping (String) -> ()){
    guard case .string(let path) = smap[id]["path"] else {return}
    GameData.from(location: path) { data in
        guard let data = data else{return err("Could not load sector")}
        var planetarr: [Planet] = []
        
//read from server and initiate variable for width and height of sectors
        guard case .number(let sectorWidth) = smap[id]["w"] else {return}
        guard case .number(let sectorHeight) = smap[id]["h"] else {return}
        
        for object in data{
            var id: Int? = nil
            if case .number(let i) = object["id"] {id=Int(i)}
            let dat = id == nil ? object : asteroids[id!]
            guard case .number(let radius) = dat["radius"] else {continue}
            guard case .number(let mass) = dat["mass"] else {continue}
            guard case .number(let x) = object["x"] else {continue}
            guard case .number(let y) = object["y"] else {continue}
            guard case .number(let spin) = dat["spin"] else {continue}
            guard case .string(let texture) = dat["texture"] else {continue}
            let t = SKTexture(imageNamed: texture)
            if id == nil{
                let i = Planet(radius: CGFloat(radius), mass: CGFloat(mass), texture: t)
                i.angularVelocity = CGFloat(spin)
                i.position.x = CGFloat(x)
                i.position.y = CGFloat(y)
                if case .bool(let hot) = dat["superhot"]{i.superhot = hot}
                if case .number(let particle) = dat["particle"]{
                    i.producesParticles = true
                    i.particle = particles[Int(particle)]
                }
                if case .number(let frequency) = dat["fequency"]{
                  i.particleFrequency = frequency
                }
                planetarr.append(i)
            }
        }
        completion(planetarr, CGSize(width: sectorWidth, height: sectorHeight))
    }
}

let REGIONSIZE = 500000
func exists(px: Int, py: Int) -> Bool{
    let delegated = CGPoint(x: fdiv(px, REGIONSIZE), y: fdiv(py, REGIONSIZE))
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
func sector(x: Int, y: Int, completion: @escaping (SectorData) -> (), err: @escaping (String) -> (), ipget: @escaping (String) -> (), _ a: [SectorData] = []){
    let regionx = fdiv(x, REGIONSIZE)
    let regiony = fdiv(y, REGIONSIZE)
    guard sectors[CGPoint(x: regionx, y: regiony)] == nil else {
        let x = CGFloat(x)
        let y = CGFloat(y)
        for sector in sectors[CGPoint(x: regionx, y: regiony)]!{
            let (_, (pos: pos, size: size), (name: _, ip: ip)) = sector
            let w2 = size.width / 2
            let h2 = size.height / 2
            if x > pos.x - w2 && x < pos.x + w2 && y > pos.y - h2 && y < pos.y + h2{
                ipget(ip)
                completion(sector)
                return
            }
        }
        if !loaded.contains(CGPoint(x: regionx, y: regiony)){
            let a = sectors[CGPoint(x: regionx, y: regiony)]
            sectors[CGPoint(x: regionx, y: regiony)] = nil
            sector(x: Int(x), y: Int(y), completion: completion, err: err, ipget: ipget, a ?? [])
            return
        }
        err("Spacetime continuum ends here...")
        return
    }
    sectors[CGPoint(x: regionx, y: regiony)] = a
    fetch("https://region-\(regionx)-\(regiony).ksh3.tk") { (d: Data) in
        var data = d
        guard let bucketname = data.read() else {return}
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
            var DONE = 0
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
                let img = "https://firebasestorage.googleapis.com/v0/b/\(bucketname).appspot.com/o/\(data.read(lentype: Int8.self) ?? "default").png?alt=media"
                if current && !exists{
                    DONE += 1
                    fetch(img) { (data: Data) in
                        if data[0] == 123{
                            err("Broken Image")
                            loaded.remove(CGPoint(x: regionx, y: regiony))
                            return
                        }
                        if let a = UIImage(data: data){
                            p.texture = SKTexture(image: a)
                            p.size = p.texture!.size()
                        }else{
                            err("Broken Image")
                            loaded.remove(CGPoint(x: regionx, y: regiony))
                            return
                        }
                        DONE -= 1
                        if DONE == 0{
                            s.0 = planets
                            if px < xx || px > xx + REGIONSIZE || py < yy || py > yy + REGIONSIZE{
                                let delegated = CGPoint(x: fdiv(px, REGIONSIZE), y: fdiv(py, REGIONSIZE))
                                if sectors[delegated] != nil{
                                    sectors[delegated]!.append(s)
                                }else{
                                    sectors[delegated] = [s]
                                }
                            }else{sectors[CGPoint(x: regionx, y: regiony)]!.append(s)}
                            completion(s)
                        }
                    } _: {e in
                        err(e)
                    }
                }
            }
            if !current && !exists{
                if px < xx || px > xx + REGIONSIZE || py < yy || py > yy + REGIONSIZE{
                    let delegated = CGPoint(x: fdiv(px, REGIONSIZE), y: fdiv(py, REGIONSIZE))
                    if sectors[delegated] != nil{
                        sectors[delegated]!.append(s)
                    }else{
                        sectors[delegated] = [s]
                    }
                }else{sectors[CGPoint(x: regionx, y: regiony)]!.append(s)}
            }
        }
        if !found{err("Spacetime continuum ends here...");return}
        loaded.insert(CGPoint(x: regionx, y: regiony))
    } _: { e in
        err(e)
    }
    
}
