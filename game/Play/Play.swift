//
//  Play.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//

import SpriteKit
import GameKit


let stopSound = SKAction.stop()
let playSound = SKAction.play()

var currentPlanetTexture = SKTexture()

extension Play{
    func suit(_ id: Int){
        //change ship. also changes the characteristics of the ship
        ship.id = id
        let sh = ships[id]
        guard case .string(let t) = sh["texture"] else {fatalError("invalid texture")}
        guard case .number(let radius) = sh["radius"] else {fatalError("invalid radius")}
        guard case .number(let mass) = sh["mass"] else {fatalError("invalid mass")}
        guard case .number(let speed) = sh["speed"] else {fatalError("invalid speed")}
        guard case .number(let spin) = sh["spin"] else {fatalError("invalid spin")}
        ship.thrustMultiplier = speed
        ship.angularThrustMultiplier = spin
        ship.body(radius: CGFloat(radius), mass: CGFloat(mass), texture: SKTexture(imageNamed: t))
        ship.shootPoints = SHOOTPOINTS[id-1]
        ship.shootVectors = SHOOTVECTORS[id-1]
    }
    func construct() {
        if creds != nil{
            gotIp()
        }else{
            
            GKLocalPlayer.local.authenticateHandler = { viewController, error in
                if let viewController = viewController{
                    self.gkview = viewController
                    return
                }
                if error != nil{
                    //guest
                    self.gameGuest()
                }
                self.gameCenterAuthed()
            }
        }
        
        
        cam.addChild(loadingbg)
        loadingbg.lineWidth = 0
        loadingbg.position.y = -0.35 * self.size.height
        loadingbg.fillColor = .gray
        
        cam.addChild(loading)
        loading.lineWidth = 0
        loading.position.y = -0.35 * self.size.height
        loading.fillColor = .white
        loading.zPosition = 1
        loading.xScale = 0
        loading.position.x = -150
        
        cam.position = CGPoint.zero
        self.addChild(cam)
        self.camera = cam
        cam.setScale(0.4)
        ship.alpha = 0
        suit(1)
        tunnel1.anchorPoint = CGPoint(x: 0, y: 0.5)
        tunnel1.position = pos(mx: -0.5, my: 0, x: -5)
        tunnel1.setScale(0.4)
        cam.addChild(tunnel1)
        tunnel2.anchorPoint = CGPoint(x: 1, y: 0.5)
        tunnel2.position = pos(mx: 0.5, my: 0, x: 5)
        tunnel2.setScale(0.4)
        cam.addChild(tunnel2)
        ship.death = 100
        self.addChild(ship)
        vibrateCamera(camera: cam)
        //ACCOUNT
        let nw = accountBG.size.width
        accountBG.position = pos(mx: 0, my: 0.5, x: 0)
        accountBG.setScale(0.3)
        accountBG.zPosition = 1000
        accountBG.anchorPoint = CGPoint(x: 0.5 ,y: 0)
        cam.addChild(accountBG)
        
        accountIcon.position = pos(mx: 0, my: 0.5, x: accountBG.size.width * 0.5 + 150, y: 20)
        accountIcon.anchorPoint = CGPoint(x: 1, y: 1)
        accountIcon.setScale(0.6)
        cam.addChild(accountIcon)
        if(accountIcon.position.x > self.size.width * 0.4 - 70){
            //reposition for smaller screens
            let dif = accountIcon.position.x - self.size.width * 0.4 - 70
            accountIcon.position.x -= dif
            accountBG.setScale((self.size.width - accountIcon.size.width) / nw)
            accountBG.position.x = accountIcon.position.x - accountBG.size.width / 2 - 130
        }
        inlightSpeed.autoplayLooped = true
        
        ship.run(SKAction.fadeAlpha(by: 1, duration: 1).ease(.easeOut))
        ship.producesParticles = true
        var step = 0
        ship.particle = { (_ ship: Object) in
            step = (step + 1) % 16
            let i = max(ship.alpha * 1.5 - 0.45, 0)
            return Particle[State(color: (r: 0.1, g: 0.7, b: 0.7), size: CGSize(width: 11, height: 2), zRot: 0, position: ship.position.add(y: -5), alpha: i), State(color: (r: 1, g: 1, b: 1), size: CGSize(width: 5, height: 2), zRot: 0, position: ship.position.add(y: -35), alpha: 0, delay: TimeInterval(i))]
        }
        ship.particleFrequency = 1
        self.label(node: tapToStart, "loading sector   ", pos: pos(mx: 0, my: -0.3, x: -153), size: 48, color: .white, font: "HalogenbyPixelSurplus-Regular", zPos: 999, isStatic: true)
        tapToStart.horizontalAlignmentMode = .left
        tapToStart.alpha = 0.7
        ship.zPosition = 5
        tapToStart.run(.repeatForever(.sequence([
            .wait(forDuration: 0.5),
            .run{
                self.tapToStart.text = "loading sector.  "
            },
            .wait(forDuration: 0.5),
            .run{
                self.tapToStart.text = "loading sector.. "
            },
            .wait(forDuration: 0.5),
            .run{
                self.tapToStart.text = "loading sector..."
            },
            .wait(forDuration: 0.5),
            .run{
                self.tapToStart.text = "loading sector   "
            }
        ])), withKey: "dotdotdot")
        
        self.addChild(inlightSpeed)
        DEBUG_TXT.fontSize = 15
        DEBUG_TXT.position = pos(mx: -0.5, my: 0.5, x: 20, y: -20)
        DEBUG_TXT.color = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        DEBUG_TXT.fontColor = .white
        DEBUG_TXT.horizontalAlignmentMode = .left
        DEBUG_TXT.verticalAlignmentMode = .top
        DEBUG_TXT.numberOfLines = 20
        DEBUG_TXT.zPosition = .infinity
        cam.addChild(DEBUG_TXT)
        api.position(completion: sectorpos)
    }
    override func didMove(to view: SKView) {
        startAnimation()
        guard !moved else{return}
        guard ready else{return}
        moved = true
        thrustSound.autoplayLooped = true
        loadingbg.removeFromParent()
        loading.removeFromParent()
        tapToStart.horizontalAlignmentMode = .center
        tapToStart.position.x = 0
        tapToStart.alpha = 0
        tapToStart.run(.fadeAlpha(to: 0.7, duration: 0.7), withKey: "in")
        ship.position = CGPoint(x: CGFloat(secx) - sector.1.pos.x, y: CGFloat(secy) - sector.1.pos.y)
        cam.position = CGPoint(x: ship.position.x, y: ship.position.y - 0.08 * self.size.height)
        for particle in particles{
            particle.position += ship.position
        }
        border1.zRotation = .pi / 2
        border1.position.y = (cam.position.y < 0 ? -0.5 : 0.5) * sector.1.size.height
        border2.position.x = (cam.position.x < 0 ? -0.5 : 0.5) * sector.1.size.width
        border1.xScale = cam.position.y < 0 ? 2 : -2
        border2.xScale = cam.position.x < 0 ? 2 : -2
        border1.yScale = 2
        border2.yScale = 2
        self.addChild(border1)
        self.addChild(border2)
        
        moveItemIcon.position = pos(mx: 0.5, my: 0, x: -180, y: 100)
        moveItemIcon.size = CGSize(width: 50, height: 50)
        
        tapToStart.removeAction(forKey: "dotdotdot")
        //setting tapToStart label relative to camera (static)
        self.run(SKAction.repeat(SKAction.sequence([
            SKAction.run{
                if self.children.count < self.MIN_NODES_TO_START{
                    self.tapToStart.text = "loading sector..."
                }else{
                    if !self.authed{
                        self.tapToStart.text = "connecting..."
                    }else{
                        self.tapToStart.text = "tap to start"
                    }
                }
            },
            SKAction.wait(forDuration: 0.2)
        ]), count: 100), withKey: "loading")
        stop.append(interval(3){
            self.tapToStart.run(SKAction.moveBy(x: 0, y: 10, duration: 2).ease(.easeOut))
        })
        let _ = timeout(1.5){
            stop.append(interval(3){
                self.tapToStart.run(SKAction.moveBy(x: 0, y: -10, duration: 2).ease(.easeOut))
            })
        }
        DEBUG_TXT.removeFromParent()
    }
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
                vibrateObject(sprite: trail)
                self.cam.addChild(trail)
            }
        }
        for i in 1...3{
            let longTrail = SKSpriteNode(imageNamed: "longTrail\(i)")
            trails.append(longTrail)
            delay += 0.1
            let _ = timeout(delay) {
                self.moveTrail(trail: longTrail)
                vibrateObject(sprite: longTrail)
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
            if x{planetsMap.append(contentsOf: node.children as! [SKShapeNode]);amountOfPlanets += planetsMap.count - 1
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
            a.fillColor = planet.superhot ? .orange : .white
            a.lineWidth = 0
            sector.addChild(a)
            a.name = "planet"
            if x{planetsMap.append(a);amountOfPlanets += 1}
        }
        if x{mainMap=sector;sector.addChild(playerArrow)}
        let box = SKShapeNode(rectOf: CGSize(width: size.width/10, height: size.height/10))
        box.strokeColor = .white
        box.lineWidth = 30
        box.name = "box"
        sector.addChild(box)
        sector.position = pos
        FakemapBG.addChild(sector)
        mapnodes[pos] = sector
        sector.position = CGPoint(x: pos.x / 10, y: pos.y / 10)
    }
    func removeTapToStart(){
        self.tapToStart.removeAction(forKey: "in")
        self.tapToStart.run(SKAction.fadeOut(withDuration: 0.3).ease(.easeOut))
        self.tapToStart.run(SKAction.scale(by: 1.5, duration: 0.2))
    }
    
    var upgradeStats: (price: Double, time: String, powers: [(name: String, old: Double, new: Double, max: Double)])?{
        guard let item = planetLanded?.items[Int(itemRot)] else {return nil}
        let id = Int(item.type.rawValue)
        if id > 127{
            return nil
        }
        if items[id].count < item.lvl + 2{return nil}
        let old = items[id][Int(item.lvl)]
        let new = items[id][Int(item.lvl)+1]
        let max = items[id].count > item.lvl + 2 ? items[id][Int(item.lvl)+2] : new
        var pw = [(name: String, old: Double, new: Double, max: Double)]()
        for (k, v) in new{
            if k == "price" || k == "time"{continue}
            if old[k] == nil{continue}
            pw.append((name: k, old: old[k]!.number!, new: v.number!, max: (max[k] ?? v).number!))
        }
        return (price: new["price"]!.number!, time: formatTime(Int(new["time"]!.number!)), powers: pw.sorted(by: {(a,b) in a.name.count < b.name.count}))
    }
    func startGame(){
        //IMPORTANT SIZE ALGORITHM
        colonizeBG.anchorPoint = CGPoint(x: 1 ,y: 1)
        let dify = (self.size.height + 40) / colonizeBG.size.height
        colonizeBG.size.height = self.size.height + 40
        colonizeBG.size.width *= dify
        colonizeBG.position = pos(mx: -0.5, my: 0.5, x: 250, y: 20)
        colonizeBG.zPosition = 100
        
        self.stars1 = SKAmbientContainer({ n in
            n.texture = STARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(2.5)
            n.texture!.filteringMode = .nearest
        }, frequency: 1, deriviation: 0, blocksize: 1250)
        self.stars2 = SKAmbientContainer({ n in
            n.texture = STARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(1.5)
            n.texture!.filteringMode = .nearest
        }, frequency: 1, deriviation: 0, blocksize: 750)
        self.stars3 = SKAmbientContainer({ n in
            n.texture = BSTARS.randomElement()
            n.size = n.texture!.size()
            n.setScale(1)
            //n.texture!.filteringMode = .nearest
        }, frequency: 1, deriviation: 0, blocksize: 500)
        self.stars4 = SKAmbientContainer({ n in
            n.texture = BGASSETS.randomElement()
            n.size = n.texture!.size()
            n.setScale(0.2)
            n.alpha = 0.2
            n.position.x = random(min: 0, max: 1999)
            n.position.y = random(min: 0, max: 1999)
        }, frequency: 0.5, deriviation: 0.2, blocksize: 2000)
        self.addChild(self.stars1)
        self.addChild(self.stars2)
        self.addChild(self.stars3)
        self.addChild(self.stars4)
        
        
        self.removeAction(forKey: "loading")
        map(planets: planets, size: sector.1.size, pos: sector.1.pos, x: true)
        for (_, v) in regions{
            for s in v{
                if s.1.pos == sector.1.pos{continue}
                map(planets: s.0, size: s.1.size, pos:s.1.pos, x: false)
            }
        }
        
        for p in self.planetindicators{
            p.alpha = 1
        }
        cam.run(SKAction.scale(to: 2, duration: 0.5).ease(.easeInEaseOut))
        startData()
        ship.producesParticles = false
        startPressed = true
        camOffset.y = 0
        //cam.run(SKAction.scale(to: 0.6, duration: 1).ease(.easeInEaseOut))
        let _ = timeout(0.5) { [self] in
            ship.controls = true
            ship.dynamic = true
            ship.particle = Object.defaultParticle
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
        speedLabel.position = CGPoint(x: -speedBG.size.width/2.7 ,y: -speedBG.size.height/3)
        speedLabel.xScale = 1.3
        
        speedBG.addChild(speedLabel)
        dPad.position = pos(mx: 0.4, my: -0.4, x: -50, y: 50)
        dPad.zPosition = 10
        dPad.setScale(1.5)
        cam.addChild(dPad)
        avatar.anchorPoint.x = 0
        avatar.position = pos(mx: -0.5, my: 0.3, x: 20)
        avatar.alpha = 1
        avatar.zPosition = 10
        avatar.setScale(0.3)
        cam.addChild(avatar)
        for i in 0...7 {
            let  energyNode = SKSpriteNode(imageNamed: "energyOff")
            energyNodes.append(energyNode)
            if i == 0{
                energyNodes[i].position = CGPoint(x: 180, y: -43)
            }else{
                energyNodes[i].position = CGPoint(x: energyNodes[i - 1].position.x + energyNodes[0].size.width*0.95, y: -43)
            }
            energyNodes[i].zPosition = avatar.zPosition + 1
            energyNodes[i].setScale(1)
            avatar.addChild(energyNodes[i])
        }
        energyCount.text = "K$ 0"
        energyCount.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        energyCount.zPosition = avatar.zPosition + 1
        energyCount.position = CGPoint(x: 165 , y: -100)
        energyCount.fontColor = UIColor.white
        energyCount.fontSize = 36
        avatar.addChild(energyCount)
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
        
        repairIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: mapIcon.position.y + (mapIcon.size.height * 1.2))
        repairIcon.alpha = 1
        repairIcon.zPosition = 11
        repairIcon.setScale(1.1)
        navBG.addChild(repairIcon)
        
        lightSpeedIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: repairIcon.position.y + (repairIcon.size.height * 1.2) )
        lightSpeedIcon.alpha = 1
        lightSpeedIcon.zPosition = 11
        lightSpeedIcon.setScale(1.1)
        navBG.addChild(lightSpeedIcon)
        
        removeTrackerIcon.position = CGPoint(x: lightSpeedIcon.position.x + (lightSpeedIcon.size.width * 1.5) ,y: lightSpeedIcon.position.y )
        removeTrackerIcon.alpha = 1
        removeTrackerIcon.zPosition = 11
        removeTrackerIcon.setScale(0.9)
        navBG.addChild(removeTrackerIcon)
        
        
        //COLONIZING
        coloPlanet.position = CGPoint(x: -125, y: -120)
        coloPlanet.zPosition = 101
        coloPlanet.setScale(0.5)
        colonizeBG.addChild(coloPlanet)
        coloPlanet.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: 0.07, duration: 1),
                ])))
        
        planetAncher.position = CGPoint(x: coloPlanet.position.x , y: coloPlanet.position.y)
        planetAncher.zPosition = 101
        planetAncher.setScale(0.5)
        colonizeBG.addChild(planetAncher)
        planetAncher.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 0.5, duration: 2).ease(.easeOut),
            SKAction.scale(to: 0.45, duration: 2).ease(.easeOut),
        ])))
        
        backIcon.position = colonizeBG.pos(mx: 0, my: -1, x: -180, y: 60)
        backIcon.zPosition = 101
        backIcon.setScale(0.4)
        colonizeBG.addChild(backIcon)
        
        buyIcon.position = colonizeBG.pos(mx: 0, my: -1, x: -70, y: 60)
        buyIcon.zPosition = 101
        buyIcon.setScale(0.4)
        colonizeBG.addChild(buyIcon)
        
        //COLONIZE LABELS
        
        coloStatsName.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coloStatsName.position = colonizeBG.pos(mx: 0, my: 0, x: -230, y: -240)
        coloStatsName.fontSize = 20
        coloStatsName.text = "Name: Big Ed"
        colonizeBG.addChild(coloStatsName)
        
        coloStatsStatus.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coloStatsStatus.position = colonizeBG.pos(mx: 0, my: 0, x: -230, y: -270)
        coloStatsStatus.fontSize = 20
        coloStatsStatus.text = "status: unowned"
        colonizeBG.addChild(coloStatsStatus)
        
        coloStatsRecource.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coloStatsRecource.position = colonizeBG.pos(mx: 0, my: 0, x: -230, y: -300)
        coloStatsRecource.fontSize = 20
        coloStatsRecource.text = "resource: Blackstone"
        colonizeBG.addChild(coloStatsRecource)
        
        coloStatsPrice.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coloStatsPrice.position = colonizeBG.pos(mx: 0, my: 0, x: -230, y: -330)
        coloStatsPrice.fontSize = 20
        coloStatsPrice.text = "price: 10,000 K$"
        colonizeBG.addChild(coloStatsPrice)
        
        collect.anchorPoint = CGPoint(x: 0 ,y:0.5)
        collect.position = avatar.pos(mx: 0, my: 0, x: 0, y: -300)
        collect.zPosition = 10000
        collect.alpha = 1
        collect.setScale(0.6)
        
        
        collectedLabel.position = collect.pos(mx: 0, my: 0, x: 0, y: 100)
        collectedLabel.zPosition = 100
        collectedLabel.alpha = 1
        collectedLabel.horizontalAlignmentMode = .left
        collectedLabel.text = "500 / 20000"
        collectedLabel.fontSize = 100
        collectedLabel.color = UIColor.white
        
        
        coloIcon.position = CGPoint(x: repairIcon.position.x + (repairIcon.size.width * 1.5) ,y: repairIcon.position.y)
        coloIcon.zPosition = 11
        coloIcon.setScale(0.9)
        
        editColoIcon.position = CGPoint(x: repairIcon.position.x + (repairIcon.size.width * 1.5) ,y: repairIcon.position.y)
        editColoIcon.zPosition = 11
        editColoIcon.setScale(0.9)
        
        
            cockpitIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: lightSpeedIcon.position.y + (lightSpeedIcon.size.height * 1.2) )
            cockpitIcon.alpha = 1
            cockpitIcon.anchorPoint = CGPoint(x: 0.1, y: 0)
            cockpitIcon.zPosition = 11
            cockpitIcon.setScale(0.9)
            navBG.addChild(cockpitIcon)
       //WARNINGS
            
        warning.position = CGPoint(x: 0, y: -healthBar.size.height)
        warning.alpha = 0
        warning.zPosition = 10
        warning.setScale(2)
        healthBar.addChild(warning)
            
            
            
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
            
        shipDirection.position = pos(mx: 0.4, my: -0.4, x: -50, y: 50)
        shipDirection.zPosition = 10
        shipDirection.setScale(1.5)
        cam.addChild(shipDirection)
        
        
            thrustButton.position = pos(mx: -0.4, my: -0.4, x: 50, y: 80)
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
            
        healthBar.position = pos(mx: 0, my: 0.47)
        healthBar.alpha = 1
        healthBar.zPosition = 10
        healthBar.setScale(0.15)
        cam.addChild(healthBar)
            
            
            speedBG.position = CGPoint(x: healthBar.size.width * 1.8, y: -healthBar.size.height * 2.5 )
        speedBG.alpha = 1
        speedBG.zPosition = 10
        speedBG.setScale(2)
        healthBar.addChild(speedBG)
        
        
        tunnel1.run(SKAction.moveBy(x: -200, y: 30, duration: 0.6).ease(.easeOut))
        tunnel1.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeOut))
        tunnel1.removeFromParent()
        tunnel2.run(SKAction.moveBy(x: 200, y: 30, duration: 0.6).ease(.easeOut))
        tunnel2.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeOut))
    
        tunnel2.removeFromParent()
       
    }
    func DisplayWARNING(_ label: String, _ warningType: Int, _ blink: Bool){
        if warningType == 1{
            warning.texture = SKTexture(imageNamed: "warning")
        }else if warningType == 2 {
            warning.texture = SKTexture(imageNamed: "achieved")
        }
        warningLabel.text = "\(label)"
        
        warningLabel.zPosition = 101
        warningLabel.position = pos(mx: 0, my: 0, x: 0, y: -25)
        warningLabel.fontSize = 60
        if warningLabel.parent == nil{warning.addChild(warningLabel)}
        if blink{
            warning.run(SKAction.repeatForever(SKAction.sequence([
            
                SKAction.fadeAlpha(to: 1, duration: 1).ease(.easeInEaseOut),
                SKAction.fadeAlpha(to: 0.4, duration: 1).ease(.easeInEaseOut)
            ])), withKey: "warningAlpha")
        }else{
            warning.run(SKAction.fadeAlpha(to: 1, duration: 1).ease(.easeIn))
        }
    }
    //This function renders the upgrading UI
    func renderUpgradeUI(){
        //remove upgrade nodes, and replace them with addItemIcons
        for label in upgradeNodes{
            label.removeFromParent()
        }
        upgradeTime.removeFromParent()
        upgradePrice.removeFromParent()
        upgradeArrow.removeFromParent()
        upgradeOld.removeFromParent()
        upgradeNew.removeFromParent()
        upgradeOld2.removeFromParent()
        upgradeNew2.removeFromParent()
        upgradebtn.removeFromParent()
        upgradeNodes = []
        guard let (price: price, time: time, powers: powers) = upgradeStats else {return}
        let (type: id, lvl: lvl, capacity: _, upgradeEnd: _) = planetLanded!.items[Int(itemRot)]!
        
        upgradeTime.text = "Time: \(time)"
        upgradePrice.text = "Price: \(formatNum(price))"
        upgradeTime.position = pos(mx: 0.9, my: -0.9)
        upgradeTime.horizontalAlignmentMode = .right
        upgradeTime.fontSize = 60
        buildBG.addChild(upgradeTime)
        upgradePrice.position = pos(mx: 1, my: -0.9)
        upgradePrice.horizontalAlignmentMode = .left
        upgradePrice.fontSize = 60
        buildBG.addChild(upgradePrice)
        upgradeOld = SKSpriteNode(imageNamed: "\(coloNames[Int(id.rawValue)])\(lvl)")
        upgradeNew = SKSpriteNode(imageNamed: "\(coloNames[Int(id.rawValue)])\(lvl+1)")
        upgradeOld.position = pos(mx: 0.6, my: -0.3)
        upgradeNew.position = pos(mx: 1.3, my: -0.3)
        upgradeOld2.position = pos(mx: 0.6, my: -0.65)
        upgradeNew2.position = pos(mx: 1.3, my: -0.65)
        upgradeOld2.fontSize = 60
        upgradeNew2.fontSize = 60
        upgradeOld2.text = "Level \(lvl)"
        upgradeNew2.text = "Level \(lvl+1)"
        upgradeArrow.position = pos(mx: 0.95, my: -0.4)
        upgradeArrow.setScale(0.3)
        upgradebtn.position = pos(mx: 0.95, my: -1.07)
        upgradebtn.setScale(0.7)
        upgradeOld.setScale(1.5)
        upgradeNew.setScale(1.5)
        buildBG.addChild(upgradeArrow)
        buildBG.addChild(upgradeOld)
        buildBG.addChild(upgradeNew)
        buildBG.addChild(upgradeOld2)
        buildBG.addChild(upgradeNew2)
        buildBG.addChild(upgradebtn)
        var i = 0
        var oldOutlineY = -125.0
        for (name: name, old: old, new: new, max: max) in powers{
            let progressLabel1 = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            let progressLabel2 = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            let progress1 = SKSpriteNode(imageNamed: "progress")
            let progress2 = SKSpriteNode(imageNamed: "progress")
            let progress3 = SKSpriteNode(imageNamed: "progressgreen")
            let outline1 = SKSpriteNode(imageNamed: "progressOutline")
            let outline2 = SKSpriteNode(imageNamed: "progressOutline")
            outline1.zPosition = 100
            outline1.setScale(0.7)
            outline1.anchorPoint = CGPoint(x: 0 ,y: 0.5)
            outline1.position = CGPoint(x: 400, y: oldOutlineY)
            
            //buildBG.addChild(outline1)
            //from here is for the inside of the progress bar showing the actual progress
            progress1.zPosition = 99
            progress1.setScale(1)
            progress1.anchorPoint = CGPoint(x: 0, y: 0.5)
            progress1.xScale = old / max * 15
            //outline1.addChild(progress1)
            
            progressLabel1.position = CGPoint(x: outline1.position.x ,y: outline1.position.y + 35)
            progressLabel1.horizontalAlignmentMode = .left
            progressLabel1.zPosition = 100
            progressLabel1.fontSize = 60
            progressLabel1.color = UIColor.white
            //buildBG.addChild(progressLabel1)
            switch name{
            case "persec":
                progressLabel1.text = "Production: \(formatNum(old*3600))/hr"
                progressLabel2.text = "Production: \(formatNum(old*3600))/hr ➪ \(formatNum(new*3600))/hr"
                break
            case "boost":
                progressLabel1.text = "Boost: \(old*100)%"
                progressLabel2.text = "Boost: \(Int(old*100))% ➪ \(Int(new*100))%"
                break
            case "researchboost":
                progressLabel1.text = "Research Boost: \(Int(old*100))%"
                progressLabel2.text = "Research Boost: \(Int(old*100))% ➪ \(Int(new*100))%"
                break
            case "damage":
                progressLabel1.text = "Damage: \(old)"
                progressLabel2.text = "Damage: \(old) ➪ \(new)"
                break
            case "storage":
                progressLabel1.text = "Storage: \(old)"
                progressLabel2.text = "Storage: \(old) ➪ \(new)"
                break
            case "accuracy":
                progressLabel1.text = "Accuracy: \(old*300)%"
                progressLabel2.text = "Accuracy: \(Int(old*300))% ➪ \(Int(new*300))%"
                break
            default:
                progressLabel1.text = "\(name): \(old)"
                progressLabel2.text = "\(name): \(old) ➪ \(new)"
                break
            }
            //from here is for the outline of the progress bar.
            outline2.zPosition = 100
            outline2.setScale(0.7)
            outline2.anchorPoint = CGPoint(x: 0 ,y: 0.5)
            outline2.position = pos(mx: 2.5, my: 0, x: -600, y: oldOutlineY)
            oldOutlineY -= 150
            buildBG.addChild(outline2)
            progressLabel2.position = CGPoint(x: outline2.position.x ,y: outline2.position.y + 35)
            progressLabel2.horizontalAlignmentMode = .left
            progressLabel2.zPosition = 100
            progressLabel2.fontSize = 60
            progressLabel2.color = UIColor.white
            buildBG.addChild(progressLabel2)
            //from here is for the inside of the progress bar showing the actual progress
            progress2.zPosition = 99
            progress2.setScale(1)
            progress2.anchorPoint = CGPoint(x: 0, y: 0.5)
            progress2.xScale = old / max * 15
            outline2.addChild(progress2)
            progress3.zPosition = 98
            progress3.setScale(1)
            progress3.anchorPoint = CGPoint(x: 0, y: 0.5)
            progress3.xScale = new / max * 15
            outline2.addChild(progress3)
            
            upgradeNodes.append(progressLabel1)
            upgradeNodes.append(progressLabel2)
            upgradeNodes.append(progress2)
            upgradeNodes.append(progress3)
            upgradeNodes.append(outline1)
            upgradeNodes.append(outline2)
            upgradeNodes.append(progress1)
            i += 1
        }
       
        
        
    }
    func removeTrackers(){
        for t in tracked{
            for i in t.children{
                if i.zPosition == 9{i.removeFromParent()}
            }
        }
        for t in trackArrows{
            t.removeFromParent()
        }
        tracked.removeAll()
        trackArrows.removeAll()
    }
    func constantLazer(){

        usedShoot = true
        newShoot = true
        usingConstantLazer = true
        if case .number(let f) = ships[ship.id]["shootspeed"]{
            ship.shootFrequency = f
        }
        ship.shootQueue = 1 - ship.shootFrequency
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
        ]), withKey: "constantLazer")
    }
    func landed(){
        planetLanded = planetTouched
        if planetLanded?.ownedState == .yours{
            if editColoIcon.parent == nil{
                navBG.addChild(editColoIcon)
                collect.addChild(collectedLabel)
                avatar.addChild(collect)
            }
        }
    }
    func takeoff(){
        editColoIcon.removeFromParent()
        collectedLabel.removeFromParent()
        collect.removeFromParent()
        coloArrow.removeFromParent()
        buildBG.removeFromParent()
        if !presence{planetLanded = nil}
        else{planetEditMode()}
    }
    
    func increseEnergy(){
    }
    func hideControls(){
        
        navArrow.removeFromParent()
        thrustButton.removeFromParent()
        dPad.removeFromParent()
        shipDirection.removeFromParent()
    }
    func showControls(){
        guard started else {return}
        if navArrow.parent == nil{cam.addChild(navArrow)}
        if dPad.parent == nil{cam.addChild(dPad)}
        if thrustButton.parent == nil{cam.addChild(thrustButton)}
        if shipDirection.parent == nil{cam.addChild(shipDirection)}
    }
    func didBuy(_ success: Bool){
        guard success else{
            //FAILED TO COLONIZE HERE
            DisplayWARNING("error: try again later", 1, false)
            return
        }
        cam.run(SKAction.sequence([
            .run{ self.DisplayWARNING("colonized successfuly",2,false)},
            .wait(forDuration: 2),
            .run{self.cam.removeAction(forKey: "warningAlpha")},
            .run{  self.warning.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeIn)) },
        ]))
    }
    func planetEditMode(){
        presence.toggle()

        buildBG.anchorPoint = CGPoint(x: 0, y: 1)
        buildBG.position = pos(mx: -0.5, my: 0, x: -50, y: 0)
        buildBG.alpha = 1
        buildBG.zPosition = 1000
        buildBG.setScale(0.4)
        
        coloArrow.anchorPoint = CGPoint(x: 0.5,y: 0)
        coloArrow.position = pos(mx: 0, my: 0.05, x: 0, y: 0)
        coloArrow.alpha = 1
        coloArrow.zPosition = 1000
        coloArrow.setScale(0.15)
        if presence{
            cam.addChild(buildBG)
            cam.addChild(coloArrow)
            cam.addChild(moveItemIcon)
            ship.alpha = 0
            itemRot = 0
            cam.setScale(1)
            planetLandedRot = planetLanded!.zRotation
            planetLanded!.zRotation = 0
            for n in planetLanded!.children{
                if n.name == nil && (n.userData?["type"] as? ColonizeItem)?.type == .satellite{
                    (n as? SKSpriteNode)?.anchorPoint.y += 1.9
                    n.removeAllActions()
                    n.zRotation = -CGFloat(n.userData?["rot"] as! UInt8) * PI256
                }
            }
            while planetLanded!.items[Int(itemRot)] == nil{
                planetLanded!.zRotation += PI256
                itemRot += 1
            }
            for i in 0...3{
                addItemIcons[i].position = CGPoint(x: 600 + CGFloat(i) * 400, y: -240)
            }
            renderUpgradeUI()
        }else{
            ship.alpha = 1
            planetLanded!.zRotation = planetLandedRot
            dragRemainder = .nan
            coloArrow.removeFromParent()
            buildBG.removeFromParent()
            moveItemIcon.removeFromParent()
            for n in planetLanded!.children{
                if n.name == nil && (n.userData?["type"] as? ColonizeItem)?.type == .satellite{
                    n.run(.repeatForever(SKAction.rotate(byAngle: planetLanded!.angularVelocity + 0.05, duration: 1)))
                    (n as? SKSpriteNode)?.anchorPoint.y -= 1.9
                }
            }
            if planetTouched == nil{planetLanded = nil}
            for i in 0...3{
                addItemIcons[i].removeFromParent()
            }
        }
    }
    func didChangeItem(_ success: Bool){
        guard success else {
            dragRemainder = .nan
            return
        }
        dragRemainder = .nan
        renderUpgradeUI()
    }
    
    
    override func nodeDown(_ node: SKNode, at point: CGPoint) {
        
        switch node{
            
        case backIcon:
            if buyScreenShowing{
                colonizeBG.removeFromParent()
                showControls()
                buyScreenShowing = false
            }
            break
        case buyIcon:
            if energyAmount >= 10{
                energyAmount -= 10
                if buyScreenShowing{
                    colonizeBG.removeFromParent()
                    showControls()
                    buyScreenShowing = false
                }
                colonize(planetLanded!)
            }else if energyAmount < 10{
                cam.run(SKAction.sequence([
                    .run{ self.DisplayWARNING("not enough energy",1,false)},
                    .wait(forDuration: 2),
                    .run{self.cam.removeAction(forKey: "warningAlpha")},
                    .run{  self.warning.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeIn)) },
                ]))
            }
            break
        case editColoIcon:
            planetEditMode()
            if !hideControl{
                hideControl.toggle()
                hideControls()
            }else{
                hideControl.toggle()
                showControls()
            }
            
            break
        case collect:
            if planetLanded != nil{collectFrom(planetLanded!)}
            break
        case coloArrow:
            var a: CGFloat = 0
            if point.x > coloArrow.position.x{
                repeat{
                    a += 1
                    itemRot &+= 1
                }while planetLanded!.items[Int(itemRot)] == nil
            }else{
                repeat{
                    a -= 1
                    itemRot &-= 1
                }while planetLanded!.items[Int(itemRot)] == nil
            }
            planetLanded!.run(.rotate(byAngle: a * PI256, duration: abs(a) / 180.0).ease(.easeInEaseOut))
            renderUpgradeUI()
            break
        default:
            break
        }
        if node.parent == buildBG, let i = addItemIcons.firstIndex(of: node as? SKSpriteNode ?? ship){
            var pos = UInt8()
            var gap = 0
            var curGap = 0
            var start = -1
            for i in 0...255{
                if planetLanded!.items[i] == nil{
                    curGap += 1
                }else{
                    if curGap > gap{
                        if start == -1{start = curGap;curGap = 0;continue}
                        gap = curGap
                        pos = UInt8((i - curGap / 2) & 255)
                        curGap = 0
                    }else{
                        curGap = 0
                    }
                }
            }
            if start + curGap > gap{
                gap = start + curGap
                pos = UInt8((start - (start + curGap) / 2) & 255)
            }
            itemRot = pos
            planetLanded!.run(.rotate(toAngle: CGFloat(pos) * PI256, duration: abs(CGFloat(pos)) / 180.0).ease(.easeInEaseOut))
            makeItem(planetLanded!, pos, .init(rawValue: UInt8(i))!)
            renderUpgradeUI()
        }
        if removeTrackerIcon == node{
            removeTrackers()
        }
        if accountIcon == node{
            gkview?.present(controller, animated: true){
                if GKLocalPlayer.local.isAuthenticated{
                    //get token
                    self.gameCenterAuthed()
                }else{
                    //create token
                    self.gameGuest()
                }
            }
            tapToStartPressed = true
        }
        if cockpitIcon == node{
            cockpitIcon.texture = SKTexture(imageNamed: "cockpitOn")
            
            
        }
        if let n = node as? Object{
            guard n != ship else {return}
            guard n as? Planet == nil else{return}
            if let i = tracked.firstIndex(of: n){
                for i in n.children{
                    if i.zPosition == 9{i.removeFromParent()}
                }
                tracked.remove(at: i)
                trackArrows.remove(at: i)
            }else{
                let tracker1 = SKSpriteNode(imageNamed: "tracker1")
                let tracker2 = SKSpriteNode(imageNamed: "tracker2")
                tracker1.zPosition = 9
                tracker1.setScale(1)
                n.addChild(tracker1)
                tracker1.run(.repeatForever(.rotate(byAngle: -.pi, duration: 1)))
                tracker2.zPosition = 9
                tracker2.setScale(1)
                n.addChild(tracker2)
                tracker2.run(.repeatForever(.rotate(byAngle: .pi, duration: 1.3)))
                tracked.append(n)
                
                let a = SKSpriteNode(imageNamed: "arrow\(tracked.count % 3)")
                a.anchorPoint = CGPoint(x: 0.5, y: 1)
                a.setScale(0.25)
                trackArrows.append(a)
            }
        }
        if repairIcon == node{
            if isWarning{
                warning.removeAction(forKey: "warningAlpha")
                warning.alpha = 0
                isWarning = false
            }else{
                DisplayWARNING("emptyWarning",1,true)
                isWarning = true
            }
        }
        
        if warning == node{
            warning.removeAction(forKey: "warningAlpha")
            warning.alpha = 0
        }
        
        if accountIcon == node{
            
            if !showAccount{
                accountIcon.run(SKAction.moveBy(x: 0, y: -200, duration: 0.35).ease(.easeOut))
                accountBG.run(SKAction.moveBy(x: 0, y: -300, duration: 0.35).ease(.easeOut))
                showAccount = true
            }else{
                accountIcon.run(SKAction.moveBy(x: 0, y: 200, duration: 0.35).ease(.easeOut))
                accountBG.run(SKAction.moveBy(x: 0, y: 300, duration: 0.35).ease(.easeOut))
                showAccount = false
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
                if !playingThrustSound{
                    thrustSound.run(SKAction.changeVolume(to: 1.5, duration: 0.01))
                    self.addChild(thrustSound)
                    playingThrustSound = true
                }
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
        if coloIcon == node{
            if !buyScreenShowing{
                buyScreenShowing = true
                cam.addChild(colonizeBG)
                hideControls()
            }
        }
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
            thrustSound.run(SKAction.sequence([
                SKAction.changeVolume(to: 0, duration: 0.2),
                SKAction.run{
                    self.thrustSound.removeFromParent()
                    self.playingThrustSound = false
                }
            ]))
            self.removeAction(forKey: "constantLazer")
            ship.shootFrequency = 0
            self.heatLevel = 0
            self.heatingLaser.alpha = 0
            self.actionStopped = true
            self.coolingDown = false
            usingConstantLazer = false
            ship.thrust = false
            thrustButton.texture = SKTexture(imageNamed: "thrustOff")
            self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
            usingConstantLazer = false
        }
        if dPad == node{
            dPad.texture = SKTexture(imageNamed: "dPad")
            ship.thrustLeft = false
            ship.thrustRight = false
            
        }
        if dragRemainder.isInfinite{dragRemainder = 0}
        if mapIcon == node{
            mapIcon.texture = SKTexture(imageNamed: "map")
        }
        if cockpitIcon == node{
            cockpitIcon.texture = SKTexture(imageNamed: "cockpitOff")
            self.end()
            SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
            DPlay.renderTo(skview)
            SKScene.transition = SKTransition.crossFade(withDuration: 0)
        }
    }
    override func keyDown(_ key: UIKeyboardHIDUsage) {
        hideControls()
        if key == .keyboardUpArrow || key == .keyboardW{
            ship.thrust = true
            if !playingThrustSound{
                thrustSound.removeAllActions()
                thrustSound.removeFromParent()
                thrustSound.run(SKAction.changeVolume(to: 1.5, duration: 0.1))
                self.addChild(thrustSound)
                playingThrustSound = true
            }
        }else if key == .keyboardRightArrow || key == .keyboardD{
            ship.thrustRight = true
        }else if key == .keyboardLeftArrow || key == .keyboardA{
            ship.thrustLeft = true
        }else if key == .keyboardDownArrow || key == .keyboardS || key == .keyboardK{
            if !usingConstantLazer{
                self.actionStopped = false
                constantLazer()
            }
        }else if key == .keyboardM{
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
        if key == .keyboardN{
            ship.encode(data: &shipStates)
        }else if key == .keyboardB{
            guard shipStates.count >= 14 else{return}
            ship.decode(data: &shipStates)
        }else if key == .keyboardEqualSign{
            send(Data([127]))
            dmessage = "Disconnected :O"
            end()
            Disconnected.renderTo(skview)
        }else if key == .keyboardF3 || key == .keyboardTab{
            if DEBUG_TXT.parent == nil{
                cam.addChild(DEBUG_TXT)
            }else{DEBUG_TXT.removeFromParent()}
        }
        if key == .keyboardSpacebar{
            if  !showAccount && !startPressed && !tapToStartPressed && children.count > MIN_NODES_TO_START{
                if !playedLightSpeedOut{
                    accountIcon.removeFromParent()
                    removeTapToStart()
                    
                    self.run(lightSpeedOut)
                    playedLightSpeedOut = true
                    //anim
                    //*
                    var mov = 0.1
                    var up = 0.07
                    let _ = timeout(2){
                        up = -0.5
                        self.ship.run(.scale(to: 0.5, duration: 0.5))
                    }
                    var stop = {}
                    let stop1 = interval(0.05){
                        mov = -sign(mov) * max(0, abs(mov) + up)
                        if(abs(mov) < 0.01){
                            return stop()
                        }
                        self.ship.xScale *= 0.99
                        self.cam.run(SKAction.moveBy(x: mov, y: 0, duration: 0.05).ease(.easeOut))
                    }
                    let stop2 = interval(0.06){
                        self.cam.run(SKAction.moveBy(x: 0, y: mov, duration: 0.06).ease(.easeOut))
                    }
                    stop = {stop1();stop2()}
                    let _ = "*///" //this line is useless but its for the comment switch so dont delete it
                    let _ = timeout(2) {
                        self.startGame()
                        self.removeAction(forKey: "inLightSpeed")
                        self.inlightSpeed.removeFromParent()
                    }
                }
            }
        }
    }
    override func keyUp(_ key: UIKeyboardHIDUsage) {
        if key == .keyboardUpArrow || key == .keyboardW{
            ship.thrust = false
            thrustSound.run(SKAction.sequence([
                SKAction.changeVolume(to: 0, duration: 0.2),
                SKAction.run{
                    self.thrustSound.removeFromParent()
                    self.playingThrustSound = false
                }
            ]))
            self.playingThrustSound = false
        }else if key == .keyboardRightArrow || key == .keyboardD{
            ship.thrustRight = false
        }else if key == .keyboardLeftArrow || key == .keyboardA{
            ship.thrustLeft = false
        }else if key == .keyboardDownArrow || key == .keyboardS || key == .keyboardK{
            self.removeAction(forKey: "constantLazer")
            ship.shootFrequency = 0
            self.heatLevel = 0
            self.heatingLaser.alpha = 0
            self.actionStopped = true
            self.coolingDown = false
            usingConstantLazer = false
            self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
        }else if key == .keyboardC{
            self.end()
            SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
            DPlay.renderTo(skview)
            SKScene.transition = SKTransition.crossFade(withDuration: 0)
        }
    }
    override func swipe(from a: CGPoint, to b: CGPoint) {
        if !dragRemainder.isNaN{
            if abs(a.x) > self.size.width / 5{
                dragRemainder = sign(a.x) * .infinity
                return
            }else if dragRemainder.isInfinite{
                dragRemainder = 0
            }
            dragRemainder += (b.x - a.x) / 12
            let d = dragRemainder
            dragRemainder.formRemainder(dividingBy: 1)
            var amount = floor(d - dragRemainder + 0.1)
            guard amount != 0 else {return} //shortcut
            while planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] != nil{amount += sign(amount)}
            let l = planetLanded!.children.first(where: {$0.userData?["rot"] as? UInt8 == itemRot})
            planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] = planetLanded!.items[Int(itemRot)]
            planetLanded!.items[Int(itemRot)] = nil
            itemRot &+= UInt8(Int(amount) & 255)
            planetLanded!.run(.rotate(byAngle: amount * PI256, duration: abs(amount) / 10.0))
            l?.run(.rotate(byAngle: -amount * PI256, duration: abs(amount) / 10.0))
            l?.userData?["rot"] = itemRot
            return
        }
        guard showMap else {return}
        if dPad.contains(b) || thrustButton.contains(b){return}
        if mapPress1 != nil && mapPress2 != nil{
            var dx = mapPress1!.x - mapPress2!.x
            var dy = mapPress1!.y - mapPress2!.y
            let d1 = dx * dx + dy * dy
            if closest(a, mapPress1!, mapPress2!){
                mapPress1 = b
            }else{
                mapPress2 = b
            }
            dx = mapPress1!.x - mapPress2!.x
            dy = mapPress1!.y - mapPress2!.y
            let d2 = dx * dx + dy * dy
            var z = sqrt(d2 / d1)
            if FakemapBG.xScale * z > 1{z = 1 / FakemapBG.xScale}
            if FakemapBG.xScale * z < 0.02{z = 0.02 / FakemapBG.xScale}
            FakemapBG.xScale *= z
            FakemapBG.yScale *= z
            FakemapBG.position.x *= z
            FakemapBG.position.y *= z
        }
        FakemapBG.position.x += b.x - a.x
        FakemapBG.position.y += b.y - a.y
    }
    override func touch(at p: CGPoint) {
        if !hideControl{showControls()}
        if mapPress1 == nil{
            mapPress1 = p
        }else if mapPress2 == nil{
            mapPress2 = p
        }else{
            (mapPress1, mapPress2) = (mapPress2, p)
        }
        if  !showAccount && !startPressed && !tapToStartPressed && children.count > MIN_NODES_TO_START{
            if !playedLightSpeedOut{
                accountIcon.removeFromParent()
                removeTapToStart()
                
                self.run(lightSpeedOut)
                playedLightSpeedOut = true
                //anim
                var mov = 0.1
                var up = 0.07
                let _ = timeout(2){
                    up = -0.5
                    self.ship.run(.scale(to: 0.5, duration: 0.5))
                }
                var stop = {}
                let stop1 = interval(0.05){
                    mov = -sign(mov) * max(0, abs(mov) + up)
                    if(abs(mov) < 0.01){
                        return stop()
                    }
                    self.ship.xScale *= 0.99
                    self.cam.run(SKAction.moveBy(x: mov, y: 0, duration: 0.05).ease(.easeOut))
                }
                let stop2 = interval(0.06){
                    self.cam.run(SKAction.moveBy(x: 0, y: mov, duration: 0.06).ease(.easeOut))
                }
                stop = {stop1();stop2()}
                let _ = timeout(2) {
                    self.startGame()
                    self.removeAction(forKey: "inLightSpeed")
                    self.inlightSpeed.removeFromParent()
                }
            }
        }
        tapToStartPressed = false
        
        if presence && moveItemIcon.contains(p){
            if dragRemainder.isNaN{dragRemainder = 0;oldItemRot = itemRot;coloArrow.removeFromParent()}
            else{
                if coloArrow.parent == nil{cam.addChild(coloArrow)}
                changeItem(planetLanded!, Int(oldItemRot), Int(itemRot))
            }
        }
    }
    override func release(at point: CGPoint){
        if mapPress2 != nil{
            //both
            if closest(point, mapPress1!, mapPress2!){
                mapPress1 = mapPress2
                mapPress2 = nil
            }else{
                mapPress2 = nil
            }
        }else if mapPress1 != nil{
            //1
            mapPress1 = nil
        }
    }
}
