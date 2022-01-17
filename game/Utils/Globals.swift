//
//  Globals.swift
//  game
//
//  Created by Matthew on 16/12/2021.
//

import Foundation
import SpriteKit

var energyAmount = 0.0
var lastSentEnergy = 0.0
var energySpace = 100.0
var energyPercent = 0.0
var researchAmount: Float = 0.0
var researchSpace: Float = 10.0
var gemCount: Float = 0



//Array of actions that need to be stopped once scene changes
var stop: [() -> ()] = []
//Execute task in background

//Ship dictionaries
var ships = GameData("/ships")!
//Asteroid dictionaries
var asteroids = GameData("/asteroids")!

//item level dictionaries
var items = GameData("/items")!.map { json -> GameData in
    return GameData(json["path"]!.string ?? "/null")!
}

let (camps, drills, shooters, satellites, dishes, electros) = (items[0], items[1], items[2], items[3], items[4], items[5])

//A sector consists of...
typealias SectorData = ([Planet], (pos: CGPoint, size: CGSize), (name:String,ip:String))
//Map a region position to a list of sectors
var regions: [CGPoint: [SectorData]] = [:]
//All the nodes for the map
var mapnodes: [CGPoint: SKNode] = [:]
//Set of all loaded regions
var loadedRegions: Set<CGPoint> = []
//Disconnect message
var dmessage = "Disconnected!"

let BSTARS = [SKTexture(imageNamed: "bstars-1"),SKTexture(imageNamed: "bstars-2")]
let STARS = [SKTexture(imageNamed: "stars1"), SKTexture(imageNamed: "stars2")]
let BGASSETS = ["asteroid1","asteroid2","asteroid3","asteroid4","rock1", "rock2", "rock3", "planetA", "planetB"].map({a in return SKTexture(imageNamed: a)})


var second: String{
    let s = Int64(NSDate().timeIntervalSince1970) % 60
    return s < 10 ? "0\(s)" : "\(s)"
}

var logs: [String] = []

func uuidstore(_ a: String) -> String{
    var u = UserDefaults.standard.string(forKey: a)
    if u == nil{
        u = UUID().uuidString
        UserDefaults.standard.set(u, forKey: a)
    }
    return u!
}

enum tutorial: Int{
    case welcome = 0
    case thrust = 1
    case dpad = 2
    case shoot = 3
    case followPlanet = 4
    case shootPlanet = 5
    case openNavigations = 6
    case planetIcon = 7
    case buyPlanet = 8
    case editPlanet = 9
    case addItem = 10
    case buyDrill = 11
    case gemFinish = 12
    case done = 13
}
var tutorialProgress: tutorial{
    get{
        return .init(rawValue: UserDefaults.standard.integer(forKey: "tutorial")) ?? .welcome
    }
    set{
        UserDefaults.standard.set(newValue.rawValue, forKey: "tutorial")
    }
}
let tutorials: [(SKLabelHorizontalAlignmentMode, SKLabelVerticalAlignmentMode, mx: CGFloat, my: CGFloat, x: CGFloat, y: CGFloat, String)] = [
    (.left, .bottom, mx: 0, my: 0, x: -40, y: -15, "welcome!"),
    (.left, .bottom, mx: -0.4, my: -0.4, x: 110, y: 110, "hold to accelerate"),
    (.right, .bottom, mx: 0.4, my: -0.4, x: -120, y: 120, "use left/right to\nRotate your ship"),
    (.left, .top, mx: -0.4, my: -0.4, x: 105, y: 120, "press to\nshoot"),
    (.center, .bottom, mx: 0, my: 0.3, x: 0, y: -40, "follow a green arrow\n to land on a planet"),
    (.left, .top, mx: -0.4, my: -0.4, x: 105, y: 120, "shoot the planet\nto gain energy"),
    (.right, .top, mx: 0.43, my: 0.5, x: -50, y: -80, "open the navigation\nmenu"),
    (.right, .top, mx: 0.43, my: 0.1, x: -40, y: 0, "buy the planet"),
    (.left, .bottom, mx: -0.3, my: -0.3, x: 50, y: -10, "buy the planet"),
    (.right, .top, mx: 0.43, my: 0.1, x: -40, y: 0, "edit the planet"),
    (.right, .bottom, mx: 0.5, my: 0, x: -205, y: 80, "add an item"),
    (.left, .bottom, mx: -0.5, my: -0.1, x: 250, y: 0, "buy a drill\nto earn energy\nautomatically"),
    (.left, .bottom, mx: 0, my: -0.3, x: 185, y: 30, "")
]

var animating: Bool = false
