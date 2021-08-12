//
//  Particles.swift
//  game
//
//  Created by Matthew on 12/08/2021.
//

import Foundation
import SpriteKit

let particles: [(Object) -> Particle] = [
    { (planet) in
        let dir = randDir(planet.radius)
        return Particle[State(color: (r: 1, g: 1, b: 0), size: CGSize(width: 10, height: 10), zRot: 0, position: CGPoint(x: planet.position.x + dir.dx, y: planet.position.y + dir.dy), alpha: 1), State(color: (r: 1, g: 0, b: 0), size: CGSize(width: 20, height: 20), zRot: 4, position: CGPoint(x: planet.position.x + dir.dx * 1.3, y: planet.position.y + dir.dy * 1.3), alpha: 0, delay: 2)]
    }
]
