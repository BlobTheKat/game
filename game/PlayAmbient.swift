//
//  PlayAmbient.swift
//  game
//
//  Created by Adam Reiner on 27/10/2021.
//

import Foundation
import SpriteKit

class SKAmbientContainer: SKNode{
    var BLOCKSIZE: CGFloat = 128 //higher = less updates but more memory
    var garbage: [SKNode] = []
    var sprites: [CGPoint: [SKNode]] = [:]
    var generator: () -> SKNode
    var frequency: CGFloat
    var deriviation: CGFloat = 0
    var fq: CGFloat = 0.5
    init(_ generator: @escaping () -> SKNode, frequency: CGFloat, deriviation: CGFloat = 0){
        self.generator = generator
        self.frequency = frequency
        self.deriviation = deriviation
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(){
        self.generator = {return SKNode()}
        self.frequency = 1
        super.init()
    }
    func update(){
        guard let cam = parent?.scene?.camera else {return}
        let scene = parent!.scene!
        let x1 = floor((cam.position.x - scene.size.width * cam.xScale - self.position.x) / BLOCKSIZE)
        let x2 = ceil((cam.position.x + scene.size.width * cam.xScale - self.position.x) / BLOCKSIZE)
        let y1 = floor((cam.position.y - scene.size.height * cam.yScale - self.position.y) / BLOCKSIZE)
        let y2 = ceil((cam.position.y + scene.size.height * cam.yScale - self.position.y) / BLOCKSIZE)
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
                    var nodes = [SKNode]()
                    fq += frequency + random() * deriviation * 2 - deriviation
                    while fq > 1{
                        nodes.append(garbage.first != nil ? garbage.removeFirst() : generator())
                        nodes.last!.position.x = (x + 0.5) * BLOCKSIZE
                        nodes.last!.position.y = (y + 0.5) * BLOCKSIZE
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

class PlayAmbient: PlayNetwork{
    var stars = SKAmbientContainer()
    var stars2 = SKAmbientContainer()
    var stars3 = SKAmbientContainer()
    
    var collectibles = SKAmbientContainer()
    func wasMoved() {
        
        self.collectibles = SKAmbientContainer({
            let n = SKSpriteNode()
            n.texture = SKTexture(imageNamed: "particle")
            n.size = n.texture!.size()
            n.setScale(2)
            return n
        }, frequency: 2, deriviation: 2)
        self.stars = SKAmbientContainer({
            let n = SKSpriteNode()
            n.texture = STARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(4)
            n.texture!.filteringMode = .nearest
            return n
        }, frequency: 1, deriviation: 0)
        self.stars.BLOCKSIZE = 2000
        self.stars2 = SKAmbientContainer({
            let n = SKSpriteNode()
            n.texture = STARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(1.5)
            n.texture!.filteringMode = .nearest
            return n
        }, frequency: 1, deriviation: 0)
        self.stars2.BLOCKSIZE = 750
        self.stars3 = SKAmbientContainer({
            let n = SKSpriteNode()
            n.texture = BSTARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(1)
            n.texture!.filteringMode = .nearest
            return n
        }, frequency: 1, deriviation: 0)
        self.stars3.BLOCKSIZE = 500
        self.addChild(self.stars)
        self.addChild(self.stars2)
        self.addChild(self.stars3)
    }
}
