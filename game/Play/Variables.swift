//
//  Variables.swift
//  game
//
//  Created by Matthew on 15/12/2021.
//

import Foundation
import SpriteKit
import GoogleMobileAds

//Variables for the play scene
class Play: SKScene{
    override init(size: CGSize){
        let diagonal = size.width + size.height
        let divider = pow(diagonal / 1300, 0.6)
        self.AllNav = [avatar, healthBar, navBG, navArrow, thrustButton, dPad, shipDirection]
        super.init(size: CGSize(width: size.width / divider, height: size.height / divider))
        self.construct()
    }
    required init?(coder:NSCoder){abort()}
    //Debug Menu LabelNode
    var swiping = false
    var DEBUG_TXT = SKLabelNode(fontNamed: "Menlo")
    //Minimum Number of nodes to start the game (to detect when textures have all loaded)
    var MIN_NODES_TO_START = 70
    //Player ship
    var ship = Object(radius: 15, mass: 100, texture: SKTexture(imageNamed: "ship1"))
    //Camera
    var cam = SKCameraNode()
    //Sounds for lightspeed and thrust
    let inlightSpeed = SKAudioNode(fileNamed: "InLightSpeed.wav")
    var thrustSound = SKAudioNode(fileNamed: "thrust.wav")
    //ambient sound
    var waitForSound = TimeInterval()
   //playing impact sound
    var impactSound = false
    
   
    //Loading bar (the one that expands)
    let loading = SKShapeNode(rect: CGRect(x: -150, y: 0, width: 300, height: 3))
    //List of all planets, objects and particles on the scene
    var particles: [Particle] = []
    var objects: [Object] = []
    var planets: [Planet] = []
    //Planet arrow nodes
    var planetindicators: [SKSpriteNode] = []
    //Network variables
    var stopPing = {} //Stops the ping timeout (which is used to detect when the server stops responding)
    //Placeholder function for send(_: Data)
    var send = {(_: Data) -> () in}
    //How many steps are left until the game is fully loaded
    var loaded = 2
    //Is everything loaded?
    var ready: Bool{
        return loaded == 0
    }
    //Handle to stop sending data
    var datastop = {}
    //Has shot since last sent packet?
    var usedShoot = false
    //Has started shooting since last sent packet?
    var newShoot = false
    //Is shooting cooling down?
    var coolingDown = false
    //Which object (if any) was shot since last packet?
    var shotObj: Object? = nil
    var planetShot: Planet? = nil
    //Is using shoot right now?
    var usingConstantLazer = false
    //List of tracked objects
    var tracked: [Object] = []
    //List of arrows that point to the tracked objects
    var trackArrows: [SKSpriteNode] = []
    //Current sector
    var sector: SectorData = ([], (pos: CGPoint(x: 0, y: 0), size: CGSize(width: CGFloat.infinity, height: CGFloat.infinity)), (name: "", ip: ""))
    //List of object indexes that need their name tags loaded
    var needsNames = Set<Int>()
    //Is authed in gamecenter?
    var gameAuthed = false
    //List of object IDs that player hit since last packet
    var hits: [UInt32] = []
    //Sequence number for critical packets
    var SEQ = UInt8(255)
    //Set of sequence numbers for which we are waiting a response
    var crits = Set<UInt8>()
    //Local variable that had to be descoped because it's accessed from Object.swift
    //Indicates whether the current node peing processed will need a name tag
    var needsName = false
    //Whether step 1 of 2-Step-Oauth has been completed (See server protocol for more info)
    var step1Completed = false
    //Timestamp of last recieved packet
    var last: DispatchTime = .now()
    //Whether we have been authenticated by the server
    var authed = false
    //IP that we are connecting to
    var ip: String = ""
    //Physics dispatch queue
    let physics = DispatchQueue.main
    //Whether the game has ended. When true, all main actions have already been stopped
    var ended = false
    //Star layers. stars4 is the layer containing background objects like rocks and planets
    var stars1 = SKAmbientContainer()
    var stars2 = SKAmbientContainer()
    var stars3 = SKAmbientContainer()
    var stars4 = SKAmbientContainer()
    //Node showing how much energy we have
    var energyCount = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var researchCount = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var researchIconBecauseAdamWasTooLazy = SKSpriteNode(imageNamed: "researchPoint")
    var gemIcon = SKSpriteNode(imageNamed: "gem")
    var gemLabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    //Squares for the energy bar
    var energyNodes: [SKSpriteNode] = []
    var researchNodes: [SKSpriteNode] = []
    //Queue for spaceUpdate() and cameraUpdate()
    var framesQueued = 0.0
    //last Update
    var lastUpdate: TimeInterval? = nil
    //Sector border nodes
    let border1 = SKSpriteNode(imageNamed: "tunnel1")
    let border2 = SKSpriteNode(imageNamed: "tunnel1")
    //taptostart pressed and all trails disappeared
    var started = false
    //Camera offset, in screen units. Starts at y offset down by 0.2
    var camOffset = CGPoint(x: 0, y: 0.2)
    //Ship velocity
    var vel: CGFloat = 0
    //Technical variable used for dragging items when customizing your planet
    var dragRemainder: CGFloat = .nan
    //direction indicator
    let shipDirection = SKSpriteNode(imageNamed: "direction")
    //Velocity indicator
    var ambient = SKAudioNode()
    let speedLabel =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    //Red player arrow on the map
    let playerArrow = SKSpriteNode(imageNamed: "playerArrow")
    //Extremely technical variables for calculating system data usage
    var lastComplete: UInt64 = SystemDataUsage.complete
    var lastU: UInt64 = 0
    var lastMem: UInt16 = 0
    //A timer that loops from 0 to 19 and repeats, used for actions that happen less than 60 times a second
    var clock20 = 0
    //Which planet is landed on (might not always be the same as planet touched)
    var planetLanded: Planet? = nil
    //Which planet is touched right now
    var planetTouched: Planet? = nil
    //Label that indicated how much energy is on the planet ready to be collected
    let collectedLabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    let collectedLabel2 = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    //Real rotation of planetLanded (used to keep track of rotation when planet is being edited)
    var planetLandedRot: CGFloat = 0
    //Rotation index of current item being edited
    var itemRot: UInt8 = 0
    //Prime example of adam's terrible variable naming. In planet edit mode?
    var presence = false
    //Presses on the map used to keep track of pinch-to-zoom
    var mapPress1: CGPoint? = nil
    var mapPress2: CGPoint? = nil
    //debug for encoding and decoding ship to a local buffer
    var shipStates = Data()
    //Old item rotation used when dragging items
    var oldItemRot: UInt8 = 0
    //tap to start was pressed?
    var tapToStartPressed = false
    //All the planets
    var planetsMap: [SKShapeNode] = []
    //amount of planets
    var amountOfPlanets = 0
    //Container for all map nodes of a specific sector
    var mainMap: SKNode = SKNode()
    //Trail nodes
    var trails: [SKSpriteNode] = []
    //TapToStart screen animated with trails?
    var animated = false
    //didMove(to view:) has been called?
    //Used as a failsafe to prevent calling twice and therefore crashing the game
    var moved = false
    //Player health
    var health = 100.0
    var maxHealth = 100.0
    //Sound Actions
    var lightSpeedOut = SKAction.playSoundFileNamed("LightSpeedOut.wav", waitForCompletion: false)
    var shootSound = SKAction.playSoundFileNamed("Lazer.wav", waitForCompletion: false)
    //Sound variables
    var playedLightSpeedOut = false
    var playingThrustSound = false
    //GameCenter prompt
    var gkview: UIViewController? = nil
    let addItemIcons: [SKSpriteNode] = [SKSpriteNode(imageNamed: "drillIcon"),SKSpriteNode(imageNamed: "shooterIcon"),SKSpriteNode(imageNamed: "satelliteIcon"),SKSpriteNode(imageNamed: "dishIcon"),SKSpriteNode(imageNamed: "electroIcon")]
    let addItemPrices: [SKLabelNode] = items.dropFirst().map{a in
        let n = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
        if a.count < 2{
            n.text = "Unavailable"
            return n
        }
        n.text = formatPrice(a[1])
        return n
    }
    var upgradingHintInterval = {}
    // these are item upgrade variables
    var upgradeNodes : [SKNode] = []
    var upgradePrice = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var upgradeTime = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    let upgradeArrow = SKSpriteNode(imageNamed: "upgradearrow")
    var upgradeOld = SKSpriteNode()
    var upgradeNew = SKSpriteNode()
    var upgradeOld2 = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var upgradeNew2 = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var upgradebtn = SKSpriteNode(imageNamed: "upgradebtn")
    
