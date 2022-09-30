//
//  Parser.swift
//  game
//
//  Created by Matthew on 16/12/2021.
//

import Foundation
import SpriteKit

typealias GameData = [[String: JSON]]
extension GameData{
    static var fetch: String? = nil
    static var err = {(a: String) in}
    func load(_ cb: @escaping (GameData) -> ()){
        let key = "data"+self[0]["___path"]!.string!
        game.fetch(GameData.fetch! + self[0]["___path"]!.string!){ (str: String) in
            UserDefaults.standard.set(str, forKey: key)
            cb(GameData(data: str))
        } _: { err in
            //retry
            game.fetch(GameData.fetch! + self[0]["___path"]!.string!){ (str: String) in
                UserDefaults.standard.set(str, forKey: key)
                cb(GameData(data: str))
            } _: { err in
                //crash
                GameData.err(err)
            }
        }
    }
    static let floatparser = try! NSRegularExpression(pattern: "^(-?(?:\\d+\\.\\d*|\\.?\\d+)(?:e[+-]?\\d+)?)([a-zA-Z%]*)$")
    init?(_ path: String){
        if GameData.fetch != nil{
            self = [["___path": .string(path)]]
            return
        }
        guard let s = UserDefaults.standard.string(forKey: "data"+path) else {
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
                let t = text[i].split(separator: ":", maxSplits: 1)
                guard t.count > 1 else{self[self.count-1][String(t[0])] = .null;i+=1;continue}
                let value = t[1].trimmingCharacters(in: CharacterSet([" ", "\u{0009}"]))
                let match = GameData.floatparser.firstMatch(in: value, range: NSRange(value.startIndex..<value.endIndex, in: value))
                if match != nil, let a = Double(value[Range(match!.range(at: 1), in: value)!]){
                    let suffixValue = SUFFIXES[String(value[Range(match!.range(at: 2), in: value)!])] ?? 1
                    self[self.count-1][String(t[0])] = .number(a * suffixValue)
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
}



//Remove textures from all the planets of a sector, to save on memory
func emptytextures(s: SectorData){
    for p in s.0{
        for c in p.children{
            if c.name != nil{(c as? SKSpriteNode)?.texture = nil}
        }
        p.smallTextures = false
    }
}

func sectorExists(px: Int, py: Int) -> Bool{
    let delegated = CGPoint(x: 0, y: 0)//fdiv(px, REGIONSIZE), y: fdiv(py, REGIONSIZE))
    if let region = regions[delegated]{
        if loadedRegions.contains(delegated){
            return true
        }
        for s in region{
            if s.1.pos.x == CGFloat(px) && s.1.pos.y == CGFloat(py){
                return true
            }
        }
    }
    return false
}

//Get a sector and load its entire region into memory. Call completion with the sector
func sector(x: Int, y: Int, completion: @escaping (SectorData) -> (), err: @escaping (String) -> (), load: @escaping (CGFloat) -> (), _ a: [SectorData] = []){
    let regionx = fdiv(x, REGIONSIZE)
    let regiony = fdiv(y, REGIONSIZE)
    guard regions[CGPoint(x: regionx, y: regiony)] == nil else {
        let x = CGFloat(x)
        let y = CGFloat(y)
        for sector in regions[CGPoint(x: regionx, y: regiony)]!{
            let (_, (pos: pos, size: size), (name: _, ip: _)) = sector
            let w2 = size.width / 2
            let h2 = size.height / 2
            if x > pos.x - w2 && x < pos.x + w2 && y > pos.y - h2 && y < pos.y + h2{
                //reinstate textures
                for p in sector.0{
                    p.downgrade()
                }
                completion(sector)
                return
            }
        }
        if !loadedRegions.contains(CGPoint(x: regionx, y: regiony)){
            let a = regions[CGPoint(x: regionx, y: regiony)]
            regions[CGPoint(x: regionx, y: regiony)] = nil
            sector(x: Int(x), y: Int(y), completion: completion, err: err, load: load, a ?? [])
            return
        }
        err("Spacetime continuum ends here...")
        secx = ssecx
        secy = ssecy
        velo = CGVector()
        zrot = zzrot
        return
    }
    regions[CGPoint(x: regionx, y: regiony)] = a
    fetch(SECTOR_PATH + "/\(regionx)_\(regiony).region") { (d: Data) in
        DispatchQueue.main.async {
            var data = d
            //guard let _ = data.read() else {return}
            var found = false
            let xx = regionx * REGIONSIZE
            let yy = regiony * REGIONSIZE
            while data.count > 0{
                var px = Int(data.readunsafe() as Int16) * 1000 + xx
                var py = Int(data.readunsafe() as Int16) * 1000 + yy
                let w = Int(data.readunsafe() as UInt16) * 1000
                let h = Int(data.readunsafe() as UInt16) * 1000
                px += w / 2
                py += h / 2
                let exists = sectorExists(px: px, py: py)
                let nl = data.readunsafe() as Int16 //name length
                let ipl = data.readunsafe() as Int16 //IP length
                var len = data.readunsafe() as UInt32 //length of planet array
                let name = String(bytes: data.read(count: Int(nl)) as [UInt8], encoding: .utf8)!
                let ip = String(bytes: data.read(count: Int(ipl)) as [UInt8], encoding: .utf8)!
                var planets = [Planet]()
                var s = (planets, (pos: CGPoint(x: px, y: py), size: CGSize(width: w, height: h)),(name:name,ip:ip))
                let current = x > px - w/2 && x < px + w/2 && y > py - h/2 && y < py + h/2
                found = found || current
                while(len > 0){
                    len -= 1
                    let id = data.readunsafe() as UInt16
                    if id & 1 == 1{
                        let _ = data.read(count: 8 + Int(id & 6) + Int(id & 8) / 2) as [UInt8]
                        continue
                    }
                    let id2 = data.readunsafe() as UInt8
                    let x = Int(data.readunsafe() as Int32)
                    let y = Int(data.readunsafe() as Int32)
                    let p = Planet(radius: CGFloat(id / 256 + UInt16(id2) * 256), mass: CGFloat(data.readunsafe() as Int32))
                    p.position = CGPoint(x: x, y: y)
                    if myplanets.contains("\(x) \(y)"){
                        p.ownedState = .yours
                    }
                    if id & 2 != 0{
                        p.producesParticles = true
                        p.particle = particles[Int(data.readunsafe() as Int16)]
                    }
                    if id & 4 != 0{
                        p.angularVelocity = CGFloat(data.readunsafe() as Float)
                    }
                    p.superhot = id & 8 != 0
                    if p.superhot{
                        p.baseEnergyChunks = floor(p.mass / 1000)
                    }
                    if !exists{planets.append(p)}
                    var img = (data.read(lentype: UInt8.self) ?? "none").split(separator: " ").map({a in return String(a)})
                    if img.count < 1{img.append("none")}
                    
                    if id & 16 != 0{
                        p.emitf = CGFloat(data.readunsafe() as UInt8) / 100
                    }
                    if id & 32 != 0{
                        let resource = (data.read(lentype: UInt8.self) ?? "").split(separator: ":")
                        p.name = resource.count > 0 ? String(resource[0]) : nil
                        p.price = resource.count > 1 ? Double(resource[1])! : 0
                        p.price2 = resource.count > 2 ? Float(resource[2])! : 0
                    }
                    var i = 0
                    for img in img{
                        var img = img.split(separator: ":")
                        if img.count < 2{img.append("1")}
                        let scale = CGFloat((img[1] as NSString).floatValue)
                        let t = String(img[0])
                        let node = SKSpriteNode()
                        p.addChild(node)
                        node.setScale(scale)
                        node.name = t
                        node.zPosition = 2
                        i += 1
                    }
                    if current && !exists{p.downgrade()}
                }
                s.0 = planets
                if px < xx || px > xx + REGIONSIZE || py < yy || py > yy + REGIONSIZE{
                    let delegated = CGPoint(x: 0, y: 0)//fdiv(px, REGIONSIZE), y: fdiv(py, REGIONSIZE))
                    if regions[delegated] != nil{
                        regions[delegated]!.append(s)
                    }else{
                        regions[delegated] = [s]
                    }
                }else{regions[CGPoint(x: regionx, y: regiony)]!.append(s)}
                if current{completion(s)}
            }
            if !found{
                err("Spacetime continuum ends here...")
                secx = ssecx
                secy = ssecy
                velo = CGVector()
                zrot = zzrot
                return
            }
            loadedRegions.insert(CGPoint(x: regionx, y: regiony))
        }
    } _: { e in
        err(e)
    }
    
}
func find(_ x: Int, _ y: Int) -> Planet?{
    guard let r = regions[CGPoint(x: fdiv(x, REGIONSIZE), y: fdiv(y, REGIONSIZE))] else {return nil}
    guard let s = r.first(where: {return abs($0.1.pos.x - CGFloat(x)) < $0.1.size.width / 2 && abs($0.1.pos.y - CGFloat(y)) < $0.1.size.height / 2 }) else {return nil}
    return s.0.first{a in return abs(a.position.x + s.1.pos.x - CGFloat(x)) < 5 && abs(a.position.y + s.1.pos.y - CGFloat(y)) < 5 }
}
