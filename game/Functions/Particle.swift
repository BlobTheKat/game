//
//  Particle.swift
//  game
//
//  Created by Matthew on 15/12/2021.
//

import Foundation
import SpriteKit

//Particle, essentially a queue of states that get interpolated and animated
class Particle: SKSpriteNode{
    var states: [State]
    var delta = State.zero
    @inline(__always) static subscript(_ a: State...) -> Particle{
        return Particle(states: a) ?? Particle()
    }
    init?(states: [State]){
        self.states = states
        super.init(texture: nil, color: UIColor.clear, size: CGSize.zero)
        if nextState(){return nil}
    }
    init(){
        self.states = []
        super.init(texture: nil, color: UIColor.clear, size: CGSize.zero)
    }
    func nextState() -> Bool{
        if states.count < 1{
            return true
        }
        let state = states.removeFirst()
        delta = (state - State.of(node: self)) / CGFloat(state.delay * gameFPS)
        delta.delay = state.delay
        if delta.delay < 0.5 / gameFPS{
            state.apply(to: self)
            return nextState()
        }
        return false
    }
    func update() -> Bool{
        delta.add(to: self)
        delta.delay -= 1 / gameFPS
        if delta.delay < 0.5 / gameFPS{
            return nextState()
        }
        return false
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//A specific state of a particle. Includes position, rotation, color, size, etc...
struct State{
    static let zero = State(color: (r: 0, g: 0, b: 0), size: CGSize.zero, zRot: 0, position: CGPoint.zero, alpha: 0)
    var color: (r: CGFloat, g: CGFloat, b: CGFloat)
    var size: CGSize
    var zRot: CGFloat
    var position: CGPoint
    var alpha: CGFloat
    var delay: TimeInterval = 0 //delay used for keyframing. not useful to describe a state on its own
    func delta(to state: State) -> State{
        return State(color: (r: state.color.r - self.color.r, g: state.color.g - self.color.g, b: state.color.b - self.color.b), size: CGSize(width: state.size.width - self.size.width, height: state.size.height - self.size.height), zRot: state.zRot - self.zRot, position: CGPoint(x: state.position.x - self.position.x, y: state.position.y - self.position.y), alpha: state.alpha - self.alpha)
    }
    static func -(_ state: State, _ this: State) -> State{
        return State(color: (r: state.color.r - this.color.r, g: state.color.g - this.color.g, b: state.color.b - this.color.b), size: CGSize(width: state.size.width - this.size.width, height: state.size.height - this.size.height), zRot: state.zRot - this.zRot, position: CGPoint(x: state.position.x - this.position.x, y: state.position.y - this.position.y), alpha: state.alpha - this.alpha)
    }
    static func /(_ this: State, _ d: CGFloat) -> State{
        return State(color: (r: this.color.r / d, g: this.color.g / d, b: this.color.b / d), size: CGSize(width: this.size.width / d, height: this.size.height / d), zRot: this.zRot / d, position: CGPoint(x: this.position.x / d, y: this.position.y / d), alpha: this.alpha / d)
    }
    static func +(_ a: State, _ b: State) -> State{
        return State(color: (r: a.color.r + b.color.r, g: a.color.g + b.color.g, b: a.color.b + b.color.b), size: CGSize(width: a.size.width + b.size.width, height: a.size.height + b.size.height), zRot: a.zRot + b.zRot, position: CGPoint(x: a.position.x + b.position.x, y: a.position.y + b.position.y), alpha: a.alpha + b.alpha)
    }
    static func +=(_ this: inout State, _ state: State){
        this.color.r += state.color.r
        this.color.g += state.color.g
        this.color.b += state.color.b
        this.size.width += state.size.width
        this.size.height += state.size.height
        this.zRot += state.zRot
        this.position.x += state.position.x
        this.position.y += state.position.y
        this.alpha += state.alpha
    }
    var uicolor: UIColor{
        return UIColor(red: self.color.r, green: self.color.g, blue: self.color.b, alpha: 1)
    }
    var debugDescription: String{
        return "(\(String(format:"%02X", color.r) + String(format:"%02X", color.g) + String(format:"%02X", color.b) + ", " + String(format:"%02X", Int(alpha * 255)))) [\(size.width)x\(size.height)] (x: \(position.x), y: \(position.y), z: \(zRot))"
    }
    func apply(to node: SKSpriteNode){
        node.alpha = alpha
        node.color = uicolor
        node.size = size
        node.zRotation = zRot
        node.position = position
    }
    func add(to node: SKSpriteNode){
        
        node.alpha += alpha
        var red = CGFloat()
        var green = CGFloat()
        var blue = CGFloat()
        node.color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        node.color = UIColor(red: red + color.r, green: green + color.g, blue: blue + color.b, alpha: 1)
        node.size.width += size.width
        node.size.height += size.height
        node.zRotation += zRot
        node.position.x += position.x
        node.position.y += position.y
        
    }
    static func of(node: SKSpriteNode) -> State{
        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        node.color.getRed(&r, green: &g, blue: &b, alpha: nil)
        return State(color: (r: r, g: g, b: b), size: node.size, zRot: node.zRotation, position: node.position, alpha: node.alpha)
    }
}
