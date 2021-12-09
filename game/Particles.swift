//
//  Particles.swift
//  game
//
//  Created by Matthew on 12/08/2021.
//

import Foundation
import SpriteKit

let P20 = CGFloat.pi / 10

let appear = { (_ pos: CGPoint) -> [Particle] in
    var p = [Particle]()
    for i in 1...20{
        let dir = dir(CGFloat(i) * P20, random(min: 50, max: 100))
        p.append(Particle[State(color: (r: 0, g: 0.2, b: 1), size: CGSize(width: 15, height: 15), zRot: 0, position: CGPoint(x: pos.x + dir.dx, y: pos.y + dir.dy), alpha: 0), State(color: (r: 1, g: 1, b: 1), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: pos.x, y: pos.y), alpha: 1, delay: 1)])
    }
    return p
}
let disappear = { (_ pos: CGPoint) -> [Particle] in
    var p = [Particle]()
    for i in 1...20{
        let dir = dir(CGFloat(i) * P20, random(min: 50, max: 100))
        p.append(Particle[State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: pos.x, y: pos.y), alpha: 1), State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 15, height: 15), zRot: 0, position: CGPoint(x: pos.x + dir.dx, y: pos.y + dir.dy), alpha: 0, delay: 1)])
        
    }
    return p
}

let particles: [(Object) -> Particle] = [
    { (planet) in //0: yellow -> red (out)
        let dir = randDir(planet.radius)
        return Particle[State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: planet.position.x + dir.dx, y: planet.position.y + dir.dy), alpha: 1), State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 20, height: 20), zRot: 4, position: CGPoint(x: planet.position.x + dir.dx * 1.3, y: planet.position.y + dir.dy * 1.3), alpha: 0, delay: 2)]
    },
    { (planet) in //1: cyan -> white (in)
            let dir = randDir(planet.radius)
       
        return Particle[State(color: (r: 0, g: 1, b: 1), size: CGSize(width: 20, height: 20), zRot: 4, position: CGPoint(x: planet.position.x + dir.dx * 1.3, y: planet.position.y + dir.dy * 1.3), alpha: 0), State(color: (r: 1, g: 1, b: 1), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: planet.position.x + dir.dx, y: planet.position.y + dir.dy), alpha: 1, delay: 2)]
       
        
        },
    { (planet) in //2: white -> black (in)
            let dir = randDir(planet.radius)
       
        return Particle[State(color: (r: 1, g: 1, b: 1), size: CGSize(width: 20, height: 20), zRot: 4, position: CGPoint(x: planet.position.x + dir.dx * 3, y: planet.position.y + dir.dy * 3), alpha: 0), State(color: (r: 0, g: 0, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: planet.position.x + dir.dx, y: planet.position.y + dir.dy), alpha: 1, delay: 3)]
       
        
        },
    { (planet) in //3: pink -> red (out)
        let dir = randDir(planet.radius)
        return Particle[State(color: (r: 0.128, g: 0, b: 0.128), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: planet.position.x + dir.dx, y: planet.position.y + dir.dy), alpha: 1), State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 20, height: 20), zRot: 4, position: CGPoint(x: planet.position.x + dir.dx * 1.3, y: planet.position.y + dir.dy * 1.3), alpha: 0, delay: 1)]
    },
    { (planet) in //4: yellow -> red (going up)
        let dir = randDir(planet.radius)
        return Particle[State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: planet.position.x + dir.dx, y: planet.position.y + dir.dy * 0.7), alpha: 1), State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 20, height: 20), zRot: 4, position: CGPoint(x: planet.position.x + dir.dx, y: planet.position.y + dir.dy * 3), alpha: 0, delay: 1)]
    }
]



let SHOOTPOINTS: [[CGPoint]] = [
    [CGPoint(x: -10, y: 40), CGPoint(x: 10, y: 40)]
]
let SHOOTVECTORS: [[CGFloat]] = [
    [0, 0]
]
let SHOOTFREQUENCIES: [CGFloat] = [
    0.05
]
let a: [[[[[[[[[[[[[[[[CGFloat]]]]]]]]]]]]]]]] = [] //just for fun
let SHOOTERDIRS: [[CGFloat]] = [ //for planet shooters (maps to shooter level)
    [-0.5,0.5],
    [-0.5,0.5],
    [-0.6,0,0.6],
    [-0.6,0,0.6]
]
