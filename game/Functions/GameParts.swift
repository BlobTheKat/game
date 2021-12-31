//
//  GameParts.swift
//  game
//
//  Created by Matthew on 15/12/2021.
//

import Foundation
import SpriteKit

//Name of colonize items, ordered
let coloNames = ["drill", "canon", "lab", "satellite", "electro", "camp"]

//a colonize item consists of a type, level and capacity
typealias ColonizeItem = (type: ColonizeItemType, lvl: UInt8, capacity: UInt8, upgradeEnd: UInt32)

//All the different types and their respective IDs
enum ColonizeItemType: UInt8{
    case drill = 0
    case shooter = 1
    case dish = 2
    case satellite = 3
    case electro = 4
    case camp = 5
}

enum OwnedState: UInt8{
    case unownable = 0 //not owned //not ownable to you
    case unowned = 64  //not owned //ownable to you
    case owned = 128   //owned     //not ownable to you
    case yours = 192   //owned     //ownable to you
}



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


enum WarningTypes{
    case warning
    case achieved
}
