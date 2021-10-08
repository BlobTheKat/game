//
//  Convenience.swift
//  game
//
//  Created by BlobKat on 22/07/2021.
//

import Foundation
import SpriteKit

func second() -> String{
    let s = Int64(NSDate().timeIntervalSince1970) % 60
    return s < 10 ? "0\(s)" : "\(s)"
}

var logs = ["[\(second())] Game started!"]

func print(_ items: Any...){
    let str = items.map({a in return "\(a)"}).joined(separator: " ")
    Swift.print(str)
    logs.insert("[\(second())] \(str)", at: 0)
    if logs.count > 10{logs.removeLast()}
}


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
    @available(iOS 13.4, *)
    @objc
    func keyDown(_: UIKeyboardHIDUsage){
    }
    @available(iOS 13.4, *)
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
    mutating func write<LenType: FixedWidthInteger>(_ a: String, encoding: String.Encoding = .utf8, lentype: LenType.Type){
        guard a.count <= lentype.max else{fatalError("Buffer overload when writing string (smh how much ram do you have??)")}
        write(lentype.init(a.count))
        self.append(a.data(using: encoding)!)
    }
    @inline(__always) mutating func write(_ a: String, encoding: String.Encoding = .utf8){
        write(a, encoding: encoding, lentype: UInt32.self)
    }
    mutating func write<SequenceType, LenType: FixedWidthInteger>(_ a: [SequenceType], lentype: LenType.Type){
        guard a.count <= lentype.max else{fatalError("Buffer overload when writing string (smh how much ram do you have??)")}
        write(LenType(a.count))
        for item in a{
            self.write(item)
        }
    }
    @inline(__always) mutating func write<S>(_ a: [S]){
        write(a, lentype: UInt32.self)
    }
    mutating func read<LenType: FixedWidthInteger>(encoding: String.Encoding = .utf8, lentype: LenType.Type) -> String?{
        if self.count < MemoryLayout<LenType>.size{return nil}
        guard let count = read() as LenType? else {return nil}
        if self.count < count{return nil}
        let data = self.prefix(Int(count))
        self.removeFirst(Int(count))
        return String(data: data, encoding: encoding)
    }
    @inline(__always) mutating func read(encoding: String.Encoding = .utf8) -> String?{
        return read(encoding: encoding, lentype: UInt32.self)
    }
    mutating func read<SequenceType, LenType: FixedWidthInteger>(lentype: LenType.Type) -> [SequenceType]?{
        if self.count < MemoryLayout<LenType>.size{return nil}
        guard let count = read() as LenType? else {return nil}
        if self.count < Int(count) * MemoryLayout<SequenceType>.size{return nil}
        var arr: [SequenceType] = []
        for _ in 1...count{
            arr.append(self.readunsafe() as SequenceType)
        }
        return arr
    }
    mutating func read<SequenceType>(count: Int) -> [SequenceType]{
        var arr: [SequenceType] = []
        if count <= 0{return arr}
        for _ in 1...count{
            arr.append(self.readunsafe() as SequenceType)
        }
        return arr
    }
    mutating func write<SequenceType>(_ arr: [SequenceType], count: Int){
        if count > 0{
            for i in 1...count{
                write(arr[i])
            }
        }
    }
    @inline(__always) mutating func read<S>() -> [S]?{
        return read(lentype: UInt32.self)
    }
    mutating func write<T>(_ a: T){
        var f = a
        self.append(Data.init(bytes: &f, count: MemoryLayout.size(ofValue: a)))
    }
    mutating func readunsafe<T>() -> T{
        let l = MemoryLayout<T>.size
        var d = Data(self.prefix(l))
        let f: T = d.withUnsafeMutableBytes { a in
            return a.load(as: T.self)
        }
        self.removeFirst(l)
        return f
    }
    mutating func read<T>() -> T?{
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

prefix operator %
extension CGFloat{
    static prefix func %(_ num: CGFloat) -> String{
        if num.isNaN{
            return "NaN     "
        }
        let neg = num < 0 ? "-" : " "
        let num = abs(num)
        if num >= 1e100{
            return neg + "infinity"
        }
        if num < 1e-99{
            return neg + "0.000000"
        }
        let pw = floor(log10(num))
        if num > 999999 || num < 0.0001{
            return "\(neg)\(String(format: "%.\(abs(pw)>9 ? "3" : "4")f", num/pow(10,pw)))\(pw<0 ? "R" : "E")\(Int(abs(pw)))"
        }
        return neg + String(format:"%.\(Int(6-Swift.max(pw,0)))f",num)
    }
}
extension Bool{
    static prefix func %(_ a: Bool) -> String{
        return a ? " TRUE" : "FALSE"
    }
}
extension Comparable{
    @inlinable func clamp(_ a: Self, _ b: Self) -> Self{
        return min(max(self, a), b)
    }
}
extension FixedWidthInteger{
    static prefix func %(_ a: Self) -> String{
        let digits = floor(log10(CGFloat(Self.max)))+1
        let i = "\(a)"
        return String(repeating: "0", count: Int(digits) - i.count) + i
    }
}

@inline(__always) func fdiv(_ x: Int, _ y: Int) -> Int{
    return (abs(x) / y) * (x < 0 ? -1 : 1)
}
