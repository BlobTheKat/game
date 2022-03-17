//
//  Rays.swift
//  game
//
//  Created by Matthew on 15/12/2021.
//

import Foundation
import SpriteKit
//Used for calculating length of a ray from a specific point and direction (length until it hits something)
func raylength(objs: [Planet], objs2: [Object], rayorigin: CGPoint, raydir: CGVector, this: CGPoint) -> (obj: Int?, len: CGFloat, planet: Int?){
    var len = 3000.0
    var o: Int? = nil
    var p: Int? = nil
    var i = -1
    for obj in objs{
        i += 1
        if obj.position == this{continue}
        let l = collision(planetpos: obj.position, planetr: obj.radius, rayorigin: rayorigin, raydir: raydir)
        if l < len{
            len = l
            p = i
            o = nil
        }
    }
    i = -1
    for obj in objs2{
        i += 1
        if obj.position == this{continue}
        let l = collision(planetpos: obj.position, planetr: obj.radius, rayorigin: rayorigin, raydir: raydir)
        if l < len{
            len = l
            o = i
            p = nil
        }
    }
    return (obj: o, len: len, planet: p)
}
//Check length of a ray against a single object, used inside raylength()
func collision(planetpos: CGPoint, planetr: CGFloat, rayorigin: CGPoint, raydir: CGVector) -> CGFloat{
    let px = planetpos.x - rayorigin.x
    let py = planetpos.y - rayorigin.y
    let a = raydir.dx / raydir.dy
    if a == 0{return raydir.dy * py > 0 && abs(px) < planetr ? abs(raydir.dy) : .infinity}
    if !a.isFinite{return raydir.dx * px > 0 && abs(py) < planetr ? abs(raydir.dx) : .infinity}
    let a2 = a * a + 1
    let x = (px * a + py) / a2
    let x2 = x * x * a2
    let touches = x * raydir.dy >= 0 && x2 - 2 * py * x - 2 * px * x * a + px * px + py * py < planetr * planetr
    return touches ? sqrt(x2) : .infinity
}
