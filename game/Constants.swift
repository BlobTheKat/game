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
