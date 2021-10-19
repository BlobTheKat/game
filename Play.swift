//
//  Play.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//

import SpriteKit

class Play: PlayCore{
    let tapToStart =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var currentSpeed = Int()
    var startPressed = false
    var showMap = false
    var actionStopped = false
    var heatLevel = 0
    var usingConstantLazer = false
    var showNav = false
    let thrustButton = SKSpriteNode(imageNamed: "thrustOff")
    let heatingLaser = SKSpriteNode(imageNamed: "heating0")
    let dPad = SKSpriteNode(imageNamed: "dPad")
    
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
    
    
    
    //WARNINGS
    var isWarning = false
    let warning = SKSpriteNode(imageNamed: "warning")

    let speedUI = SKSpriteNode(imageNamed: "speed29")
    
    let tunnel1 = SKSpriteNode(imageNamed: "tunnel1")
    let tunnel2 = SKSpriteNode(imageNamed: "tunnel2")
    func suit(_ id: Int){
        ship.id = id
        let sh = ships[id]
        guard case .string(let t) = sh["texture"] else {fatalError("invalid texture")}
        guard case .number(let radius) = sh["radius"] else {fatalError("invalid radius")}
        guard case .number(let mass) = sh["mass"] else {fatalError("invalid mass")}
        ship.body(radius: CGFloat(radius), mass: CGFloat(mass), texture: SKTexture(imageNamed: t))
        ship.shootPoints = SHOOTPOINTS[id-1]
        ship.shootVectors = SHOOTVECTORS[id-1]
    }
    override init(size: CGSize) {
        super.init(size: size)
        cam.position = CGPoint.zero
        self.addChild(cam)
        self.camera = cam
        cam.setScale(0.4)
        ship.position.y = 160
        ship.alpha = 0
        suit(1)
        tunnel1.position = pos(mx: -0.13, my: 0.05)
        tunnel1.setScale(0.155)
        self.addChild(tunnel1)
        tunnel2.position = pos(mx: 0.13, my: 0.05)
        tunnel2.setScale(0.155)
        self.addChild(tunnel2)
        self.addChild(ship)
        vibrateCamera(camera: cam)
        didInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var moved = false
    override func didMove(to view: SKView) {
        startAnimation()
        guard !moved else {return}
        guard ready else{return}
        moved = true
        border1.zRotation = .pi / 2
        border1.position.y = (cam.position.y < 0 ? -0.5 : 0.5) * loadstack.size!.height
        border2.position.x = (cam.position.x < 0 ? -0.5 : 0.5) * loadstack.size!.width
        border1.xScale = cam.position.y < 0 ? 2 : -2
        border2.xScale = cam.position.x < 0 ? 2 : -2
        border1.yScale = 2
        border2.yScale = 2
        self.addChild(border1)
        self.addChild(border2)
        ship.run(SKAction.fadeAlpha(by: 1, duration: 1).ease(.easeOut))
        //setting tapToStart label relative to camera (static)
        self.label(node: tapToStart, "tap to start", pos: pos(mx: 0, my: -0.4), size: fmed, color: .white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        self.run(SKAction.repeat(SKAction.sequence([
            SKAction.run{
                if self.children.count < self.MIN_NODES{
                    self.tapToStart.text = "loading..."
                }else{
                    self.tapToStart.text = "tap to start"
                }
            },
            SKAction.wait(forDuration: 0.2)
        ]), count: 100), withKey: "loading")
        //position indicator
        tapToStart.alpha = 0.7
        ship.zPosition = 5
        ship.producesParticles = true
        var step = 0
        ship.particle = { (_ ship: Object) in
            step = (step + 1) % 16
            let i = max(ship.alpha * 1.5 - 0.45, 0)
            return Particle[State(color: (r: 0.1, g: 0.7, b: 0.7), size: CGSize(width: 11, height: 2), zRot: 0, position: ship.position.add(y: -5), alpha: i), State(color: (r: 1, g: 1, b: 1), size: CGSize(width: 5, height: 2), zRot: 0, position: ship.position.add(y: -35), alpha: 0, delay: TimeInterval(i))]
        }
        ship.particleFrequency = 1
        let _ = interval(3) {
            self.tapToStart.run(SKAction.moveBy(x: 0, y: 10, duration: 2).ease(.easeOut))
        }
        let _ = timeout(1.5) {
            let _ = interval(3){
                self.tapToStart.run(SKAction.moveBy(x: 0, y: -10, duration: 2).ease(.easeOut))
            }
        }
        star1.texture!.filteringMode = .nearest
        star2.texture!.filteringMode = .nearest
        star3.texture!.filteringMode = .nearest
        star4.texture!.filteringMode = .nearest
    }
    var trails: [SKSpriteNode] = []
    var animated = false
    func startAnimation(){
        if animated{return}
        animated = true
        var delay = 0.0
        for i in 1...15{
            let trail = SKSpriteNode(imageNamed: "trail\((i%5)+1)")
            trails.append(trail)
            delay += 0.1
            let _ = timeout(delay) {
                self.moveTrail(trail: trail)
                self.vibrateObject(sprite: trail)
                self.cam.addChild(trail)
            }
        }
        for i in 1...3{
            let longTrail = SKSpriteNode(imageNamed: "longTrail\(i)")
            trails.append(longTrail)
            delay += 0.1
            let _ = timeout(delay) {
                self.moveTrail(trail: longTrail)
                self.vibrateObject(sprite: longTrail)
                self.cam.addChild(longTrail)
            }
        }
        vibrateObject(sprite: tunnel1)
        vibrateObject(sprite: tunnel2)
        vibrateObject(sprite: border1)
        vibrateObject(sprite: border2)
    }
    func moveTrail(trail: SKSpriteNode){
        var stop = {}
        //var stopped = false // to be removed in final built once debugged is true
        stop = interval(0.5){ [self] in
            //if stopped{return} // to be removed in final built once debugged is true
            if startPressed{
                trail.removeFromParent()
                stop()
                //stopped = true // to be removed in final built once debugged is true
                trails.remove(at: trails.firstIndex(of: trail)!)
                if trails.count == 0{
                    started = true
                }
            }else{
                let randomPosition = random(min: -25, max: 25)
                trail.position = pos(mx: randomPosition/100 , my: 0.5)
                trail.zPosition = 2
                trail.setScale(0.2)
                trail.run(SKAction.moveBy(x: 0, y: -self.size.height - trail.size.height/2, duration: 0.2))
            }
        }
    }
    var planetsMP: [SKShapeNode] = []
    var amountOfPlanets = 0
    var mainMap: SKNode = SKNode()
    func map(planets: [Planet], size: CGSize, pos: CGPoint, x: Bool = false){
        if let node = mapnodes[pos]{
            node.removeFromParent()
            FakemapBG.addChild(node)
            var box: SKShapeNode? = nil
            for n in node.children{
                if n.name != "planet"{
                    n.removeFromParent()
                    if n.name == "box"{
                        box = n as? SKShapeNode
                    }
                }
            }
            if x{planetsMP.append(contentsOf: node.children as! [SKShapeNode]);amountOfPlanets += planetsMP.count - 1
                mainMap = node
                node.addChild(playerArrow)
            }
            node.addChild(box ?? SKShapeNode())
            return
        }
        let sector = SKNode()
        for planet in planets{
            let a = SKShapeNode(circleOfRadius: planet.radius/10)
            a.position = CGPoint(x: planet.position.x/10, y: planet.position.y/10)
            a.zPosition = 8
            //a.fillColor = planet.superhot ? .orange : .white
            sector.addChild(a)
            a.name = "planet"
            if x{planetsMP.append(a);amountOfPlanets += 1}
        }
        if x{mainMap=sector;sector.addChild(playerArrow)}
        let box = SKShapeNode(rectOf: CGSize(width: size.width/10, height: size.height/10))
        box.strokeColor = .white
        box.lineWidth = 5
        box.name = "box"
        sector.addChild(box)
        sector.position = pos
        FakemapBG.addChild(sector)
        mapnodes[pos] = sector
        sector.position = CGPoint(x: pos.x / 10, y: pos.y / 10)
    }
    func startGame(){
        if children.count > MIN_NODES{
            self.removeAction(forKey: "loading")
            map(planets: planets, size: loadstack.size!, pos: loadstack.pos!, x: true)
            for (_, v) in sectors{
                for s in v{
                    if s.1.pos == loadstack.pos!{continue}
                    map(planets: s.0, size: s.1.size, pos:s.1.pos, x: false)
                }
            }
            
            for p in self.planetindicators{
                p.alpha = 1
            }
        cam.run(SKAction.scale(to: 2, duration: 0.5).ease(.easeInEaseOut))
        startData()
        ship.producesParticles = false
        self.tapToStart.run(SKAction.fadeOut(withDuration: 0.3).ease(.easeOut))
        self.tapToStart.run(SKAction.scale(by: 1.5, duration: 0.2))
        startPressed = true
        camOffset.y = 0
        //cam.run(SKAction.scale(to: 0.6, duration: 1).ease(.easeInEaseOut))
        let _ = timeout(0.5) { [self] in
            ship.controls = true
            ship.dynamic = true
            ship.particle = ship.defParticle
            ship.particleFrequency = 0.2
        }
        cam.removeAction(forKey: "vibratingCamera")
        cam.removeAction(forKey: "vibratingCameras")
        
            speedLabel.text = "320"
            speedLabel.zPosition = 9
            speedLabel.fontSize = 70
            speedLabel.color = .white
            speedLabel.zRotation = 0.165
            speedLabel.horizontalAlignmentMode = .left
            speedLabel.position = CGPoint(x: -self.size.width/5.5 ,y: -self.size.height/6.9)
            speedLabel.xScale = 1.3
            speedBG.addChild(speedLabel)
            
            dPad.position = pos(mx: 0.35, my: -0.25)
            dPad.alpha = 1
            dPad.zPosition = 10
            dPad.setScale(1.5)
            cam.addChild(dPad)
            
       
            
            
        
        avatar.position = pos(mx: -0.385, my: 0.35)
        avatar.alpha = 0.1
        avatar.zPosition = 10
        avatar.setScale(0.7)
        cam.addChild(avatar)
        
            
            self.addChild(star1)
            star1.setScale(2)
            star1.zPosition = -10
            self.addChild(star2)
            star2.setScale(2)
            star2.zPosition = -10
            self.addChild(star3)
            star3.setScale(2)
            star3.zPosition = -10
            self.addChild(star4)
            star4.zPosition = -10
            star4.setScale(2)
        
            
            //NAVIGATION
       
        navArrow.position = pos(mx: 0.43, my: 0.5)
        navArrow.alpha = 1
        navArrow.zPosition = 11
        navArrow.setScale(0.3)
        cam.addChild(navArrow)
            
        navBG.position = CGPoint(x: navArrow.position.x,y: navArrow.position.y + navArrow.size.height)
        navBG.alpha = 1
        navBG.anchorPoint = CGPoint(x: 0.5 ,y: 0)
        navBG.zPosition = 11
        navBG.setScale(0.4)
        cam.addChild(navBG)
            
        mapIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: navBG.size.height/6 )
        mapIcon.alpha = 1
        mapIcon.zPosition = 11
        mapIcon.setScale(0.3)
        navBG.addChild(mapIcon)
            
        repairIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: mapIcon.position.y + (mapIcon.size.height * 1.2) )
        repairIcon.alpha = 1
        repairIcon.zPosition = 11
        repairIcon.setScale(1.1)
        navBG.addChild(repairIcon)
            
        lightSpeedIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: repairIcon.position.y + (repairIcon.size.height * 1.2) )
        lightSpeedIcon.alpha = 1
        lightSpeedIcon.zPosition = 11
        lightSpeedIcon.setScale(1.1)
        navBG.addChild(lightSpeedIcon)
        
       //WARNINGS
            
        warning.position = CGPoint(x: 0 ,y: -speedUI.size.height   )
        warning.alpha = 0
        warning.zPosition = 10
        warning.setScale(2)
        speedUI.addChild(warning)
            
            
            
        mapBG.position = pos(mx: 0, my: 0)
        mapBG.zPosition = 9
        mapBG.setScale(0.12)
        mapBG.alpha = 0
        cam.addChild(mapBG)
            
        FakemapBG.position = pos(mx: 0, my: 0)
        FakemapBG.alpha = 0
        FakemapBG.zPosition = 9
        FakemapBG.setScale(0.1)
        cam.addChild(FakemapBG)
            
        
        playerArrow.zPosition = 9
        playerArrow.setScale(2)
            
        shipDirection.position = pos(mx: 0, my: 0)
        shipDirection.alpha = 1
        shipDirection.zPosition = 9
        shipDirection.setScale(1)
        dPad.addChild(shipDirection)
        
        
            thrustButton.position = pos(mx: -0.35, my: -0.2)
            thrustButton.alpha = 1
            thrustButton.zPosition = 10
            thrustButton.setScale(1.4)
            cam.addChild(thrustButton)
            
            heatingLaser.position = CGPoint(x: 0, y: thrustButton.size.width/2.2)
            heatingLaser.alpha = 0
            heatingLaser.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            heatingLaser.zPosition = 10
            heatingLaser.setScale(0.12)
            thrustButton.addChild(heatingLaser)
            
        speedUI.position = pos(mx: 0, my: 0.47)
        speedUI.alpha = 1
        speedUI.zPosition = 10
        speedUI.setScale(0.15)
        cam.addChild(speedUI)
            
            
            speedBG.position = CGPoint(x: speedUI.size.width * 1.8, y: -speedUI.size.height * 2.5 )
        speedBG.alpha = 1
        speedBG.zPosition = 10
        speedBG.setScale(2)
        speedUI.addChild(speedBG)
        
        
        tunnel1.run(SKAction.moveBy(x: -200, y: 30, duration: 0.6).ease(.easeOut))
        tunnel1.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeOut))
        tunnel1.removeFromParent()
        tunnel2.run(SKAction.moveBy(x: 200, y: 30, duration: 0.6).ease(.easeOut))
        tunnel2.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeOut))
    
        tunnel2.removeFromParent()
        }
        
        
    }
    
    func DisplayWARNING(){
        
        warning.run(SKAction.repeatForever(SKAction.sequence([
        
            SKAction.fadeAlpha(to: 1, duration: 0.8).ease(.easeInEaseOut),
            SKAction.fadeAlpha(to: 0.15, duration: 0.8).ease(.easeInEaseOut)
        ])), withKey: "warningAlpha")
        
        
    }
    override func nodeDown(_ node: SKNode, at point: CGPoint) {
        if !startPressed{
            startGame()
        }
        if repairIcon == node{
           
            if isWarning{
                warning.removeAction(forKey: "warningAlpha")
                warning.alpha = 0
                isWarning = false
            }else{
                DisplayWARNING()
                isWarning = true
            }
        }
        if navArrow == node{
            if showNav == false{
            navArrow.run(SKAction.move(to: pos(mx: 0.43, my: 0 ), duration: 0.35).ease(.easeOut))
            navArrow.run(SKAction.rotate(toAngle: 3.18, duration: 0.35).ease(.easeOut))
                navBG.run(SKAction.move(to: pos(mx: 0.43, my: 0 ), duration: 0.35).ease(.easeOut))
                showNav = true
            }else if showNav == true{
                
                navArrow.run(SKAction.move(to: pos(mx: 0.43, my: 0.5 ), duration: 0.35).ease(.easeOut))
                navArrow.run(SKAction.rotate(toAngle: 0, duration: 0.35).ease(.easeOut))
                navBG.run(SKAction.move(to: pos(mx: 0.43, my: 0.5  ), duration: 0.35).ease(.easeOut))
                showNav = false
            }
            
        }
        if thrustButton == node{
            if point.y > thrustButton.position.y + 50{
                thrustButton.texture = SKTexture(imageNamed: "shooting2")
                if !usingConstantLazer{
                    self.actionStopped = false
                    constantLazer()
                }
                
            }else{
                thrustButton.texture = SKTexture(imageNamed: "thrustOn")
                self.removeAction(forKey: "constantLazer")
                ship.shootFrequency = 0
                self.heatLevel = 0
                self.heatingLaser.alpha = 0
                self.actionStopped = true
                self.coolingDown = false
                self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
                usingConstantLazer = false
                ship.thrust = true
            }
            
        }
        if dPad == node{
            if point.x > dPad.position.x{
                ship.thrustRight = true
                dPad.texture = SKTexture(imageNamed: "dPadRight")
                ship.thrustLeft = false
            }else{
                ship.thrustLeft = true
                dPad.texture = SKTexture(imageNamed: "dPadLeft")
                ship.thrustRight = false
            }
        }
        
        if mapIcon == node{
            mapIcon.texture = SKTexture(imageNamed: "mapT")
            
            if showMap == false{
                mapBG.alpha = 1
                FakemapBG.alpha = 1
                showMap = true
                
                FakemapBG.position = CGPoint(x: -mainMap.position.x/10 - playerArrow.position.x/10 ,y: -mainMap.position.y/10 - playerArrow.position.y/10)
            }else if showMap == true{
                mapBG.alpha = 0
                FakemapBG.alpha = 0
                showMap = false
            }
        }
    }
    
    func constantLazer(){
        usingConstantLazer = true
        ship.shootFrequency = SHOOTFREQUENCIES[ship.id-1]
        self.run(SKAction.sequence([

            SKAction.repeat(SKAction.sequence([
            
                SKAction.wait(forDuration: 1),
                SKAction.run {
                    if !self.actionStopped{
                    self.heatingLaser.alpha = 1
                         self.heatLevel += 1
                        self.heatingLaser.texture = SKTexture(imageNamed: "heating\(self.heatLevel)")
                        
                } },
            ]), count: 4 - self.heatLevel),
            SKAction.repeat(SKAction.sequence([
            
                SKAction.run {
                    if !self.actionStopped{
                    self.coolingDown = true
                    self.heatLevel += 1
                    switch self.heatLevel{
                        case 5: self.heatingLaser.texture = SKTexture(imageNamed: "heating4")
                            break
                        case 6:  self.heatingLaser.alpha = 0
                            break
                        case 7:  self.heatingLaser.alpha = 1
                            break
                        case 8:   self.heatingLaser.alpha = 0
                            break
                        case 9:  self.heatingLaser.alpha = 1
                            break
                        case 10:   self.heatingLaser.alpha = 0
                            break
                        case 11:  self.heatingLaser.alpha = 1
                            break
                        default:break
                    }
                    }
                },
                SKAction.wait(forDuration: 0.3),
            ]), count: 7),
            SKAction.wait(forDuration: 0.5),
            SKAction.run{ self.heatLevel = 3},
            SKAction.repeat(SKAction.sequence([
                SKAction.wait(forDuration: 0.7),
                SKAction.run {
                    if !self.actionStopped{
                    self.heatingLaser.texture = SKTexture(imageNamed: "heating\(self.heatLevel)")
                    self.heatLevel -= 1
                    }
                },
            ]), count: 4),
            SKAction.run {
                self.coolingDown = false
                self.heatLevel = 0
                if self.usingConstantLazer{
                    self.constantLazer()
                }
            }
        ]), withKey: "constantLaser")
    }
    override func nodeMoved(_ node: SKNode, at point: CGPoint) {
        if dPad == node{
            if point.x > dPad.position.x{
                ship.thrustRight = true
                dPad.texture = SKTexture(imageNamed: "dPadRight")
                ship.thrustLeft = false
            }else{
                ship.thrustLeft = true
                dPad.texture = SKTexture(imageNamed: "dPadLeft")
                ship.thrustRight = false
            }
        }
        
        if thrustButton == node{
            if point.y > thrustButton.position.y + 50{
                if !usingConstantLazer{
                    thrustButton.texture = SKTexture(imageNamed: "shooting1")
                    self.actionStopped = false
                    constantLazer()
                }
                
            }else{
                thrustButton.texture = SKTexture(imageNamed: "thrustOn")
                self.removeAction(forKey: "constantLazer")
                ship.shootFrequency = 0
                self.heatLevel = 0
                self.heatingLaser.alpha = 0
                self.actionStopped = true
                self.coolingDown = false
                self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
                usingConstantLazer = false
                ship.thrust = true
            }
            
        }
    }
    
    override func nodeUp(_ node: SKNode, at _: CGPoint) {
        if thrustButton == node{
            self.removeAction(forKey: "constantLazer")
            ship.shootFrequency = 0
            self.heatLevel = 0
            self.heatingLaser.alpha = 0
            self.actionStopped = true
            self.coolingDown = false
            self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
            usingConstantLazer = false
            ship.thrust = false
            thrustButton.texture = SKTexture(imageNamed: "thrustOff")
        }
        if dPad == node{
            dPad.texture = SKTexture(imageNamed: "dPad")
            ship.thrustLeft = false
            ship.thrustRight = false
            
        }
        
        if mapIcon == node{
            mapIcon.texture = SKTexture(imageNamed: "map")
        }
    }
    var d = Data()
    override func keyDown(_ key: UIKeyboardHIDUsage) {
        if key == .keyboardUpArrow || key == .keyboardW{
            ship.thrust = true
        }else if key == .keyboardRightArrow || key == .keyboardD{
            ship.thrustRight = true
        }else if key == .keyboardLeftArrow || key == .keyboardA{
            ship.thrustLeft = true
        }
        if key == .keyboardN{
            ship.encode(data: &d)
        }else if key == .keyboardB{
            guard d.count >= 20 else{return}
            ship.decode(data: &d)
        }else if key == .keyboardEqualSign{
            send(Data([127]))
            dmessage = "Y u diskonnekt??"
            end()
            Disconnected.renderTo(skview)
        }
    }
    override func keyUp(_ key: UIKeyboardHIDUsage) {
        if key == .keyboardUpArrow || key == .keyboardW{
            ship.thrust = false
        }else if key == .keyboardRightArrow || key == .keyboardD{
            ship.thrustRight = false
        }else if key == .keyboardLeftArrow || key == .keyboardA{
            ship.thrustLeft = false
        }
    }
    override func swipe(from a: CGPoint, to b: CGPoint) {
        guard showMap else {return}
        if dPad.contains(b) || thrustButton.contains(b){return}
        FakemapBG.position.x += b.x - a.x
        FakemapBG.position.y += b.y - a.y
    }
}
