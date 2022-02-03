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
let IPOVERRIDE: String? = "192.168.1.141:65152"
//Game version
let VERSION = 2
//Universal gravitational constant
let G: CGFloat = 0.0001
//FPS (60)
let gameFPS: CGFloat = 60.0
//Size of a region
let REGIONSIZE = 500000
//Starting X and Y

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

let BADGES = ["blank", "badge1", "badge2", "badge3", "badge4", "badge5", "badge6", "badge7", "badge8", "badge9", "badge10", "badge11", "badge12", "badge13", "badge14", "badge15", "badge16", "badge17", "badge18", "badge19", "badge20", "badge21", "badge22", "badge23", "badge24", "badge25", "badge26", "badge27", "badge28", "badge29", "badge30", "badge31"].map({ badge -> SKSpriteNode in
    let node = SKSpriteNode(imageNamed: "boxlock")
    let child = SKSpriteNode(imageNamed: badge)
    child.zPosition = -1
    node.addChild(child)
    node.zPosition = 1
    return node
})

let SHIPS = ["ship1","ship2","ship3","ship4","ship5","ship6","ship7","ship8","ship9","ship10","ship11","ship12","ship13","ship14","ship15","ship16","ship17","ship18"].map({ badge -> SKSpriteNode in
    let node = SKSpriteNode(imageNamed: "boxlock")
    let child = SKSpriteNode(imageNamed: badge)
    child.zPosition = -1
    node.addChild(child)
    node.zPosition = 1
    return node
})


let COLORS: [UIColor] = [
    .green,
    .yellow,
    .red
]


let missionTXTS = [
    "travel": "Travel %ly",
    "planets": "Colonize % planets",
    "destroy": "Destroy % asteroids",
    "steal": "Destroy % planets",
    "build": "Build % buildings",
    "drill": "Upgrade a drill to level %",
    "canon": "Upgrade a canon to level %",
    "kills": "Kill % players",
    "energy": "Collect % energy",
    "research": "Collect % research points",
    "gems": "Find % gems",
    "flybys": "Fly by % stars",
    "visit": "Visit % sectors"
]

let MISSIONS: [String: GameData] = ({keys in
    var dict = [String: GameData]()
    for k in keys{
        dict[k] = GameData("/"+k)!
    }
    return dict
})(missionTXTS.keys)
