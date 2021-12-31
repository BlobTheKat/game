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
    static let floatparser = try! NSRegularExpression(pattern: "^(-?(?:\\d+\\.\\d*|\\.?\\d+)(?:e[+-]?\\d+)?)([a-zA-Z%]*)$")
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
                let match = GameData.floatparser.firstMatch(in: value, range: NSRange(value.startIndex..<value.endIndex, in: value))
                if match != nil, let a = Double(value[Range(match!.range(at: 1), in: value)!]){
                    let prefixValue = PREFIXES[String(value[Range(match!.range(at: 2), in: value)!])] ?? 1
                    self[self.count-1][String(t[0])] = .number(a * prefixValue)
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



//Remove textures from all the planets of a sector, to save on memory
func emptytextures(s: SectorData){
    for p in s.0{
        p.texture = nil
        for c in p.children{
            if c.name != nil{(c as? SKSpriteNode)?.texture = nil}
        }
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
                    p.texture = SKTexture(imageNamed: p.name!)
                    p.size = p.texture!.size()
                    for c in p.children{
                        if let c = c as? SKSpriteNode, let n = c.name{
                            c.texture = SKTexture(imageNamed: n)
                            c.size = c.texture!.size()
                        }
                    }
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
        return
    }
    regions[CGPoint(x: regionx, y: regiony)] = a
    fetch("https://raw.githubusercontent.com/BlobTheKat/data/master/\(regionx)_\(regiony).region") { (d: Data) in
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
                    
                    if id & 16 != 0{
                        p.emitf = CGFloat(data.readunsafe() as UInt8) / 100
                    }
                    if id & 32 != 0{
                        let _ = data.read(lentype: UInt8.self) ?? ""
                    }
                    var i = 0
                    for img in img{
                        var img = img.split(separator: ":")
                        if img.count < 2{img.append("1")}
                        let scale = CGFloat((img[1] as NSString).floatValue)
                        let t = String(img[0])
                        if i == 0{
                            if current && !exists{
                                p.texture = SKTexture(imageNamed: t)
                                p.size = p.texture!.size()
                            }
                            p.setScale(scale)
                            p.name = t
                        }else{
                            let node = SKSpriteNode()
                            p.addChild(node)
                            if current && !exists{
                                node.texture = SKTexture(imageNamed: t)
                                node.size = node.texture!.size()
                            }
                            node.setScale(scale)
                            node.name = t
                        }
                        i += 1
                    }
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
            if !found{err("Spacetime continuum ends here...");return}
            loadedRegions.insert(CGPoint(x: regionx, y: regiony))
        }
    } _: { e in
        err(e)
    }
    
}
