//
//  Protocols.swift
//  game
//
//  Created by Matthew on 15/12/2021.
//

import Foundation
import SpriteKit

//make CGPoint hashable
extension CGPoint: Hashable{
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
}

//Formattables
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
extension CGFloat{
    static prefix func %(_ num: CGFloat) -> String{
        if num.isNaN{
            return " NaN     "
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
extension Float{
    static prefix func %(_ num: Float) -> String{
        if num.isNaN{
            return " NaN   "
        }
        let neg = num < 0 ? "-" : " "
        let num = abs(num)
        if num >= 1e10{
            return neg + "infnty"
        }
        if num < 1e-9{
            return neg + "0.0000"
        }
        let pw = floor(log10(num))
        if num > 9999 || num < 0.01{
            return "\(neg)\(String(format: "%.2f", num/pow(10,pw)))\(pw<0 ? "R" : "E")\(Int(abs(pw)))"
        }
        return neg + String(format:"%.\(Int(4-Swift.max(pw,0)))f",num)
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
    static func +(a: CGPoint, b: CGPoint) -> CGPoint{
        return CGPoint(x: a.x + b.x, y: a.y + b.y)
    }
    static func +=(a: inout CGPoint, b: CGPoint){
        a.x += b.x
        a.y += b.y
    }
    static func -(a: CGPoint, b: CGPoint) -> CGPoint{
        return CGPoint(x: a.x - b.x, y: a.y - b.y)
    }
    static func -=(a: inout CGPoint, b: CGPoint){
        a.x -= b.x
        a.y -= b.y
    }
    static func *(a: CGPoint, b: CGFloat) -> CGPoint{
        return CGPoint(x: a.x * b, y: a.y * b)
    }
    static func *=(a: inout CGPoint, b: CGFloat){
        a.x *= b
        a.y *= b
    }
    static func /(a: CGPoint, b: CGFloat) -> CGPoint{
        return CGPoint(x: a.x / b, y: a.y / b)
    }
    static func /=(a: inout CGPoint, b: CGFloat){
        a.x /= b
        a.y /= b
    }
}

extension CGVector{
    func add(dx: CGFloat, dy: CGFloat = 0) -> CGVector{
        return CGVector(dx: self.dx + dx, dy: self.dy + dy)
    }
    func add(y: CGFloat) -> CGVector{
        return CGVector(dx: self.dx, dy: self.dy + y)
    }
    static func +(a: CGVector, b: CGVector) -> CGVector{
        return CGVector(dx: a.dx + b.dx, dy: a.dy + b.dy)
    }
    static func +=(a: inout CGVector, b: CGVector){
        a.dx += b.dx
        a.dy += b.dy
    }
    static func -(a: CGVector, b: CGVector) -> CGVector{
        return CGVector(dx: a.dx - b.dx, dy: a.dy - b.dy)
    }
    static func -=(a: inout CGVector, b: CGVector){
        a.dx -= b.dx
        a.dy -= b.dy
    }
    static func *(a: CGVector, b: CGFloat) -> CGVector{
        return CGVector(dx: a.dx * b, dy: a.dy * b)
    }
    static func *=(a: inout CGVector, b: CGFloat){
        a.dx *= b
        a.dy *= b
    }
    static func /(a: CGVector, b: CGFloat) -> CGVector{
        return CGVector(dx: a.dx / b, dy: a.dy / b)
    }
    static func /=(a: inout CGVector, b: CGFloat){
        a.dx /= b
        a.dy /= b
    }
}

extension FloatingPoint{
    static postfix func %(_ num: Self) -> Self{
        return num / Self(100)
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

extension SKSpriteNode{
    func fitTo(_ scene: SKSpriteNode){
        let scale = max(scene.size.width / self.size.width, scene.size.height / self.size.height)
        self.setScale(scale)
        self.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
    }
    func fitTo(_ scene: SKScene){
        let scale = max(scene.size.width / self.size.width, scene.size.height / self.size.height)
        self.setScale(scale)
        self.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
    }
    func pos(mx: CGFloat = 0.5, my: CGFloat = 0.5, x: CGFloat = 0, y: CGFloat = 0) -> CGPoint{
        return CGPoint(x: self.size.width * mx + x, y: self.size.height * my + y)
    }
}
extension SKNode{
    func fiddle(_ refsize: CGSize? = nil){
        var x = CGFloat(), y = CGFloat(), mx = CGFloat(0.5), my = CGFloat(0.5)
        var r = 1.0, g = 1.0, b = 1.0
        reg.x{a in
            x = a
            self.position.x = mx * (refsize ?? self.scene?.frame.size ?? .zero).width + x
        }
        reg.y{a in
            y = a
            self.position.y = my * (refsize ?? self.scene?.frame.size ?? .zero).height + y
        }
        reg.mx{a in
            mx = a
            self.position.x = mx * (refsize ?? self.scene?.frame.size ?? .zero).width + x
        }
        reg.my{a in
            my = a
            self.position.y = my * (refsize ?? self.scene?.frame.size ?? .zero).height + y
        }
        reg.sx{a in (self as? SKSpriteNode)?.anchorPoint.x = a;(self as? SKLabelNode)?.horizontalAlignmentMode = a < 0.45 ? .left : (a > 0.55 ? .right : .center)}
        reg.sy{a in (self as? SKSpriteNode)?.anchorPoint.y = a;(self as? SKLabelNode)?.verticalAlignmentMode = a < 0.45 ? .bottom : (a > 0.55 ? .top : .center)}
        reg.s{s in self.setScale(s)}
        reg.z{z in self.zPosition = z}
        reg.r{a in r = Double(a)/255; let col = UIColor(red: r, green: g, blue: b, alpha: 1); if let s = self as? SKLabelNode{s.fontColor = col}else if let s = self as? SKSpriteNode{s.color = col}}
        reg.g{a in g = Double(a)/255; let col = UIColor(red: r, green: g, blue: b, alpha: 1); if let s = self as? SKLabelNode{s.fontColor = col}else if let s = self as? SKSpriteNode{s.color = col}}
        reg.b{a in b = Double(a)/255; let col = UIColor(red: r, green: g, blue: b, alpha: 1); if let s = self as? SKLabelNode{s.fontColor = col}else if let s = self as? SKSpriteNode{s.color = col}}
        reg.o{o in self.alpha = o}
        fiddlenode = self
    }
}

extension Data{
    func hexEncodedString(uppercase: Bool = false) -> String {
        return self.map {
            if $0 < 16 {
                return "0" + String($0, radix: 16, uppercase: uppercase)
            } else {
                return String($0, radix: 16, uppercase: uppercase)
            }
        }.joined()
    }
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

extension SKScene{
    static var font = "Arial"
    static var transition = SKTransition.crossFade(withDuration: 0)
    static func renderTo(_ view: SKView){
        let scene = self.init(size: view.frame.size)
        SKScene.transition.pausesIncomingScene = false
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .black
        for stop in stop{
            stop()
        }
        stop.removeAll()
        DispatchQueue.main.async{view.presentScene(scene, transition: SKScene.transition)}
    }
    func label(node: SKLabelNode, _ txt: String, pos: CGPoint, size: CGFloat = 32, color: UIColor = .white, font: String = SKScene.font, zPos: CGFloat = 10, isStatic: Bool = false){
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
    func label(_ txt: String, pos: CGPoint, size: CGFloat = 32, color: UIColor = .white, font: String = SKScene.font, zPos: CGFloat = 10, isStatic: Bool = false) -> SKLabelNode{
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
            for node in Set(self.nodes(at: t.location(in: self))){
                self.nodeDown(node, at: t.location(in: node.parent ?? self))
            }
            touch(at: t.location(in: camera ?? self))
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            var oldNodes = Set(self.nodes(at: t.previousLocation(in: self)))
            for node in Set(self.nodes(at: t.location(in: self))){
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
            for node in Set(self.nodes(at: t.location(in: self))){
                self.nodeUp(node, at: t.location(in: node.parent ?? self))
            }
            release(at: t.location(in: camera ?? self))
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            for node in Set(self.nodes(at: t.location(in: self))){
                self.nodeUp(node, at: t.location(in: node.parent ?? self))
            }
            release(at: t.location(in: camera ?? self))
        }
    }
}


extension Dictionary{
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}

extension SKNode{
    func addChild(_ node: SKNode){
        if node.parent == nil{
            insertChild(node, at: children.count)
        }
    }
}