    var buyScreenShowing = false
    let colonizeBG = SKSpriteNode(imageNamed: "coloBG")
    let coloPlanet = SKSpriteNode(imageNamed: "coloPlanet")
    let buyIcon = SKSpriteNode(imageNamed: "buyIcon")
    let backIcon = SKSpriteNode(imageNamed: "backIcon")
    let planetAncher = SKSpriteNode(imageNamed: "planetAncher")
    var coloStatsStatus = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var coloStatsPrice = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var coloStatsRecource = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var coloStatsName = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    
    var coloStatus = String()
    var coloPrice = String()
    var coloRecsource = String()
    var coloName = String()
    
    let collectImg = SKTexture(imageNamed: "collect")
    let restoreImg = SKTexture(imageNamed: "restore")
    
    let coloIcon = SKSpriteNode(imageNamed: "colonizeOff")
    let editColoIcon = SKSpriteNode(imageNamed: "editPlanet")
    let collect = SKSpriteNode(imageNamed: "collect")
    
    
    let collectStorageLabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    
    let buildBG = SKSpriteNode(imageNamed: "buildBG")
    let coloArrow = SKSpriteNode(imageNamed: "coloArrow")
    let moveItemIcon = SKSpriteNode(imageNamed: "moveitem")
    let addItemIcon = SKSpriteNode(imageNamed: "addicon")
    
    
    let tapToStart =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var currentSpeed = Int()
    var startPressed = false
    var showMap = false
    var actionStopped = false
    var heatLevel = 0
    var showNav = false
    let thrustButton = SKSpriteNode(imageNamed: "thrustOff")
    let heatingLaser = SKSpriteNode(imageNamed: "heating0")
    let dPad = SKSpriteNode(imageNamed: "dPad")
    //ACCOUNT
    let accountIcon = SKSpriteNode(imageNamed: "accountIcon")
    let accountBG = SKSpriteNode(imageNamed: "accountBG")
    var showAccount = false
    
    
    let speedBG = SKSpriteNode(imageNamed: "speedBG")
    let mapBG = SKSpriteNode(imageNamed: "mapBG")
    let FakemapBG = SKSpriteNode(imageNamed: "fakeMapBG")
    let avatar = SKSpriteNode(imageNamed: "avatar")
    
    
    //NAVIGATION
    let navArrow = SKSpriteNode(imageNamed: "navArrow")
    let navBG = SKSpriteNode(imageNamed: "nav")
    let mapIcon = SKSpriteNode(imageNamed: "map")
    let repairIcon = SKSpriteNode(imageNamed: "repairOff")
    let lightSpeedIcon = SKSpriteNode(imageNamed: "lightSpeedOff")
    let cockpitIcon = SKSpriteNode(imageNamed: "inCockpitOff")
    let removeTrackerIcon = SKSpriteNode(imageNamed: "removeTracker")
    var hideControl = false
    //WARNINGS
    var isWarning = false
    let warning = SKSpriteNode(imageNamed: "warning")
    var warningLabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    let healthBar = SKSpriteNode(imageNamed: "health13")
    let tunnel1 = SKSpriteNode(imageNamed: "tunnel1")
    let tunnel2 = SKSpriteNode(imageNamed: "tunnel2")
    let loadingbg = SKShapeNode(rect: CGRect(x: -150, y: 0, width: 300, height: 3))
    
