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
