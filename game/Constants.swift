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

struct servers{
    static let uswest = ""
    static let backup = ""
    static let home = "192.168.1.64"
}
let textures: [SKTexture] = ["", "ship1", "planet1", "asteroid1"].map{a in return SKTexture(imageNamed: a)}
func reverse() -> [SKTexture: UInt32]{
    var r: [SKTexture: UInt32] = [:]
    var i: UInt32? = 0
    for v in textures{
        r[v] = i
        i? += 1
    }
    return r
}
let r = reverse()

extension SKTexture{
    static func from(_ a: UInt32) -> SKTexture{
        return textures[Int(a)]
    }
    func code() -> UInt32{
        return r[self] ?? 0
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
        let text = s.split(separator: "\n")
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
            while text[i] != ""{
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

    var header: [String: JSON]
    var data: [[String: JSON]]
    @inlinable subscript(_ a: Int) -> [String: JSON]{
        return data[a]
    }
}
let map = GameData("map")!