    var netseq = 0
    var myseq = 0
        
    //for statsWall
    let statsWall = SKSpriteNode(imageNamed: "statsWall")
    let statsEdge1 = SKSpriteNode(imageNamed: "statsEdge")
    let statsEdge2 = SKSpriteNode(imageNamed: "statsEdge")
    var statsLabel: [SKLabelNode] = []
    var statsLabel2: [SKLabelNode] = []
    let badgeCropNode = SKCropNode()
    var appleSwipe: CGFloat = 0
    var statsIcons: [SKSpriteNode] = [SKSpriteNode(imageNamed: "shop"),SKSpriteNode(imageNamed: "badge"),SKSpriteNode(imageNamed: "ship")]
    var goingDown: Bool = false
    var stopInterval = {}
    var swipesCropNode = false
    
    var stats = (
        levelbg: SKSpriteNode(imageNamed: "levelbg"),
        levelLabel: SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular"),
        xpLabel: SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular"),
        xpBox: SKSpriteNode(imageNamed: "progressOutline"),
        xpFill: SKSpriteNode(imageNamed: "progressyellow"),
        missions: [(label: SKLabelNode, box: SKSpriteNode, fill: SKSpriteNode, text: SKLabelNode, rewardsbox: SKSpriteNode, xpReward: SKLabelNode, gemReward: SKLabelNode)]()
    )
    
    var tutArrow = SKSpriteNode(imageNamed: "tut")
    var tutInfo = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    
    //ALL NAVIGATIONS ON SCREEN
    let AllNav: [SKSpriteNode]
    
    
    let equip = SKSpriteNode(imageNamed: "equip")
    var shipSuit = -1
    
    let advert = SKSpriteNode(imageNamed: "advert")
    var adIsSliding = false
    
    let cheapPass = SKSpriteNode(imageNamed: "cheap_pass")
    var ad: GADRewardedAd? = nil
    var adstop = {}
    
    var objBoxes: [SKShapeNode] = []
}
