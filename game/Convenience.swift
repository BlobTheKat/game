//
//  Convenience.swift
//  game
//
//  Created by BlobKat on 22/07/2021.
//

import Foundation
import SpriteKit

extension SKScene{
    static var font = "Arial"
    static var transition = SKTransition.crossFade(withDuration: 0)
    static var _k = 0
    static func renderTo(_ view: SKView){
        let scene = self.init(size: view.frame.size)
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .black
        view.presentScene(scene, transition: SKScene.transition)
    }
    func label(node: SKLabelNode, _ txt: String, pos: CGPoint, size: CGFloat = 32, color: UIColor = UIColor.white, font: String = SKScene.font, zPos: CGFloat = 10, isStatic: Bool = false){
        node.fontName = font
        node.text = txt
        node.fontSize = size
        node.fontColor = color
        node.position = pos
        node.zPosition = zPos
        if isStatic{
            camera?.addChild(node)
        }else{
            
            self.addChild(node)
        }
        
    }
    func label(_ txt: String, pos: CGPoint, size: CGFloat = 32, color: UIColor = UIColor.white, font: String = SKScene.font, zPos: CGFloat = 10, isStatic: Bool = false) -> SKLabelNode{
        let node = SKLabelNode()
        node.fontName = font
        node.text = txt
        node.fontSize = size
        node.fontColor = color
        node.position = pos
        node.zPosition = zPos
        if isStatic{
            camera?.addChild(node)
        }else{
            self.addChild(node)
        }
        return node
    }
    func pos(mx: CGFloat = 0.5, my: CGFloat = 0.5, x: CGFloat = 0, y: CGFloat = 0) -> CGPoint{
        return CGPoint(x: self.size.width * mx + x, y: self.size.height * my + y)
    }
    @objc
    func nodeDown(_: SKNode, at _: CGPoint){
    }
    @objc
    func nodeUp(_: SKNode, at _: CGPoint){
    }
    @objc
    func nodeMoved(_: SKNode, at _: CGPoint){
    }
    @objc
    func keyDown(_: UIKeyboardHIDUsage){
    }
    @objc
    func keyUp(_: UIKeyboardHIDUsage){
    }
    @objc
    func touch(at _: CGPoint){
    }
    @objc
    func swipe(from _: CGPoint, to _: CGPoint){
    }
    @objc
    func release(at _: CGPoint){
    }
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for t in touches {
            for node in self.nodes(at: t.location(in: self)){
                self.nodeDown(node, at: t.location(in: node.parent ?? self))
            }
            touch(at: t.location(in: camera ?? self))
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            var oldNodes = Set(self.nodes(at: t.previousLocation(in: self)))
            for node in self.nodes(at: t.location(in: self)){
                if oldNodes.remove(node) == nil{
                    self.nodeDown(node, at: t.location(in: node.parent ?? self))
                }else{
                    self.nodeMoved(node, at: t.location(in: node.parent ?? self))
                }
            }
            for node in oldNodes{
                self.nodeUp(node, at: t.location(in: node.parent ?? self))
            }
            swipe(from: t.previousLocation(in: camera ?? self), to: t.location(in: camera ?? self))
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            for node in self.nodes(at: t.location(in: self)){
                self.nodeUp(node, at: t.location(in: node.parent ?? self))
            }
            release(at: t.location(in: camera ?? self))
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            for node in self.nodes(at: t.location(in: self)){
                self.nodeUp(node, at: t.location(in: node.parent ?? self))
            }
            release(at: t.location(in: camera ?? self))
        }
    }
}
extension SKNode{
    func interval(_ every: Double, _ a: @escaping () -> ()) -> (() -> ()){
        var stopped = false
        let action = SKAction.repeatForever(SKAction.sequence([SKAction.run{if !stopped{a()}},SKAction.wait(forDuration: every)]))
        let k = SKScene._k
        SKScene._k += 1
        self.run(action, withKey: "__\(k)")
        return {
            stopped = true
            self.removeAction(forKey: "__\(k)")
        }
    }
    func timeout(_ after: Double, _ a: @escaping () -> ()) -> (() -> ()){
        var stopped = false
        let action = SKAction.sequence([SKAction.wait(forDuration: after),SKAction.run{if !stopped{a()}}])
        let k = SKScene._k
        SKScene._k += 1
        self.run(action, withKey: "__\(k)")
        return {() -> () in
            stopped = true
            self.removeAction(forKey: "__\(k)")
        }
    }
}

extension SKAction{
    func ease(_ a: SKActionTimingMode) -> SKAction{
        self.timingMode = a
        return self
    }
    func ease(_ a: @escaping SKActionTimingFunction) -> SKAction{
        self.timingFunction = a
        return self
    }
}

extension Data{
    mutating func write(_ a: String, encoding: String.Encoding = .utf8){
        guard a.count < 4294967296 else{fatalError("Buffer overload when writing string (smh how much ram do you have??)")}
        write(UInt32(a.count))
        self.append(a.data(using: encoding)!)
    }
    mutating func read(encoding: String.Encoding = .utf8) -> String?{
        if self.count < 4{return nil}
        let count = Int(read() as UInt32)
        if self.count < count{return nil}
        let data = self.prefix(count)
        self.removeFirst(count)
        return String(data: data, encoding: encoding)
    }
    mutating func write<T>(_ a: T){
        var f = a
        self.append(Data.init(bytes: &f, count: MemoryLayout.size(ofValue: a)))
    }
    mutating func read<T>() -> T{
        let l = MemoryLayout<T>.size
        var d = Data(self.prefix(l))
        let f: T = d.withUnsafeMutableBytes { a in
            return a.load(as: T.self)
        }
        self.removeFirst(l)
        return f
    }
    mutating func readsafe<T>() -> T?{
        let l = MemoryLayout<T>.size
        if self.count < l{return nil}
        var d = Data(self.prefix(l))
        let f: T = d.withUnsafeMutableBytes { a in
            return a.load(as: T.self)
        }
        self.removeFirst(l)
        return f
    }
}

extension StringProtocol{
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
}

extension CGPoint{
    func add(x: CGFloat, y: CGFloat = 0) -> CGPoint{
        return CGPoint(x: self.x + x, y: self.y + y)
    }
    func add(y: CGFloat) -> CGPoint{
        return CGPoint(x: self.x, y: self.y + y)
    }
}
