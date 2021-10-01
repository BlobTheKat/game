//
//  Constants.swift
//  game
//
//  Created by Matthew on 05/08/2021.
//

import Foundation
import SpriteKit

let G: CGFloat = 0.0001
let fsmall: CGFloat = 32
let fmed: CGFloat = 48
let fbig: CGFloat = 72
let gameFPS = 60.0

var sect: UInt32 = 0

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
var map = GameData("/map")!
var ships = GameData("/ships")!
var asteroids = GameData("/asteroids")!
let VERSION = 1

func sector(_ id: Int, completion: @escaping ([Planet], [Object], CGSize) -> (), err: @escaping (String) -> ()){
    guard case .string(let path) = map[id]["path"] else {return}
    GameData.from(location: path) { data in
        guard let data = data else{return err("Could not load sector")}
        var planetarr: [Planet] = []
        let asteroidarr: [Object] = []
        
//read from server and initiate variable for width and height of sectors
        guard case .number(let sectorWidth) = map[id]["w"] else {return}
        guard case .number(let sectorHeight) = map[id]["h"] else {return}
        
        
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
            if id != nil{
                /*
                let i = Object(radius: CGFloat(radius), mass: CGFloat(mass), texture: t, asteroid: true)
                i.angularVelocity = CGFloat(spin)
                i.position.x = CGFloat(x)
                i.position.y = CGFloat(y)
                
                if case .number(let particle) = dat["particle"]{
                    i.producesParticles = true
                    i.particle = particles[Int(particle)]
                }
                if case .number(let frequency) = dat["fequency"]{
                  i.particleFrequency = frequency
                }
                i.id = Int(id)
                asteroidarr.append(i)
                */
            }else{
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
        completion(planetarr, asteroidarr, CGSize(width: sectorWidth, height: sectorHeight))
    }
    
}
