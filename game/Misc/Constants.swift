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

let allSpawnPoints = [
    (x: 8560, y: 52770),
    (x: 16790, y: 62000),
    (x: -27500, y: 71420),
    (x: 44500, y: 56460),
    (x: 67910, y: 53680),
    (x: 78080, y: 81630),
    (x: 64840, y: 95020),
    (x: 35670, y: 104260),
    (x: 31570, y: 113550),
    (x: 41960, y: 125040),
    (x: 83580, y: 197490),
    (x: 106340, y: 206910),
    (x: 128290, y: 221380),
    (x: 157990, y: 214710),
    (x: -10210, y: 261160),
    (x: 120570, y: 267980),
    (x: 77590, y: 282060),
    (x: 175760, y: 350400),
    (x: 229500, y: 351760),
    (x: 234690, y: 351430),
    (x: 284710, y: 310280),
    (x: 270770, y: 255590),
    (x: 332010, y: 393990),
    (x: 327310, y: 278150),
    (x: 383950, y: 238980),
    (x: 352290, y: 198410),
    (x: 357810, y: 163520),
    (x: 302290, y: 141650),
    (x: 340080, y: 114570),
    (x: 352140, y: 96880),
    (x: 374040, y: 79940),
    (x: 366860, y: 62140),
    (x: 351120, y: 43810),
    (x: 351120, y: 25400),
    (x: 322390, y: 42940),
    (x: 302140, y: 27840),
    (x: 304810, y: 11920),
    (x: 322010, y: -6900),
    (x: 290540, y: 10900),
    (x: 268230, y: 8200),
    (x: 264580, y: -16360),
    (x: 279950, y: -19780),
    (x: 279230, y: -30450),
    (x: 252900, y: 22060),
    (x: 219100, y: 10300),
    (x: 224130, y: -7690),
    (x: 239450, y: -19900),
    (x: 221390, y: -37590),
    (x: 251100, y: -48070),
    (x: 200390, y: -28570),
    (x: 181120, y: -25450),
    (x: 178380, y: -12270),
    (x: 193330, y: -6940),
    (x: 201820, y: 9670),
    (x: 188370, y: 9740),
    (x: 179620, y: 13830),
    (x: 160280, y: 21910),
    (x: 138530, y: 23710),
    (x: 133980, y: 6210),
    (x: 92070, y: 6100),
    (x: 102060, y: -5020),
    (x: 95330, y: -17750),
    (x: 114410, y: -32550),
    (x: 121550, y: -23010),
    (x: 59240, y: -32820),
    (x: 85040, y: -32820),
    (x: 77080, y: -22670),
    (x: 70090, y: -13510),
    (x: 66150, y: -1900),
    (x: 44290, y: -12530),
    (x: 22390, y: -12530),
    (x: 21110, y: -28010),
    (x: 11200, y: -33420),
    (x: 6160, y: -22670),
    (x: 7440, y: -8930),
    (x: -9540, y: -25340),
    (x: -26360, y: -28500),
    (x: -13710, y: -15610),
    (x: -22500, y: -6450),
    (x: -7280, y: -4040),
    (x: -14350, y: 350),
    (x: -29710, y: 2980),
    (x: -22570, y: 7220),
    (x: -13410, y: 9060),
    (x: -5410, y: 16130),
    (x: -5410, y: 23600),
    (x: -18660, y: 23600),
    (x: -12690, y: 30590),
    (x: -27530, y: 36750),
    (x: -7770, y: 42230),
    (x: -26140, y: 43770),
    (x: -6950, y: 53760),
    (x: -23620, y: 60900),
    (x: -26820, y: 71830),
    (x: -10930, y: 71980),
    (x: -1010, y: 70290),
    (x: -5290, y: 58610),
    (x: 14090, y: 55530),
    (x: 13860, y: 65070),
    (x: 11200, y: 73480),
    (x: 16040, y: 87120),
    (x: 1020, y: 87600),
    (x: -9690, y: 86930),
    (x: -22200, y: 84000),
    (x: -31020, y: 88510),
    (x: -35790, y: 92980),
    (x: -48490, y: 87270),
    (x: -58180, y: 94330),
    (x: -62420, y: 102850),
    (x: -63440, y: 115210),
    (x: -54270, y: 121670),
    (x: 76790, y: 281780),
    (x: 59810, y: 277380),
    (x: 68750, y: 269680),
    (x: 79380, y: 269640),
    (x: 87340, y: 278060),
    (x: 99960, y: 282830),
    (x: 98160, y: 269910),
    (x: 111720, y: 280090),
    (x: 120090, y: 271030),
    (x: 140640, y: 268670),
    (x: 142440, y: 274860),
    (x: 146240, y: 286320),
    (x: 139740, y: 299020),
    (x: 128920, y: 309160),
    (x: 125950, y: 321440),
    (x: 126030, y: 328010),
    (x: 137560, y: 330980),
    (x: 139550, y: 341650),
    (x: 127340, y: 344050),
    (x: 135040, y: 351980),
    (x: 125460, y: 353590),
    (x: 121710, y: 360990),
    (x: 144210, y: 360990),
    (x: 221100, y: 316900),
    (x: 213240, y: 302620),
    (x: 197730, y: 294020),
    (x: 210580, y: 287330),
    (x: 173620, y: 290640),
    (x: 159460, y: 290640),
    (x: 155030, y: 282680),
    (x: 338810, y: 397280),
    (x: 323340, y: 397240),
    (x: 314320, y: 376430),
    (x: 304520, y: 355020),
    (x: 325780, y: 356860),
    (x: 329910, y: 350210),
    (x: 329910, y: 340480),
    (x: 303320, y: 327790),
    (x: 306510, y: 316970),
    (x: 315560, y: 323470),
    (x: 277290, y: 236550),
    (x: 277290, y: 211870),
    (x: 277360, y: 191850),
    (x: 290170, y: 179870),
    (x: 303170, y: 164060),
    (x: 319130, y: 191140),
    (x: 348090, y: 190880),
    (x: 361050, y: 188290),
    (x: 377240, y: 205980),
    (x: 375850, y: 221870),
    (x: 373930, y: 233280),
    (x: 383320, y: 249620),
    (x: 383320, y: 262620),
    (x: 383770, y: 291950),
    (x: 365180, y: 308590),
    (x: 367280, y: 144450),
    (x: 347410, y: 144490),
    (x: 327990, y: 144490),
    (x: 320070, y: 130220),
    (x: 306730, y: 121320),
    (x: 302600, y: 102500),
    (x: 302450, y: 87100),
    (x: 309810, y: 71210),
    (x: 344330, y: 79360),
    (x: 358530, y: 87210),
    (x: 360030, y: 48860),
    (x: 360030, y: 34060),
    (x: 352180, y: 25200),
    (x: 334570, y: -2220),
    (x: 312820, y: -14240),
    (x: 223350, y: -40050),
    (x: 238970, y: -40050),
    (x: 238070, y: -26560),
    (x: 242880, y: -13000),
    (x: 186500, y: -29490),
    (x: 189770, y: 101140),
    (x: 180150, y: 123910),
    (x: 178910, y: 140100),
    (x: 193450, y: 150690),
    (x: 179480, y: 166460),
    (x: 163960, y: 160300),
    (x: 146090, y: 142310),
    (x: 135980, y: 150120),
    (x: 135760, y: 166280),
    (x: 107320, y: 167210),
    (x: 94930, y: 145350),
    (x: 76260, y: 155800),
    (x: 76180, y: 172170),
    (x: 65630, y: 188660)
]
var (x: secx, y: secy) = allSpawnPoints[Int(UInt(String(ID.suffix(16)), radix: 16)! % 200)]
var ssecx = secx
var ssecy = secy

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
