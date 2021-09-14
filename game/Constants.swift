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
struct GameData{
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
        header = [:]
        while i < text.count && text[i] != ""{
            let t = text[i].split(separator: ":")
            guard t.count > 1 else{header[String(t[0])] = .null;i+=1;continue}
            let value = t[1].trimmingCharacters(in: CharacterSet([" ", "\u{0009}"]))
            if let a = Double(value){
                header[String(t[0])] = .number(a)
            }else if value.lowercased() == "yes" || value.lowercased() == "true"{
                header[String(t[0])] = .bool(true)
            }else if value.lowercased() == "no" || value.lowercased() == "false"{
                header[String(t[0])] = .bool(false)
            }else{
                header[String(t[0])] = .string(String(value))
            }
            i += 1
        }
        i += 1
        data = []
        while i < text.count{
            data.append([:])
            while i < text.count && text[i] != ""{
                let t = text[i].split(separator: ":")
                guard t.count > 1 else{data[data.count-1][String(t[0])] = .null;i+=1;continue}
                let value = t[1].trimmingCharacters(in: CharacterSet([" ", "\u{0009}"]))
                if let a = Double(value){
                    data[data.count-1][String(t[0])] = .number(a)
                }else if value.lowercased() == "yes" || value.lowercased() == "true"{
                    data[data.count-1][String(t[0])] = .bool(true)
                }else if value.lowercased() == "no" || value.lowercased() == "false"{
                    data[data.count-1][String(t[0])] = .bool(false)
                }else{
                    data[data.count-1][String(t[0])] = .string(String(value))
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
    var header: [String: JSON]
    var data: [[String: JSON]]
    @inlinable subscript(_ a: Int) -> [String: JSON]{
        return data[a]
    }
}
var map = GameData("/map")!
var ships = GameData("/ships")!
var planets = GameData("/planets")!
var asteroids = GameData("/asteroids")!

func sector(_ id: Int, completion: @escaping ([Planet], [Object]) -> ()){
    guard case .string(let path) = map.data[id]["path"] else {return}
    GameData.from(location: path) { data in
        guard let data = data?.data else{return}
        var planetarr: [Planet] = []
        var asteroidarr: [Object] = []
        for object in data{
            var a = false
            if case .bool(let f) = object["asteroid"] {a = f}
            guard case .number(let id) = object["id"] else {continue}
            let dat = (a ? asteroids : planets).data[Int(id)]
            guard case .number(let radius) = dat["radius"] else {continue}
            guard case .number(let mass) = dat["mass"] else {continue}
            guard case .number(let x) = object["x"] else {continue}
            guard case .number(let y) = object["y"] else {continue}
            guard case .number(let spin) = dat["spin"] else {continue}
            guard case .string(let texture) = dat["texture"] else {continue}
            let t = SKTexture(imageNamed: texture)
            if a{
                continue
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
                i.id = Int(id)
                planetarr.append(i)
            }
        }
        completion(planetarr, asteroidarr)
    }
    
}
