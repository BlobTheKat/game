//
//  UsefulFunctions.swift
//  game
//
//  Created by Matthew on 24/12/2021.
//

import Foundation
import SpriteKit

func closest(_ test: CGPoint, _ a: CGPoint, _ b: CGPoint) -> Bool{
    //a = true
    //b = false
    let q1 = abs(a.x - test.x) + abs(a.y - test.y)
    let q2 = abs(b.x - test.x) + abs(b.y - test.y)
    return q1 < q2 //if a is closer
}

func print(_ items: Any...){
    let str = items.map({a in "\(a)"}).joined(separator: " ")
    Swift.print(str)
    logs.insert("[\(second)] \(str)", at: 0)
    if logs.count > 10{logs.removeLast()}
}

func fromNow(_ time: Double) -> DispatchTime{
    return .now() + .microseconds(Int(time * 1000000))
}

@inline(__always) func fdiv(_ x: Int, _ y: Int) -> Int{
    return (abs(x) / y) * (x < 0 ? -1 : 1)
}

func timeout(_ after: Double, _ a: @escaping () -> (), label: String = "") -> () -> (){
    var cancelled = false
    if label != ""{print("start \(label)")}
    DispatchQueue.main.asyncAfter(deadline: fromNow(after)){
        if !cancelled{if label != ""{print("exec \(label)")};a()}
    }
    var i = 0
    return {i += 1;if label != ""{print("cancelled \(label) (\(i))")};cancelled = true}
}

func interval(_ every: Double, _ a: @escaping () -> (), label: String = "") -> () -> (){
    var cancelled = false
    var x = {}
    if label != ""{print("start \(label)")}
    x = {
        a()
        if !cancelled{if label != ""{print("exec \(label)")};DispatchQueue.main.asyncAfter(deadline: fromNow(every), execute: x)}
    }
    x()
    var i = 0
    return {i += 1;if label != ""{print("cancelled \(label) (\(i))")};cancelled = true}
}


func random() -> CGFloat{
    return CGFloat(Double(arc4random()) / 0x100000000)
}
func random(min: CGFloat, max: CGFloat) -> CGFloat{
    return floor(random() * (max - min) + min)
}

func randDir(_ radius: CGFloat) -> CGVector{
    let direction = random() * .pi * 2
    return CGVector(dx: sin(direction) * radius, dy: cos(direction) * radius)
}

func dir(_ direction: CGFloat, _ radius: CGFloat) -> CGVector{
    return CGVector(dx: sin(direction) * radius, dy: cos(direction) * radius)
}

func formatTime(_ seconds: Int) -> String {
    if seconds <= 0{return "0s"}
    let s = seconds % 60
    let m = (seconds / 60) % 60
    let h = (seconds / 3600) % 60
    let d = seconds / 86400
    return "\(d>0 ? "\(d) days" : "")\(h>0 ? "\(h)hr" : "")\(m>0 ? "\(m)min" : "")\(s>0 ? "\(s)sec" : "")"
}
func formatNum(_ a: Double) -> String{
    if a == 0{return "0"}
    let p = floor(log10(abs(a)) / 3)
    let b = a / pow(1000, p)
    return "\(b == trunc(b) ? "\(Int(b))" : "\(b)")\(p == 0 ? "" : (p > 5 ? "e\(p*3)" : String("kmbtq"[Int(p-1)])))"
}

func vibrateObject(sprite: SKSpriteNode){
    sprite.position.x += 5
    sprite.position.y += 5
        sprite.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                ])), withKey: "vibratingObject")
                sprite.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.moveBy(x: 0, y: -10, duration: 0.05),
                    SKAction.moveBy(x: 0, y: 10, duration: 0.05),
                ])), withKey: "vibratingObjects")
}
func vibrateCamera(camera: SKCameraNode, amount: CGFloat = 0.5){
    camera.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.moveBy(x: amount, y: 0, duration: 0.1),
                    SKAction.moveBy(x: -amount, y: 0, duration: 0.1),
                    SKAction.moveBy(x: -amount, y: 0, duration: 0.1),
                    SKAction.moveBy(x: amount, y: 0, duration: 0.1),
                ])), withKey: "vibratingCamera")
    camera.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.moveBy(x: 0, y: amount, duration: 0.1),
                    SKAction.moveBy(x: 0, y: -amount, duration: 0.1),
                    SKAction.moveBy(x: 0, y: amount, duration: 0.1),
                    SKAction.moveBy(x: 0, y: -amount, duration: 0.1),
                ])), withKey: "vibratingCameras")
}
func pulsate(node: SKNode, amount: CGFloat, duration: CGFloat){
    stop.append(interval(Double(duration)) {
        node.run(SKAction.fadeAlpha(by: -amount, duration: Double(duration)/2).ease(.easeInEaseOut))
        
        let _ = timeout(Double(duration)/2) {
            node.run(SKAction.fadeAlpha(by: amount, duration: Double(duration)/2).ease(.easeInEaseOut))
        }
    })
}
func bg(_ a: @escaping () -> ()){DispatchQueue.global(qos: .background).async(execute: a)}
