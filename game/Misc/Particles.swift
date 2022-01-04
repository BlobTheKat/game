//
//  Particles.swift
//  game
//
//  Created by Matthew on 12/08/2021.
//

import Foundation
import SpriteKit

func boom(_ pos: CGPoint, _ end: Color) -> [Particle]{
    var particleArr = [Particle]()
    for i in 1...20{
        let dir = dir(CGFloat(i) * PI20, random(min: 60, max: 100))
        let a = Particle[State(color: (r: 1, g: 1, b: 1), size: CGSize(width: 6, height: 6), zRot: 0, position: CGPoint(x: pos.x, y: pos.y), alpha: 1), State(color: end, size: CGSize(width: 12, height: 12), zRot: 0, position: CGPoint(x: pos.x + dir.dx, y: pos.y + dir.dy), alpha: 0, delay: 1)]
        particleArr.append(a)
    }
    return particleArr
}
func boom2(_ pos: CGPoint, _ radius: CGFloat = 100) -> [Particle]{
    var particleArr = [Particle]()
    for i in 1...Int(ceil(radius / 10) * 20){
        let dir = dir(CGFloat(i) * PI20, random(min: radius * 0.8, max: radius * 1.5))
        particleArr.append(Particle[State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 15, height: 15), zRot: 0, position: CGPoint(x: pos.x, y: pos.y), alpha: 1), State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 30, height: 30), zRot: 0, position: CGPoint(x: pos.x + dir.dx, y: pos.y + dir.dy), alpha: 0, delay: 1)])
        
    }
    return particleArr
}

let appear = { (_ pos: CGPoint) -> [Particle] in
    var particleArr = [Particle]()
    for i in 1...20{
        let dir = dir(CGFloat(i) * PI20, random(min: 50, max: 100))
        particleArr.append(Particle[State(color: (r: 0, g: 0.2, b: 1), size: CGSize(width: 15, height: 15), zRot: 0, position: CGPoint(x: pos.x + dir.dx, y: pos.y + dir.dy), alpha: 0), State(color: (r: 1, g: 1, b: 1), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: pos.x, y: pos.y), alpha: 1, delay: 1)])
    }
    return particleArr
}
let disappear = { (_ pos: CGPoint) -> [Particle] in
    var particleArr = [Particle]()
    for i in 1...20{
        let dir = dir(CGFloat(i) * PI20, random(min: 50, max: 100))
        particleArr.append(Particle[State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: pos.x, y: pos.y), alpha: 1), State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 15, height: 15), zRot: 0, position: CGPoint(x: pos.x + dir.dx, y: pos.y + dir.dy), alpha: 0, delay: 1)])
        
    }
    return particleArr
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


let SHOOTPOINTS: [[CGPoint]] = ships.dropFirst().map { ship in
    if case .string(let points) = ship["shootpoints"]{
        return points.split(separator: ",").map{ a in
            let point = String(a).trimmingCharacters(in: CharacterSet([" "])).split(separator: " ")
            return CGPoint(x: CGFloat(Double(point[0])!), y: CGFloat(Double(point[1])!))
        }
    }else{
        return []
    }
}
let SHOOTVECTORS: [[CGFloat]] = ships.dropFirst().map { ship in
    if case .string(let points) = ship["shootvecs"]{
        return points.split(separator: ",").map{ a in CGFloat(Double(String(a).trimmingCharacters(in: CharacterSet([" "])))!) }
    }else{
        return []
    }
}
let SHOOTDAMAGES: [[CGFloat]] = ships.dropFirst().map { ship in
    if case .string(let points) = ship["shootdmgs"]{
        return points.split(separator: ",").map{ a in CGFloat(Double(String(a).trimmingCharacters(in: CharacterSet([" "])))!) }
    }else{
        return []
    }
}
