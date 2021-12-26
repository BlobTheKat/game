//
//  Structs.swift
//  game
//
//  Created by Matthew on 16/12/2021.
//

import Foundation
import SpriteKit

//encodable and decodable into a buffer
protocol DataCodable {
    func encode(data: inout Data)
    func decode(data: inout Data)
}

prefix operator %
postfix operator %


//JSON used for GameData
enum JSON{
    init(_ v: Any?){
        guard let a = v else{self = .null;return}
        if a is Double{
            self = .number(a as! Double)
        }else if a is String{
            self = .string(a as! String)
        }else if a is [Any]{
            let arr = a as! [Any]
            var res: [JSON] = []
            for a in arr{
                res.append(JSON(a))
            }
            self = .array(res)
        }else if a is Bool{
            self = .bool(a as! Bool)
        }else if a is [String: Any]{
            let arr = a as! [String: Any]
            var res: [String: JSON] = [:]
            for (k, a) in arr{
                res[k] = JSON(a)
            }
            self = .map(res)
        }else{
            self = .null
        }
    }
    
    case map([String: JSON])
    case array([JSON])
    case number(Double)
    case string(String)
    case bool(Bool)
    case null
    var number: Double?{if case .number(let a) = self{return a};return nil}
    var string: String?{if case .string(let a) = self{return a};return nil}
    var bool: Bool?{if case .bool(let a) = self{return a};return nil}
    var array: [JSON]?{if case .array(let a) = self{return a};return nil}
    var map: [String: JSON]?{if case .map(let a) = self{return a};return nil}
    subscript(_ a: String) -> JSON?{
        if case .map(let m) = self{
            return m[a]
        }
        return nil
    }
}


//Imaginary numbers
struct Complex<T> where T: Numeric{
    var r: T
    var i: T
    var x: T{
        get{return r}
        set{r = newValue}
    }
    var y: T{
        get{return i}
        set{i = newValue}
    }
    @inline(__always) static func +(a: Self, b: Self) -> Self{
        return Self(r: a.r + b.r, i: a.i + b.i)
    }
    @inline(__always) static func +=(a: inout Self, b: Self){
        a.i += b.i
        a.r += b.r
    }
    @inline(__always) static func -(a: Self, b: Self) -> Self{
        return Self(r: a.r - b.r, i: a.i - b.i)
    }
    @inline(__always) static func -=(a: inout Self, b: Self){
        a.i -= b.i
        a.r -= b.r
    }
    @inline(__always) static func *(a: Self, b: Self) -> Self{
        return Self(r: a.r * b.r - a.i * b.i, i: a.i * b.r + a.r * b.i)
    }
    @inline(__always) static func *=(a: inout Self, b: Self){
        let r = a.r * b.r - a.i * b.i
        a.i = a.i * b.r + a.r * b.i
        a.r = r
    }
    @inline(__always) static func /(a: Self, b: Self) -> Self where T: FloatingPoint{
        let B = b.r * b.r + b.i * b.i
        return Self(r: (b.r * a.r + b.i * a.i) / B, i: (a.i * b.r - a.r * b.i) / B)
    }
    @inline(__always) static func /=(a: inout Self, b: Self) where T: FloatingPoint{
        let B = b.r * b.r + b.i * b.i
        let r = (b.r * a.r + b.i * a.i) / B
        a.i = (a.i * b.r - a.r * b.i) / B
        a.r = r
    }
    func abs() -> T where T: FloatingPoint{
        return sqrt(r * r - i * i)
    }
    @inline(__always) static func ==(a: Self, b: Self) -> Bool{
        return a.r == b.r && a.i == b.i
    }
    func point() -> CGPoint where T == CGFloat{
        return CGPoint(x: r, y: i)
    }
}
