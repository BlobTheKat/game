//
//  PlayAmbient.swift
//  game
//
//  Created by Adam Reiner on 27/10/2021.
//

import Foundation
import SpriteKit

class SKAmbientContainer: SKNode{
    let blocksize: CGFloat //higher = less updates but more memory
    var garbage: [SKSpriteNode] = []
    var sprites: [CGPoint: [SKSpriteNode]] = [:]
    var generator: (SKSpriteNode) -> ()
    var frequency: CGFloat
    var deriviation: CGFloat = 0
    var fq: CGFloat = 0.5
    init(_ generator: @escaping (SKSpriteNode) -> (), frequency: CGFloat, deriviation: CGFloat = 0, blocksize: CGFloat = 128){
        self.blocksize = blocksize
        self.generator = generator
        self.frequency = frequency
        self.deriviation = deriviation
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(){
        self.generator = {_ in}
        self.frequency = 1
        self.blocksize = 128
        super.init()
    }
    func update(){
        guard let cam = parent?.scene?.camera else {return}
        let scene = parent!.scene!
        let x1 = floor((cam.position.x - scene.size.width * cam.xScale - self.position.x) / blocksize)
        let x2 = ceil((cam.position.x + scene.size.width * cam.xScale - self.position.x) / blocksize)
        let y1 = floor((cam.position.y - scene.size.height * cam.yScale - self.position.y) / blocksize)
        let y2 = ceil((cam.position.y + scene.size.height * cam.yScale - self.position.y) / blocksize)
        var x = x1
        var y = y1
        var keys: Set<CGPoint> = Set(sprites.keys)
        while(x < x2){
            while(y < y2){
                let p = CGPoint(x: x, y: y)
                if sprites[p] != nil{
                    keys.remove(p)
                }else{
                    //create
                    var nodes = [SKSpriteNode]()
                    fq += frequency + random() * deriviation * 2 - deriviation
                    while fq > 1{
                        nodes.append(garbage.first != nil ? garbage.removeFirst() : SKSpriteNode())
                        nodes.last!.position = .zero
                        nodes.last!.setScale(1)
                        generator(nodes.last!)
                        nodes.last!.position.x = (x + 0.5) * blocksize
                        nodes.last!.position.y = (y + 0.5) * blocksize
                        self.addChild(nodes.last!)
                        nodes.last!.zPosition = -10000
                        fq -= 1
                    }
                    sprites[p] = nodes
                }
                y += 1
            }
            y = y1
            x += 1
        }
        for key in keys{
            if CGFloat(garbage.count) > CGFloat(sprites.keys.count) * frequency{
                garbage.removeLast(garbage.count - sprites.keys.count * Int(frequency))
                break
            }
            garbage.append(contentsOf: sprites[key]!)
            for i in sprites[key]!{
                i.removeFromParent()
            }
            sprites[key] = nil
        }
    }
}

let BSTARS = [SKTexture(imageNamed: "bstars-1"),SKTexture(imageNamed: "bstars-2")]
let STARS = [SKTexture(imageNamed: "stars1"), SKTexture(imageNamed: "stars2")]
let BGASSETS = ["asteroid1","asteroid2","asteroid3","asteroid4","rock1", "rock2", "rock3", "planetA", "planetB"].map({a in return SKTexture(imageNamed: a)})


class PlayAmbient: PlayNetwork{
    var stars = SKAmbientContainer()
    var stars2 = SKAmbientContainer()
    var stars3 = SKAmbientContainer()
    var stars4 = SKAmbientContainer()
    func wasMoved() {
        self.stars = SKAmbientContainer({ n in
            n.texture = STARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(2.5)
            n.texture!.filteringMode = .nearest
        }, frequency: 1, deriviation: 0, blocksize: 1250)
        self.stars2 = SKAmbientContainer({ n in
            n.texture = STARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(1.5)
            n.texture!.filteringMode = .nearest
        }, frequency: 1, deriviation: 0, blocksize: 750)
        self.stars3 = SKAmbientContainer({ n in
            n.texture = BSTARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(1)
            //n.texture!.filteringMode = .nearest
        }, frequency: 1, deriviation: 0, blocksize: 500)
        self.stars4 = SKAmbientContainer({ n in
            n.texture = BGASSETS.randomElement()
            n.size = n.texture!.size()
            n.setScale(0.2)
            n.alpha = 0.2
            n.position.x = random(min: 0, max: 1999)
            n.position.y = random(min: 0, max: 1999)
        }, frequency: 0.5, deriviation: 0.2, blocksize: 2000)
        self.addChild(self.stars)
        self.addChild(self.stars2)
        self.addChild(self.stars3)
        self.addChild(self.stars4)
    }
}
