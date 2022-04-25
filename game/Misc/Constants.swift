//
//  Constants.swift
//  game
//
//  Created by Matthew on 05/08/2021.
//

import Foundation
import SpriteKit
import Network

//Non-configurable constants//
let PI256: CGFloat = .pi / 128 //for converting radians to octians
let ROT_STEP = Complex(r: cos(PI256), i: -sin(PI256)) //complex step
let PI20 = CGFloat.pi / 10 //20-step rotation, used in particles
let build = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "nil" //Build Number, used for the debug menu
let ID = (UIDevice.current.identifierForVendor?.uuidString ?? uuidstore("ID")).replacingOccurrences(of: "-", with: "")

//Configurable constants//
//for connecting to local servers
let IPOVERRIDE: String? = nil//"192.168.1.141:65152"
//Game version
let VERSION = 3
//Universal gravitational constant
let G: CGFloat = 0.0001
//FPS (60)
let gameFPS: CGFloat = 60.0
//Size of a region
let REGIONSIZE = 500000
//Starting X and Y

var unlockedpacks: UInt32 = 1

var secx = 7000
var secy = 4000
var ssecx = 7000
var ssecy = 4000

let SUFFIXES = [
    "s": 1,
    "m": 60,
    "h": 3600,
    "d": 86400,
    "K": 1000,
    "M": 1000000,
    "k": 1000,
    "ms": 0.001,
    "%": 0.01
]

let BADGES = ["blank", "badge1", "badge2", "badge3", "badge4", "badge5", "badge6", "badge7", "badge8", "badge9", "badge10", "badge11", "badge12", "badge13", "badge14", "badge15", "badge16", "badge17", "badge18", "badge19", "badge30", "badge31", "badge32"].map({ badge -> SKSpriteNode in
    let node = SKSpriteNode(imageNamed: "boxlock")
    let child = SKSpriteNode(imageNamed: badge)
    child.zPosition = -1
    node.addChild(child)
    node.zPosition = 1
    return node
})

let COLORBOXES = ["thrustbox0", "thrustbox1", "thrustbox2", "thrustbox3"].map({ badge -> SKSpriteNode in
    let node = SKSpriteNode(imageNamed: "boxlock")
    let child = SKSpriteNode(imageNamed: badge)
    child.zPosition = -1
    node.addChild(child)
    node.zPosition = 1
    child.setScale(0.5)
    return node
}), NAMEBOXES = ["namebox0", "namebox1", "namebox2", "namebox3"].map({ badge -> SKSpriteNode in
    let node = SKSpriteNode(imageNamed: "boxlock")
    let child = SKSpriteNode(imageNamed: badge)
    child.zPosition = -1
    node.addChild(child)
    node.zPosition = 1
    child.setScale(0.5)
    return node
})

let PACKPRICES: [Float] = [0, 500, 300, 500]

let SHIPS = ships.dropFirst().map({a in return a["boximg"]?.string ?? "ship1"}).map({ badge -> SKSpriteNode in
    let node = SKSpriteNode(imageNamed: "boxlock")
    let child = SKSpriteNode(imageNamed: badge)
    child.zPosition = -1
    node.addChild(child)
    node.zPosition = 1
    return node
})


let COLORS: [UIColor] = [
    .green,
    .gray,
    .purple,
    .orange
]

let THRUSTCOLORS: [(a: Color, b: Color)] = [
    (a: (r: 1, g: 1, b: 0), b: (r: 1, g: 0, b: 0)),
    (a: (r: 0.6, g: 0.7, b: 0.7), b: (r: 1, g: 0, b: 0)),
    (a: (r: 0.6, g: 0.2, b: 0.6), b: (r: 0.8, g: 0.5, b: 0.8)),
    (a: (r: 0.9, g: 0.6, b: 0.1), b: (r: 0.9, g: 0.2, b: 0.1))
]


var missionTXTS = GameData("/missions/missionindex")!

var MISSIONS: [String: GameData] = ({keys in
    var dict = [String: GameData]()
    for k in keys{
        dict[k] = GameData("/missions/"+k)!
    }
    return dict
})(missionTXTS[0].keys)



let NAMES = [
    "john bob silli hugo best coffee cat locus blob darth random bolt pik dave terrible littl",
    "winner lover ross invader doe smith parker mully hulk boi guy sky inter s player pawn",
    "123 1000 200000 69 420 65535 2147483647 64 541345 9999 1337 911 -ultra thesecond butbetter lovesanime"
].map{a in return a.split(separator: " ")}
