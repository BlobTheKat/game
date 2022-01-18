//
//  Play.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//

import SpriteKit
import GameKit
var waitForSound = Int()

let stopSound = SKAction.stop()
let playSound = SKAction.play()

var currentPlanetTexture = SKTexture()

extension Play{
    func construct() {
        let x = UserDefaults.standard.integer(forKey: "sx")
        let y = UserDefaults.standard.integer(forKey: "sy")
        if x != 0{secx = x}
        if y != 0{secy = y}
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
        let id = UserDefaults.standard.integer(forKey: "shipid")
        ship.suit(id > 0 ? id : 1)
        tunnel1.anchorPoint = CGPoint(x: 0, y: 0.5)
        tunnel1.position = pos(mx: -0.5, my: 0, x: -5)
        tunnel1.setScale(0.4)
        cam.addChild(tunnel1)
        tunnel2.anchorPoint = CGPoint(x: 1, y: 0.5)
        tunnel2.position = pos(mx: 0.5, my: 0, x: 5)
        tunnel2.setScale(0.4)
        cam.addChild(tunnel2)
        ship.death = 100
        ship.controls = false
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
        ship.zPosition = 7
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
        avatar.alpha = 0.2
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
        
        moveItemIcon.position = pos(mx: 0.5, my: 0, x: -170, y: 120)
        moveItemIcon.size = CGSize(width: 50, height: 50)
        addItemIcon.position = pos(mx: 0.5, my: 0, x: -170, y: 50)
        addItemIcon.size = CGSize(width: 50, height: 50)
        moveItemIcon.zPosition = 10
        addItemIcon.zPosition = 10
        
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
        avatar.alpha = 1
    }
    func startAnimation(){
        if animated{return}
        animated = true
        var delay = 0.0
        for i in 1...15{
            let trail = SKSpriteNode(imageNamed: "trail\((i%5)+1)")
            trails.append(trail)
            delay += 0.1
            self.moveTrail(trail: trail, delay)
        }
        for i in 1...3{
            let longTrail = SKSpriteNode(imageNamed: "longTrail\(i)")
            trails.append(longTrail)
            delay += 0.1
            self.moveTrail(trail: longTrail, delay)
        }
        vibrateObject(sprite: tunnel1)
        vibrateObject(sprite: tunnel2)
        vibrateObject(sprite: border1)
        vibrateObject(sprite: border2)
    }
    func moveTrail(trail: SKSpriteNode, _ delay: Double){
        var stop = {}
        var d = delay + 0.1
        stop = interval(0.1){ [self] in
            d -= 0.1
            if d < 0.05{
                d += 0.5
                if trail.parent == nil{vibrateObject(sprite: trail);self.cam.addChild(trail)}
                if startPressed{
                    trail.removeFromParent()
                    stop()
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
    
    var upgradeStats: (price: String, time: String, powers: [(name: String, old: Double, new: Double, max: Double)])?{
        guard let item = planetLanded?.items[Int(itemRot)] else {return nil}
        let id = Int(item.type.rawValue)
        var lvl = 0
        for itm in planetLanded!.items{if itm?.type == .camp{lvl = Int(itm!.lvl);break}}
        let dat = items[Int(item.type.rawValue)][0]
        if Double(item.lvl) >= Double(Double(lvl) - (dat["available"]?.number ?? 1.0)) / (dat["every"]?.number ?? 1.0) + 1.0{return nil}
        if item.upgradeEnd > 0 || items[id].count < item.lvl + 2{return nil}
        let old = items[id][Int(item.lvl)]
        let new = items[id][Int(item.lvl)+1]
        let max = items[id].count > item.lvl + 2 ? items[id][Int(item.lvl)+2] : new
        var pw = [(name: String, old: Double, new: Double, max: Double)]()
        for (k, v) in new{
            if k[0] == "_" || k == "price" || k == "price2" || k == "time"{continue}
            pw.append((name: k, old: old[k]?.number ?? 0, new: v.number!, max: (max[k] ?? v).number!))
        }
        return (price: formatPrice(new), time: formatTime(Int(new["time"]!.number!)), powers: pw.sorted(by: {(a,b) in a.name.count < b.name.count}))
    }
    func refreshXp(){
        stats.levelLabel.text = "level \(level)"
        stats.xpFill.xScale = 0.0737 * Double(xp) / Double(level)
        stats.xpLabel.text = "\(xp)xp"
    }
    func startGame(){
        nextStep(nil)
        //IMPORTANT SIZE ALGORITHM
        colonizeBG.anchorPoint = CGPoint(x: 1, y: 1)
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
        avatar.position = pos(mx: -0.5, my: 0.3, x: 50)
        avatar.alpha = 1
        avatar.zPosition = 10
        avatar.setScale(0.3)
        cam.addChild(avatar)
        for i in 0...7 {
            var energyNode = SKSpriteNode(imageNamed: "energyOff")
            energyNodes.append(energyNode)
            if i == 0{
                energyNodes[i].position = CGPoint(x: 180, y: -43)
            }else{
                energyNodes[i].position = CGPoint(x: energyNodes[i - 1].position.x + energyNodes[0].size.width*0.95, y: -43)
            }
            energyNodes[i].zPosition = avatar.zPosition + 1
            energyNodes[i].setScale(1)
            avatar.addChild(energyNodes[i])
            
            energyNode = SKSpriteNode(imageNamed: "energyOff")
            researchNodes.append(energyNode)
            if i == 0{
                researchNodes[i].position = CGPoint(x: 300, y: 41)
            }else{
                researchNodes[i].position = CGPoint(x: researchNodes[i - 1].position.x + researchNodes[0].size.width*0.95, y: 41)
            }
            researchNodes[i].zPosition = avatar.zPosition + 1
            researchNodes[i].setScale(1)
            avatar.addChild(researchNodes[i])
        }
        energyCount.text = "k$ 0"
        energyCount.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        energyCount.zPosition = avatar.zPosition + 1
        energyCount.position = CGPoint(x: 165, y: -100)
        energyCount.fontColor = UIColor.white
        energyCount.fontSize = 36
        avatar.addChild(energyCount)
        researchCount.text = "r$ 0"
        researchCount.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        researchCount.zPosition = avatar.zPosition + 1
        researchCount.position = CGPoint(x: 300, y: 73)
        researchCount.fontColor = UIColor.white
        researchCount.fontSize = 36
        avatar.addChild(researchCount)
        researchIconBecauseAdamWasTooLazy.zPosition = avatar.zPosition + 1
        researchIconBecauseAdamWasTooLazy.setScale(0.3)
        researchIconBecauseAdamWasTooLazy.position = CGPoint(x: 180, y: 60)
        avatar.addChild(researchIconBecauseAdamWasTooLazy)
        gemIcon.position = CGPoint(x: 180, y: 170)
        gemIcon.zPosition = avatar.zPosition + 1
        gemIcon.setScale(0.4)
        gemIcon.texture?.filteringMode = .linear
        avatar.addChild(gemIcon)
        gemLabel.zPosition = avatar.zPosition + 1
        gemLabel.position = CGPoint(x: 220, y: 160)
        gemLabel.horizontalAlignmentMode = .left
        gemLabel.fontSize = 36
        gemLabel.text = "0"
        avatar.addChild(gemLabel)
        
        // for stats Wall
        statsWall.anchorPoint = CGPoint(x: 0.5 ,y: 0)
        statsWall.zPosition = 300
        statsWall.setScale(0.5)
        
        statsEdge1.anchorPoint = CGPoint(x: 0.5 ,y: 0)
        statsEdge1.position = pos(mx: -0.4, my: 0.1, x: 0, y: 0)
        statsEdge1.zPosition = 101
        statsEdge1.setScale(1)
        statsEdge1.alpha = 0.3
        statsWall.addChild(statsEdge1)
        
        statsEdge2.anchorPoint = CGPoint(x: 0.5 ,y: 0)
        statsEdge2.position = pos(mx: 0.4, my: 0.1, x: 0, y: 0)
        statsEdge2.zPosition = 101
        statsEdge2.setScale(1)
        statsEdge2.alpha = 0.3
        statsWall.addChild(statsEdge2)
        
        for i in 0...4{
            
            statsLabel.append(SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular"))
            statsLabel2.append(SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular"))
            
            statsLabel[i].fontSize = 40
            statsLabel[i].color = UIColor.white
            statsLabel[i].horizontalAlignmentMode = .left
            if i > 0{
                statsLabel[i].position = CGPoint(x: statsLabel[i - 1].position.x ,y: statsLabel[i - 1].position.y + 60)
            }else{
                statsLabel[i].position = pos(mx: 0.45, my: 0.2, x: 0, y: 0)
            }
            statsWall.addChild(statsLabel[i])
            
            
            
            //BREAK
            statsLabel2.append(SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular"))
            
            statsLabel2[i].fontSize = 40
            statsLabel2[i].color = UIColor.white
            statsLabel2[i].horizontalAlignmentMode = .left
            if i > 0{
                statsLabel2[i].position = CGPoint(x: statsLabel2[i - 1].position.x ,y: statsLabel2[i - 1].position.y + 60)
            }else{
                statsLabel2[i].position = CGPoint(x: statsLabel[i].position.x + 200, y: statsLabel[i].position.y)
            }
            statsWall.addChild(statsLabel2[i])
        }
        statsLabel[0].text = "kill:"
        statsLabel[1].text = "deaths:"
        statsLabel[2].text = "kdr:"
        statsLabel[3].text = "planets:"
        statsLabel[4].text = "travel:"
        
        statsLabel2[0].text = "980"
        statsLabel2[1].text = "902"
        statsLabel2[2].text = "1.09"
        statsLabel2[3].text = "19"
        statsLabel2[4].text = "224ly"
        
        for i in 0...2{
            
            statsIcons[i].anchorPoint = CGPoint(x: 0.5 ,y: 0)
            statsIcons[i].zPosition = 101
            statsIcons[i].setScale(0.4)
            
            if i > 0{
                statsIcons[i].position = CGPoint( x: statsIcons[i - 1].position.x , y: statsIcons[i - 1].position.y + (40 + statsIcons[i].size.height) )
            }else{
                statsIcons[i].position = pos(mx: -0.7, my: 0.1, x: 0, y: 0)
            }
            
            statsWall.addChild(statsIcons[i])
        }
        
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
        coloStatsPrice.text = "price: K$ 10,000"
        colonizeBG.addChild(coloStatsPrice)
        
        collect.anchorPoint = CGPoint(x: 0 ,y:0.5)
        collect.position = avatar.pos(mx: 0, my: 0, x: 0, y: -260)
        collect.zPosition = 100
        collect.alpha = 1
        collect.setScale(0.6)
        
        
        collectedLabel.position = collect.pos(mx: 0, my: 0, x: 0, y: 100)
        collectedLabel.zPosition = 100
        collectedLabel.alpha = 1
        collectedLabel.horizontalAlignmentMode = .left
        collectedLabel.text = "0"
        collectedLabel.fontSize = 100
        collectedLabel2.position = collect.pos(mx: 1.6666666667, my: 0, x: 0, y: 100)
        collectedLabel2.zPosition = 100
        collectedLabel2.alpha = 1
        collectedLabel2.horizontalAlignmentMode = .right
        collectedLabel2.text = "0"
        collectedLabel2.fontSize = 100
        collectedLabel2.fontColor = .purple
        
        
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
        wallIcons()
        self.ambientSound()
    }
    func ambientSound(){
        
        
        
        let randomSound = Int(random(min: 1, max: 4))
                    ambient = SKAudioNode(fileNamed: "extras/ambient\(randomSound).wav")
                    
                    switch randomSound{
                    case 1: self.waitForSound = 180
                        break
                    case 2: self.waitForSound = 144
                        break
                    case 3: self.waitForSound = 89
                        break
                    case 4: self.waitForSound = 120
                        break
                    case 5: self.waitForSound = 57
                        break
                    default:break
                    }
                    
        ambient.run(SKAction.changeVolume(to: 0.15, duration: 0))
                        ambient.autoplayLooped = false
                        self.addChild(ambient)
                        ambient.run(.play())
        let _ = timeout(self.waitForSound){
            self.ambient.removeFromParent()
            self.ambientSound()
        }
        
    }

    
    
    func DisplayWARNING(_ label: String, _ warningType: WarningTypes = .warning, _ blink: Bool = false){
        switch warningType{
        case .warning:
            warning.texture = SKTexture(imageNamed: "warning")
            break
        case .achieved:
            warning.texture = SKTexture(imageNamed: "achieved")
            break
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
        let _ = timeout(3){
            self.cam.removeAction(forKey: "warningAlpha")
            self.warning.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeIn))
        }
    }
    func hideUpgradeUI(){
        for label in upgradeNodes{
            label.removeFromParent()
        }
        for icon in addItemIcons{
            icon.removeFromParent()
        }
        for icon in addItemPrices{
            icon.removeFromParent()
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
        upgradingHintInterval()
        upgradingHintInterval = {}
    }
    //This function renders the upgrading UI
    
    func renderUpgradeUI(){
        //remove upgrade nodes, and replace them with addItemIcons
        hideUpgradeUI()
        guard let (type: id, lvl: lvl, capacity: _, upgradeEnd: u) = planetLanded!.items[Int(itemRot)] else {return}
        guard let (price: price, time: time, powers: powers) = upgradeStats else {
            
            if u > 1{
                var time = Int(u) - Int(NSDate().timeIntervalSince1970)
                upgradeTime.text = "Time: \(formatTime(time))"
                upgradeTime.fontSize = 120
                buildBG.addChild(upgradeTime)
                upgradeTime.position = pos(mx: 1.5, my: -0.5)
                upgradeTime.horizontalAlignmentMode = .center
                upgradePrice.fontSize = 80
                buildBG.addChild(upgradePrice)
                upgradePrice.position = pos(mx: 1.5, my: -0.8)
                upgradePrice.horizontalAlignmentMode = .center
                upgradePrice.text = "Finish now (\(formatNum(ceil(Double(time) / 300))) gems)"
                upgradePrice.fontColor = .green
                upgradingHintInterval = interval(1, {
                    time -= 1
                    self.upgradePrice.text = "Finish now (\(formatNum(ceil(Double(time) / 300))) gems)"
                    self.upgradeTime.text = "Time: \(formatTime(time))"
                    
                })
            }else if u == 1{
                upgradeTime.text = "Item Destroyed!"
                upgradeTime.fontSize = 120
                buildBG.addChild(upgradeTime)
                upgradeTime.position = pos(mx: 1.5, my: -0.5)
                upgradeTime.horizontalAlignmentMode = .center
                upgradePrice.fontSize = 80
                buildBG.addChild(upgradePrice)
                upgradePrice.position = pos(mx: 1.5, my: -0.8)
                upgradePrice.horizontalAlignmentMode = .center
                upgradePrice.text = "Repair (\(formatPrice(items[Int(id.rawValue)][Int(lvl)], 1.5)))"
                upgradePrice.fontColor = .orange
            }else{
                upgradeTime.text = "Level \(lvl)"
                upgradeTime.fontSize = 120
                buildBG.addChild(upgradeTime)
                upgradeTime.position = pos(mx: 1.5, my: -0.5)
                upgradeTime.horizontalAlignmentMode = .center
                upgradePrice.fontSize = 80
                buildBG.addChild(upgradePrice)
                upgradePrice.position = pos(mx: 1.5, my: -0.8)
                upgradePrice.horizontalAlignmentMode = .center
                upgradePrice.text = "Upgrade camp to unlock more levels"
                upgradePrice.fontColor = .white
            }
            return
        }
        upgradePrice.fontColor = .white
        upgradeTime.text = "Time: \(time)"
        upgradePrice.text = "Price: \(price)"
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
        let avg = upgradeOld.size.height + upgradeNew.size.height
        upgradeOld.setScale(300 / avg)
        upgradeNew.setScale(300 / avg)
        upgradeOld2.fontSize = 60
        upgradeNew2.fontSize = 60
        upgradeOld2.text = "Level \(lvl)"
        upgradeNew2.text = "Level \(lvl+1)"
        upgradeArrow.position = pos(mx: 0.95, my: -0.4)
        upgradeArrow.setScale(0.3)
        upgradebtn.position = pos(mx: 0.95, my: -1.07)
        upgradebtn.setScale(0.7)
        buildBG.addChild(upgradeArrow)
        buildBG.addChild(upgradeOld)
        buildBG.addChild(upgradeNew)
        buildBG.addChild(upgradeOld2)
        buildBG.addChild(upgradeNew2)
        buildBG.addChild(upgradebtn)
        var i = 0
        var oldOutlineY = -125.0
        for (name: name, old: old, new: new, max: max) in powers{
            if name == "unlocksitem"{
                //unlocks item
                let unlockslabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
                let unlocksIcon = SKSpriteNode(imageNamed: coloNames[Int(new)]+"1")
                unlockslabel.text = "Unlocks:"
                unlockslabel.fontSize = 60
                unlockslabel.position = pos(mx: 2.5, my: 0, x: -300, y: oldOutlineY + 30)
                unlocksIcon.position = pos(mx: 2.5, my: 0, x: -300, y: oldOutlineY - 110)
                unlocksIcon.setScale(200 / unlocksIcon.size.height)
                upgradeNodes.append(unlockslabel)
                upgradeNodes.append(unlocksIcon)
                buildBG.addChild(unlockslabel)
                buildBG.addChild(unlocksIcon)
                oldOutlineY -= 400
                continue
            }
            let progressLabel2 = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            let progress2 = SKSpriteNode(imageNamed: "progress")
            let progress3 = SKSpriteNode(imageNamed: "progressgreen")
            let outline2 = SKSpriteNode(imageNamed: "progressOutline")
            switch name{
            case "persec":
                progressLabel2.text = "Energy: \(formatNum(old*3600))/hr ➪ \(formatNum(new*3600))/hr"
                break
            case "boost":
                progressLabel2.text = "Boost: \(Int(old*100))% ➪ \(Int(new*100))%"
                break
            case "boost2":
                progressLabel2.text = "Research Boost: \(Int(old*100))% ➪ \(Int(new*100))%"
                break
            case "damage":
                progressLabel2.text = "Damage: \(formatNum(old)) ➪ \(formatNum(new))"
                break
            case "storage":
                progressLabel2.text = "Storage: \(formatNum(old)) ➪ \(formatNum(new))"
                break
            case "accuracy":
                progressLabel2.text = "Accuracy: \(Int(old*200))% ➪ \(Int(new*200))%"
                break
            default:
                progressLabel2.text = "\(name): \(formatNum(old)) ➪ \(formatNum(new))"
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
            upgradeNodes.append(progressLabel2)
            upgradeNodes.append(progress2)
            upgradeNodes.append(progress3)
            upgradeNodes.append(outline2)
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
    func startLazer(){
        usedShoot = true
        newShoot = true
        usingConstantLazer = true
        heatingLaser.alpha = 1
        stopInterval()
        if heatLevel <= 40{
            goingDown = false
            ship.shootQueue = 1
            heatingLaser.texture = SKTexture(imageNamed: "heating\(heatLevel / 10)")
        }
        stopInterval = interval(0.1){ [self] in
            heatLevel += goingDown ? -1 : 1
            if heatLevel == 50{
                goingDown = true
            }
            if heatLevel < 1{
                heatingLaser.texture = SKTexture(imageNamed: "heating0")
                if usingConstantLazer{goingDown = false}
                heatLevel = 0
                return
            }
            if heatLevel <= 40 && !goingDown{
                if case .number(let f) = ships[ship.id]["shootspeed"]{
                    ship.shootFrequency = f
                }
                heatingLaser.texture = SKTexture(imageNamed: "heating\(heatLevel / 10)")
            }else if heatLevel > 40{
                ship.shootFrequency = 0
                let stage = (heatLevel - 41) / 2
                if stage % 2 == 0{
                    heatingLaser.alpha = 0
                }else{
                    heatingLaser.alpha = 1
                }
            }else{
                ship.shootFrequency = 0
                heatingLaser.alpha = 1
                heatingLaser.texture = SKTexture(imageNamed: "heating\(heatLevel / 10)")
            }
        }
    }
    func pauseLazer(){
        if usingConstantLazer && tutorialProgress == .shoot { nextStep() }
        usingConstantLazer = false
        if heatLevel < 40{
            goingDown = true
        }
        ship.shootFrequency = 0
    }
    func constantLazer(){
        usedShoot = true
        newShoot = true
        usingConstantLazer = true
        if case .number(let f) = ships[ship.id]["shootspeed"]{
            ship.shootFrequency = f
        }
        ship.shootQueue = 1 - ship.shootFrequency
        if let action = self.action(forKey: "constantLazer"), action.speed == 0{
            action.speed = 1
            heatingLaser.alpha = 1
            return
        }
        self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
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
                    let _ = timeout(5){
                        if !self.usingConstantLazer{
                            self.heatLevel = 0
                            self.coolingDown = false
                            self.removeAction(forKey: "constantLazer")
                        }
                    }
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
    func showLandedUI(){
        if planetLanded?.ownedState == .yours{
            if editColoIcon.parent == nil{
                navBG.addChild(editColoIcon)
                collect.addChild(collectedLabel)
                collect.addChild(collectedLabel2)
                avatar.addChild(collect)
            }
        }
    }
    func hideLandedUI(){
        editColoIcon.removeFromParent()
        collectedLabel.removeFromParent()
        collectedLabel2.removeFromParent()
        collect.removeFromParent()
        coloArrow.removeFromParent()
        buildBG.removeFromParent()
    }
    func landed(){
        planetLanded = planetTouched
        showLandedUI()
        if vel > 50 {
            let impactSound = SKAudioNode(fileNamed: "extras/impact.wav")
            impactSound.run(SKAction.changeVolume(to: 0.3, duration: 0))
            self.addChild(impactSound)
            let _ = timeout(1){
                impactSound.removeFromParent()
            }
        }
        if tutorialProgress == .followPlanet && (planetLanded!.ownedState == .yours || planetLanded!.ownedState == .unowned){
            ship.controls = false
            for a in planetLanded!.items{if a?.type == .drill{tutorialProgress = .gemFinish;ship.controls = true}}
            nextStep()
            
        }else if tutorialProgress == .followPlanet{
            tutInfo.text = "this planet is\nalready owned"
            tutInfo.fontColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)
        }
        vibratePhone(.light)
    }
    func takeoff(){
        if tutorialProgress == .followPlanet{
            tutInfo.text = "follow a green arrow to\nland on an unowned planet"
            tutInfo.fontColor = .white
        }
        editColoIcon.removeFromParent()
        collectedLabel.removeFromParent()
        collectedLabel2.removeFromParent()
        collect.removeFromParent()
        coloArrow.removeFromParent()
        buildBG.removeFromParent()
        if !presence{planetLanded = nil}
        else{let _ = timeout(0.5){if self.planetLanded==nil&&self.presence{self.planetEditMode()}}}
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
            DisplayWARNING("error: try again later", .warning, false)
            return
        }
        DisplayWARNING("colonized successfuly",.achieved,false)
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
            cam.addChild(addItemIcon)
            ship.alpha = 0
            itemRot = 0
            cam.setScale(1)
            planetLandedRot = planetLanded!.zRotation
            planetLanded!.zRotation = 0
            for n in planetLanded!.children{
                let itm = (n.userData?["type"] as? ColonizeItem)
                if n.name == nil && itm?.type == .satellite && itm?.upgradeEnd ?? 0 < 2{
                    (n as? SKSpriteNode)?.anchorPoint.y += 2
                    n.removeAllActions()
                    n.zRotation = -CGFloat(n.userData?["rot"] as! UInt8) * PI256
                }
            }
            while planetLanded!.items[Int(itemRot)] == nil{
                planetLanded!.zRotation += PI256
                itemRot += 1
            }
            renderUpgradeUI()
        }else{
            ship.alpha = 1
            planetLanded!.zRotation = planetLandedRot
            dragRemainder = .nan
            coloArrow.removeFromParent()
            buildBG.removeFromParent()
            moveItemIcon.removeFromParent()
            addItemIcon.removeFromParent()
            for n in planetLanded!.children{
                let itm = (n.userData?["type"] as? ColonizeItem)
                if n.name == nil && itm?.type == .satellite && itm?.upgradeEnd ?? 0 < 2{
                    n.run(.repeatForever(SKAction.rotate(byAngle: planetLanded!.angularVelocity + 0.05, duration: 1)))
                    (n as? SKSpriteNode)?.anchorPoint.y -= 2
                }
            }
            if planetTouched == nil{planetLanded = nil}
            for i in 0...addItemIcons.count-1{
                addItemIcons[i].removeFromParent()
                addItemPrices[i].removeFromParent()
            }
        }
    }
    func didChangeItem(_ success: Bool){
        guard success else {
            dragRemainder = .nan
            return
        }
        dragRemainder = .nan
    }
    
    func wallIcons(){
        let mustard = UIColor(red: 1, green: 0.7, blue: 0, alpha: 1)
        stats.levelbg.position.y = self.size.height * 0.9 - 20
        stats.levelLabel.text = "level \(level)"
        stats.levelLabel.fontColor = mustard
        stats.levelLabel.position.y = self.size.height * 0.9 - 40
        stats.levelLabel.fontSize = 40
        stats.xpBox.position.y = self.size.height * 0.7
        stats.xpBox.setScale(0.5)
        stats.xpLabel.text = "\(xp)xp"
        stats.xpLabel.position = pos(mx: 0, my: 0.7, x: -218, y: -12)
        stats.xpLabel.horizontalAlignmentMode = .left
        stats.xpLabel.zPosition = 2
        stats.xpLabel.fontSize = 30
        stats.xpFill.anchorPoint.x = 0
        stats.xpFill.position = pos(mx: 0, my: 0.7, x: -220, y: 0)
        stats.xpFill.setScale(0.5)
        statsWall.addChild(stats.xpBox)
        statsWall.addChild(stats.levelbg)
        statsWall.addChild(stats.levelLabel)
        statsWall.addChild(stats.xpLabel)
        statsWall.addChild(stats.xpFill)
        for i in 0...2{
            let box = SKSpriteNode(imageNamed: "progressOutline")
            let fill = SKSpriteNode(imageNamed: "progressgreen")
            let text = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            let rewardsbox = SKSpriteNode(imageNamed: "rewards")
            let xpReward = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            let gemReward = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            rewardsbox.position = pos(mx: 0.4, my: 0.5, x: -10.0, y: CGFloat(i * -60) + 2)
            rewardsbox.setScale(1.3)
            rewardsbox.anchorPoint = CGPoint(x: 1.0, y: 0.5)
            xpReward.text = "1000"
            xpReward.position = pos(mx: 0.4, my: 0.5, x: -218.0, y: CGFloat(i * -60))
            xpReward.fontSize = 28
            xpReward.horizontalAlignmentMode = .left
            xpReward.verticalAlignmentMode = .center
            xpReward.fontColor = mustard

            gemReward.text = "10"
            gemReward.position = pos(mx: 0.4, my: 0.5, x: -70.0, y: CGFloat(i * -60))
            gemReward.fontSize = 28.8
            gemReward.fontColor = .green
            gemReward.verticalAlignmentMode = .center
            
            fill.position = pos(mx: -0.4, my: 0.5, x: 22.0, y: CGFloat(i * -60))
            fill.anchorPoint.x = 0
            fill.setScale(0.4)
            box.position = pos(mx: -0.4, my: 0.5, x: 20.0, y: CGFloat(i * -60))
            box.setScale(0.4)
            box.anchorPoint.x = 0
            let label = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            label.text = "Destroy 300 asteroids"
            label.position = pos(mx: -0.4, my: 0.5, x: 18.0, y: 20.0 + CGFloat(i * -60))
            label.fontSize = 25
            label.horizontalAlignmentMode = .left
            label.zPosition = 2
            text.text = "51 / 300"
            text.position = pos(mx: -0.4, my: 0.5, x: 22.0, y: CGFloat(i * -60))
            text.fontSize = 20
            text.horizontalAlignmentMode = .left
            text.verticalAlignmentMode = .center
            text.zPosition = 2
            stats.missions.append((label: label, box: box, fill: fill, text: text, rewardsbox: rewardsbox, xpReward: xpReward, gemReward: gemReward))
            statsWall.addChild(box)
            statsWall.addChild(fill)
            statsWall.addChild(label)
            statsWall.addChild(text)
            statsWall.addChild(rewardsbox)
            statsWall.addChild(gemReward)
            statsWall.addChild(xpReward)
        }
        
    }
    func removeWallIcons(){
        stats.levelbg.removeFromParent()
        stats.levelLabel.removeFromParent()
        stats.xpLabel.removeFromParent()
        stats.xpBox.removeFromParent()
        stats.xpFill.removeFromParent()
        for m in stats.missions{
            m.label.removeFromParent()
            m.box.removeFromParent()
            m.fill.removeFromParent()
            m.text.removeFromParent()
            m.rewardsbox.removeFromParent()
            m.xpReward.removeFromParent()
            m.gemReward.removeFromParent()
        }
        stats.missions.removeAll()
    }
    
    override func nodeDown(_ node: SKNode, at point: CGPoint) {
        if fiddlenode == nil && nodeToFiddle?.zPosition ?? -.infinity < node.zPosition {nodeToFiddle = node}
        if statsWall.parent != nil && !swiping{
            switch node{
            case statsIcons[1]:
                if badgeCropNode.name != "badge"{
                    removeWallIcons()
                    var i = 0
                    statsIcons[0].texture = SKTexture(imageNamed: "shop")
                    statsIcons[1].texture = SKTexture(imageNamed: "statsbtn")
                    statsIcons[2].texture = SKTexture(imageNamed: "ship")
                    badgeCropNode.name = "badge"
                    let w = 0.4 * self.size.width, h = 0.5 * self.size.height
                    badgeCropNode.position.y = h
                    badgeCropNode.position.x = -w
                    let n = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: -h), size: CGSize(width: w * 2, height: h * 2)))
                    n.fillColor = .white
                    n.lineWidth = 0
                    badgeCropNode.maskNode = n
                    badgeCropNode.removeAllChildren()
                    for b in BADGES{
                        b.removeFromParent()
                        badgeCropNode.addChild(b)
                        b.position.y = self.size.height / (i & 1 == 0 ? 4 : -4)
                        b.position.x = CGFloat(i >> 1) * 200 + 150
                        i += 1
                    }
                    badgeCropNode.removeFromParent()
                    statsWall.addChild(badgeCropNode)
                }else{
                    badgeCropNode.removeFromParent()
                    badgeCropNode.name = nil
                    wallIcons()
                    statsIcons[1].texture = SKTexture(imageNamed: "badge")
                }
                break
            case statsIcons[0]:
                if badgeCropNode.name != "shop"{
                    removeWallIcons()
                    statsIcons[0].texture = SKTexture(imageNamed: "statsbtn")
                    statsIcons[1].texture = SKTexture(imageNamed: "badge")
                    statsIcons[2].texture = SKTexture(imageNamed: "ship")
                    let w = 0.4 * self.size.width, h = 0.5 * self.size.height
                    badgeCropNode.position.y = h
                    badgeCropNode.position.x = -w
                    let n = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: -h), size: CGSize(width: w * 2, height: h * 2)))
                    n.fillColor = .white
                    n.lineWidth = 0
                    badgeCropNode.maskNode = n
                    badgeCropNode.removeAllChildren()
                    badgeCropNode.name = "shop"
                    
                    //DISPLAY SHOP
                    let cheapPass = SKSpriteNode(imageNamed: "cheap_pass")
                    let pass = SKSpriteNode(imageNamed: "pass")
                    let cheapPrice = SKSpriteNode(imageNamed: "price300")
                    let price = SKSpriteNode(imageNamed: "price1000")
                    let gems1 = SKSpriteNode(imageNamed: "gems60")
                    let gems2 = SKSpriteNode(imageNamed: "gems300")
                    let gems3 = SKSpriteNode(imageNamed: "gems1000")
                    let gems4 = SKSpriteNode(imageNamed: "gems5000")
                    let dummy = SKSpriteNode(imageNamed: "blank")
                    dummy.setScale(0)
                    cheapPass.position = CGPoint(x: w, y: 80)
                    cheapPrice.position = CGPoint(x: w, y: -100)
                    pass.position = CGPoint(x: w * 2.5 + 50, y: 80)
                    price.position = CGPoint(x: w * 2.5 + 50, y: -100)
                    gems1.position = CGPoint(x: w * 4, y: 80)
                    gems2.position = CGPoint(x: w * 4 + 160, y: 80)
                    gems3.position = CGPoint(x: w * 4, y: -80)
                    gems4.position = CGPoint(x: w * 4 + 160, y: -80)
                    dummy.position.x = w * 5 + 80
                    badgeCropNode.addChild(cheapPass)
                    badgeCropNode.addChild(cheapPrice)
                    badgeCropNode.addChild(pass)
                    badgeCropNode.addChild(price)
                    badgeCropNode.addChild(gems1)
                    badgeCropNode.addChild(gems2)
                    badgeCropNode.addChild(gems3)
                    badgeCropNode.addChild(gems4)
                    badgeCropNode.addChild(dummy)
                    pass.setScale(1.2)
                    price.setScale(1.2)
                    cheapPass.setScale(1.2)
                    cheapPrice.setScale(1.2)
                    
                    badgeCropNode.removeFromParent()
                    statsWall.addChild(badgeCropNode)
                }else{
                    badgeCropNode.name = nil
                    badgeCropNode.removeFromParent()
                    wallIcons()
                    statsIcons[0].texture = SKTexture(imageNamed: "shop")
                }
                break
            case statsIcons[2]:
                if badgeCropNode.name != "ship"{
                    removeWallIcons()
                    statsIcons[0].texture = SKTexture(imageNamed: "shop")
                    statsIcons[1].texture = SKTexture(imageNamed: "badge")
                    statsIcons[2].texture = SKTexture(imageNamed: "statsbtn")
                    let w = 0.4 * self.size.width, h = 0.5 * self.size.height
                    badgeCropNode.position.y = h
                    badgeCropNode.position.x = -w
                    let n = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: -h), size: CGSize(width: w * 2, height: h * 2)))
                    n.fillColor = .white
                    n.lineWidth = 0
                    badgeCropNode.maskNode = n
                    badgeCropNode.removeAllChildren()
                    badgeCropNode.name = "ship"
                    
                    //DISPLAY SHIPS
                    var i = 0
                    for s in SHIPS{
                        s.removeFromParent()
                        if i < level{
                            //unlock
                            s.texture = SKTexture(imageNamed: "box")
                        }else{
                            //lock
                            s.texture = SKTexture(imageNamed: "boxlock")
                        }
                        badgeCropNode.addChild(s)
                        s.position.y = self.size.height / (i & 1 == 0 ? 4 : -4)
                        s.position.x = CGFloat(i >> 1) * 200 + 150
                        i += 1
                    }
                    
                    badgeCropNode.removeFromParent()
                    statsWall.addChild(badgeCropNode)
                }else{
                    badgeCropNode.name = nil
                    badgeCropNode.removeFromParent()
                    wallIcons()
                    statsIcons[2].texture = SKTexture(imageNamed: "ship")
                }
                break
            default:break
            }
            return
        }
        switch node{
        case addItemIcon:
            if tutorialProgress == .gemFinish{return}
            hideUpgradeUI()
            if tutorialProgress == .addItem{ nextStep(); lastSentEnergy += 150 }
            //render additem ui
            var used = [Int8](repeating: 0, count: 128)
            var lvl = 0
            for itm in planetLanded!.items{
                guard itm != nil else {continue}
                used[Int(itm!.type.rawValue)] += 1
                if itm!.type == .camp{lvl = Int(itm!.lvl)}
            }
            for i in 0...addItemIcons.count-1{
                addItemIcons[i].position = CGPoint(x: 600 + CGFloat(i) * 400, y: -220)
                addItemPrices[i].position = addItemIcons[i].position
                addItemPrices[i].position.y -= 250
                addItemPrices[i].fontSize = 60
                if Double(used[i+1]) >= Double(Double(lvl) - (items[i+1][0]["available"]?.number ?? 1.0)) / (items[i+1][0]["every"]?.number ?? 1.0) + 1.0{
                    addItemIcons[i].alpha = 0.5
                }else{
                    addItemIcons[i].alpha = 1
                    buildBG.addChild(addItemPrices[i])
                }
                buildBG.addChild(addItemIcons[i])
                
            }
            break
        case backIcon:
            if buyScreenShowing{
                colonizeBG.removeFromParent()
                showControls()
                buyScreenShowing = false
            }
            break
        case buyIcon:
            if tutorialProgress == .buyPlanet{
                nextStep()
            }
            if energyAmount >= planetLanded!.price {
                if buyScreenShowing{
                    colonizeBG.removeFromParent()
                    coloIcon.removeFromParent()
                    showControls()
                    buyScreenShowing = false
                }
                
                colonize(planetLanded!)
            }else{
                DisplayWARNING("not enough energy",.warning,false)
            }
            break
        case editColoIcon:
            if tutorialProgress == .editPlanet{ nextStep() }
            else if tutorialProgress.rawValue > 8 && tutorialProgress != .done{
                return
            }
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
            if planetLanded == nil{break}
            if collectedLabel2.text != ""{
                collectFrom(planetLanded!);planetLanded!.last=NSDate().timeIntervalSince1970
            }else{
                if energyAmount < Double(Int(10000 - planetLanded!.health*10000)){
                    DisplayWARNING("not enough energy",.warning,false)
                    break
                }
                //restore
                restore(planetLanded!)
            }
            break
        case upgradebtn:
            guard let item = planetLanded?.items[Int(itemRot)] else {break}
            let itm = items[Int(item.type.rawValue)][Int(item.lvl + 1)]
            let price = itm["price"]?.number ?? 0
            let price2 = Float(itm["price2"]?.number ?? 0)
            if energyAmount < price || researchAmount < price2{
                DisplayWARNING("not enough energy",.warning,false)
            }
            changeItem(planetLanded!, Int(itemRot))
            hideUpgradeUI()
            break
        case upgradePrice:
            if upgradePrice.fontColor == .green{
                //skip time
                guard let end = planetLanded?.items[Int(itemRot)]?.upgradeEnd else {break}
                guard end > 1 else {return}
                let price = ceil(Double(Int(end) - Int(NSDate().timeIntervalSince1970)) / 300)
                if Double(gemCount) < price{
                    DisplayWARNING("not enough gems",.warning,false)
                    break
                }
                if tutorialProgress == .gemFinish && planetLanded?.items[Int(itemRot)]?.type == .drill{ nextStep(); ship.controls = true; planetEditMode() }
                skipBuild(planetLanded!, itemRot)
            }else if upgradePrice.fontColor == .orange{
                //repair
                guard let item = planetLanded?.items[Int(itemRot)] else {break}
                let price = (items[Int(item.type.rawValue)][Int(item.lvl)]["price"]?.number ?? 0) * 1.5
                let price2 = (items[Int(item.type.rawValue)][Int(item.lvl)]["price2"]?.number ?? 0) * 1.5
                if energyAmount < price || Double(researchAmount) < price2{
                    self.DisplayWARNING("not enough energy",.warning,false)
                    break
                }
                repair(planetLanded!, itemRot)
            }
            
            break
        case coloArrow:
            if tutorialProgress == .gemFinish{return}
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
          //  cockpitIcon.texture = SKTexture(imageNamed: "cockpitOn")
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
                DisplayWARNING("Placeholder",.warning,true)
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
            if tutorialProgress == .openNavigations{
                if editColoIcon.parent != nil{
                    tutorialProgress = .buyPlanet
                }
                nextStep()
            }
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
                startLazer()
            }else{
                thrustButton.texture = SKTexture(imageNamed: "thrustOn")
                
                pauseLazer()
                ship.thrust = true
                if !playingThrustSound{
                    thrustSound.removeAllActions()
                    thrustSound.removeFromParent()
                    thrustSound.run(SKAction.changeVolume(to: 1.5, duration: 0.1))
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
            if tutorialProgress == .planetIcon{
                nextStep()
            }
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
                    startLazer()
                }
                
            }else{
                thrustButton.texture = SKTexture(imageNamed: "thrustOn")
                self.action(forKey: "constantLazer")?.speed = 0
                pauseLazer()
                ship.thrust = true
            }
            
        }
    }
    
    override func nodeUp(_ node: SKNode, at _: CGPoint) {
        if !swiping && node.parent == buildBG, var i = addItemIcons.firstIndex(of: node as? SKSpriteNode ?? ship){
            guard node.alpha == 1 else{
                DisplayWARNING("upgrade camp to build more",.warning,false)
                return
            }
            i += 1
            if tutorialProgress == .buyDrill && i != 1{ return }
            let price = items[i][1]["price"]?.number ?? 0
            let price2 = Float(items[i][1]["price2"]?.number ?? 0)
            if energyAmount < price || researchAmount < price2{
                DisplayWARNING("not enough energy",.warning,false)
                return
            }
            var pos = UInt8()
            var gap = 0
            var curGap = 0
            var start = -1
            for i in 0...255{
                if planetLanded!.items[i] == nil{
                    curGap += 1
                }else{
                    if curGap >= gap{
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
            
            if gap < Int(min(32, ceil(10 / planetLanded!.radius))) * 2 + 1{
                //yell at the user
                DisplayWARNING("create more space", .warning, true)
                return
            }
            itemRot = pos
            planetLanded!.run(.rotate(toAngle: CGFloat(pos) * PI256, duration: 0.5).ease(.easeInEaseOut))
            makeItem(planetLanded!, pos, .init(rawValue: UInt8(i))!)
            if tutorialProgress == .buyDrill{ nextStep() }
        }
        if !swiping && node.parent == badgeCropNode && badgeCropNode.name == "ship"{
            let id = badgeCropNode.children.firstIndex(of: node)! + 1
            if level < id{return}
            UserDefaults.standard.set(id, forKey: "shipid")
            ship.suit(id)
        }
        if thrustButton == node{
            thrustSound.run(SKAction.sequence([
                SKAction.changeVolume(to: 0, duration: 0.2),
                SKAction.run{
                    self.thrustSound.removeFromParent()
                    self.playingThrustSound = false
                }
            ]))
            self.playingThrustSound = false
            pauseLazer()
            ship.thrust = false
            if tutorialProgress == .thrust{ nextStep() }
            thrustButton.texture = SKTexture(imageNamed: "thrustOff")
        }
        if dPad == node{
            dPad.texture = SKTexture(imageNamed: "dPad")
            ship.thrustLeft = false
            ship.thrustRight = false
            if tutorialProgress == .dpad { nextStep() }
        }
        if dragRemainder.isInfinite{dragRemainder = 0}
        if mapIcon == node{
            mapIcon.texture = SKTexture(imageNamed: "map")
        }
        if cockpitIcon == node && statsWall.parent == nil{
            cam.addChild(statsWall)
            statsWall.position.y = self.size.height / 2
            statsWall.run(.moveTo(y: 0, duration: 0.5))
            statsWall.alpha = 0.99
            let _ = timeout(0.5){self.statsWall.alpha = 1}

            for navigations in AllNav{
                navigations.run(SKAction.fadeOut(withDuration: 0.1))
            }
        }
    }
    override func keyDown(_ key: UIKeyboardHIDUsage) {
        hideControls()
        if let b = boolfiddle, key == .keyboardComma || key == .keyboardPeriod{b.setTo(!b.value);return}
        if let b = bytefiddle{if key == .keyboardComma{b.setTo(b.value&-1);return}else if key == .keyboardPeriod{b.setTo(b.value&+1);return}else if key == .keyboardN{b.setTo(b.value&-10);return}else if key == .keyboardM{b.setTo(b.value&+10);return}}
        if let f = floatfiddle{if key == .keyboardComma{f.setTo(f.value-1);return}else if key == .keyboardPeriod{f.setTo(f.value+1);return}else if key == .keyboardN{f.setTo(f.value-10);return}else if key == .keyboardM{f.setTo(f.value+10);return}else if key == .keyboardSemicolon{f.setTo(f.value-0.1);return}else if key == .keyboardQuote{f.setTo(f.value+0.1);return}}
        boolfiddle = nil
        floatfiddle = nil
        bytefiddle = nil
        switch key{
        case .keyboardX:
            floatfiddle = reg.x
            break
        case .keyboardY:
            floatfiddle = reg.y
            break
        case .keyboardZ:
            floatfiddle = reg.z
            break
        case .keyboardS:
            floatfiddle = reg.s
            break
        case .keyboardI:
            boolfiddle = reg.i
            break
        case .keyboardO:
            floatfiddle = reg.o
            break
        case .keyboardP:
            boolfiddle = reg.p
            break
        case .keyboardOpenBracket:
            floatfiddle = reg.mx
            break
        case .keyboardCloseBracket:
            floatfiddle = reg.my
            break
        case .keyboardHyphen:
            floatfiddle = reg.sx
            break
        case .keyboardEqualSign:
            floatfiddle = reg.sy
            break
        case .keyboardR:
            bytefiddle = reg.r
            break
        case .keyboardG:
            bytefiddle = reg.g
            break
        case .keyboardB:
            bytefiddle = reg.b
            break
        case .keyboardGraveAccentAndTilde:
            let node = "<#node#" + ">"
            let label = fiddlenode as? SKLabelNode != nil
            UIPasteboard.general.string = "\(node).position = pos(mx: \(rnd(reg.mx.value)), my: \(rnd(reg.my.value))\(reg.x.value != 0 || reg.y.value != 0 ? ", x: \(rnd(reg.x.value)), y: \(rnd(reg.y.value))":""))\n\(reg.o.value < 1 ? "\(node).alpha = \(rnd(reg.o.value))\n":"")\(reg.s.value != 1 ? (label ? "\(node).fontSize = \(rnd(reg.s.value*32))\n":"\(node).setScale(\(rnd(reg.s.value)))\n"):"")\(reg.z.value != 0 ? "\(node).zPosition = \(rnd(reg.z.value))\n":"")\( reg.sx.value != 0.5 || reg.sy.value != 0.5 ? (label ? "\(reg.sx.value > 0.55 ? "\(node).horizontalAlignmentMode = .right\n" : (reg.sx.value < 0.45 ? "\(node).horizontalAlignmentMode = .left\n" : ""))\(reg.sy.value > 0.55 ? "\(node).verticalAlignmentMode = .top\n" : (reg.sy.value >= 0.45 ? "\(node).verticalAlignmentMode = .center\n" : ""))" : "\(node).anchorPoint = CGPoint(x: \(rnd(reg.sx.value)), y: \(rnd(reg.sy.value)))\n"):"")\(reg.r.value != 255 || reg.g.value != 255 || reg.b.value != 255 && (label || fiddlenode as? SKSpriteNode != nil) ? "\(node).\(label ? "fontColor" : "color") = UIColor(red: \(rnd(Double(reg.r.value) / 255)), green: \(rnd(Double(reg.g.value) / 255)), blue: \(rnd(Double(reg.b.value) / 255))\n":"")"
        case .keyboardF:
            if fiddlenode == nil{fiddlenode = SKNode();fiddlenode!.name="!"}
            else if fiddlenode!.name != "!"{fiddlenode = nil}
        default:break
        }
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
        }else if key == .keyboardDownArrow || key == .keyboardK{
            startLazer()
        }else if key == .keyboardTab{
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
        if key == .keyboardC{
            ship.encode(data: &shipStates)
        }else if key == .keyboardV{
            guard shipStates.count >= 16 else{return}
            ship.decode(data: &shipStates)
        }else if key == .keyboardBackslash{
            send(Data([127]))
            dmessage = "Disconnected :O"
            end()
            Disconnected.renderTo(skview)
        }else if key == .keyboardF3 || key == .keyboardSlash{
            if DEBUG_TXT.parent == nil{
                cam.addChild(DEBUG_TXT)
                avatar.alpha = 0.1
            }else{DEBUG_TXT.removeFromParent();avatar.alpha = 1}
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
            if tutorialProgress == .thrust{ nextStep() }
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
            if tutorialProgress == .dpad { nextStep() }
        }else if key == .keyboardLeftArrow || key == .keyboardA{
            ship.thrustLeft = false
            if tutorialProgress == .dpad { nextStep() }
        }else if key == .keyboardDownArrow || key == .keyboardS || key == .keyboardK{
            pauseLazer()
        }else if key == .keyboardL{
            self.end()
            SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
            DPlay.renderTo(skview)
            SKScene.transition = SKTransition.crossFade(withDuration: 0)
        }
    }
    override func swipe(from a: CGPoint, to b: CGPoint) {
        swiping = true
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
            var amount = round(d - dragRemainder + 0.1)
            guard amount != 0 else {return} //shortcut
            while planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] != nil{amount += sign(amount)}
            let newRot = UInt8((Int(itemRot) + Int(amount)) & 255)
            let box = UInt8(min(32, ceil(3000 / planetLanded!.radius)))
            var red = false
            var i = newRot &- box &+ 1
            while i != newRot &+ box{
                if planetLanded!.items[Int(i)] != nil && i != itemRot{ red = true }
                i &+= 1
            }
            guard let l = planetLanded!.children.first(where: {$0.userData?["rot"] as? UInt8 == itemRot}) as? SKSpriteNode else {return}
            planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] = planetLanded!.items[Int(itemRot)]
            planetLanded!.items[Int(itemRot)] = nil
            itemRot &+= UInt8(Int(amount) & 255)
            planetLanded!.run(.rotate(byAngle: amount * PI256, duration: abs(amount) / 10.0))
            l.run(.rotate(byAngle: -amount * PI256, duration: abs(amount) / 10.0))
            l.userData?["rot"] = itemRot
            if red{
                l.colorBlendFactor = 0.5
                l.color = .red
            }else{
                l.colorBlendFactor = 0
                l.color = .clear
            }
            return
        }else if addItemIcons[0].parent != nil{
            if statsWall.parent == nil || b.y < -50{
                var x = (b.x - a.x) * 2.5
                var correct = addItemIcons[0].position.x + x - 600
                if correct > 0{x -= correct}else{
                    correct = addItemIcons.last!.position.x + x - (self.size.width * 2.5 - 300)
                    if correct < 0{x -= correct}
                }
                for n in addItemIcons{
                    n.position.x += x
                }
                for n in addItemPrices{
                    n.position.x += x
                }
                return
            }
        }
        if statsWall.parent != nil && statsWall.alpha == 1 && abs(b.y-a.y) > abs(b.x-a.x){
            statsWall.removeAllActions()
            statsWall.position.y = max(statsWall.position.y + b.y - a.y, 0)
        }else if statsWall.parent != nil && statsWall.alpha == 1{
            if badgeCropNode.parent != nil && badgeCropNode.children.count > 0{
                appleSwipe = (b.x - a.x)
                var x = appleSwipe * 2
                var correct = badgeCropNode.children.first!.position.x + x - badgeCropNode.children.first!.frame.width
                if correct > 0{x -= correct}else{
                    correct = badgeCropNode.children.last!.position.x + x - (self.size.width * 0.8) + badgeCropNode.children.last!.frame.width
                    if correct < 0{x -= correct}
                }
                for node in badgeCropNode.children{
                    node.position.x += x
                }
            }
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
        if nodeToFiddle != nil{nodeToFiddle!.fiddle();nodeToFiddle = nil}
        if tutInfo.text == "done" { tutArrow.run(SKAction.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()])); tutInfo.text = ""; ship.controls = true; if hideControl{hideControl = false; showControls()} }
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
                ship.position.x = CGFloat(secx) - sector.1.pos.x
                ship.position.y = CGFloat(secy) - sector.1.pos.y
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
                guard let l = planetLanded!.children.first(where: {$0.userData?["rot"] as? UInt8 == itemRot}) as? SKSpriteNode else {return}
                if l.color == .red{
                    let amount = CGFloat(Int8(bitPattern: oldItemRot &- itemRot))
                    planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] = planetLanded!.items[Int(itemRot)]
                    planetLanded!.items[Int(itemRot)] = nil
                    itemRot &+= UInt8(Int(amount) & 255)
                    planetLanded!.run(.rotate(byAngle: amount * PI256, duration: abs(amount) / 180.0))
                    l.run(.rotate(byAngle: -amount * PI256, duration: abs(amount) / 180.0))
                    l.userData?["rot"] = itemRot
                    l.color = .clear
                    l.colorBlendFactor = 0
                }
                if coloArrow.parent == nil{cam.addChild(coloArrow)}
                changeItem(planetLanded!, Int(oldItemRot), Int(itemRot))
            }
        }
    }
    override func release(at point: CGPoint){
        if statsWall.parent != nil && statsWall.alpha == 1{
            if statsWall.position.y > size.height / 4{
                statsWall.run(SKAction.sequence([SKAction.moveTo(y: self.size.height / 2, duration: 0.5).ease(.easeOut),SKAction.removeFromParent()]))
                statsWall.alpha = 0.99
                let _ = timeout(0.5){self.statsWall.alpha = 1}
                for navigations in AllNav{
                    navigations.run(SKAction.fadeIn(withDuration: 0.1))
                }
            }else{
                statsWall.run(SKAction.moveTo(y: 0, duration: 0.5).ease(.easeOut))
                statsWall.alpha = 0.99
                let _ = timeout(0.5){self.statsWall.alpha = 1}
            }
        }
        swiping = false
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
    
    func nextStep(_ next: Bool? = true){
        if next == nil{
            if tutorialProgress == .done{return}
            if tutorialProgress.rawValue > 3{
                tutorialProgress = .followPlanet
            }
        }
        guard !animating else {return}
        animating = true
        let i = tutorialProgress.rawValue + (next != nil ? (next! ? 1 : -1) : 0)
        tutorialProgress = .init(rawValue: i)!
        if tutInfo.parent != nil{tutInfo.run(.fadeOut(withDuration: 0.2))}
        if tutArrow.parent != nil{tutArrow.run(.fadeOut(withDuration: 0.2))}
        if tutorialProgress == .done{
            let _ = timeout(0.3){ [self] in
                ship.controls = true
                tutArrow.position = .zero
                tutArrow.setScale(1)
                tutArrow.texture = SKTexture(imageNamed: "tutdone")
                tutArrow.size = tutArrow.texture!.size()
                tutArrow.setScale(0.6)
                tutArrow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                tutInfo.text = "done"
                tutArrow.removeFromParent()
                cam.addChild(tutArrow)
                tutArrow.run(.fadeIn(withDuration: 0.2))
            }
            return
        }
        tutInfo.fontSize = 25
        tutInfo.zPosition = .infinity
        tutArrow.zPosition = .infinity
        tutInfo.numberOfLines = 10
        let _ = timeout(0.3){ [self] in
            let (hori, verti, mx: mx, my: my, x: x, y: y, text) = tutorials[i]
            if hori == .center{
                tutArrow.anchorPoint = CGPoint(x: 0.5, y: 0.6)
                tutArrow.texture = SKTexture(imageNamed: "tut2")
                tutArrow.xScale = hori == .right ? -0.5 : 0.5
                tutArrow.yScale = verti == .top ? -0.5 : 0.5
            }else{
                tutArrow.texture = SKTexture(imageNamed: "tut")
                tutArrow.anchorPoint = CGPoint(x: 0.15, y: 0.3)
                tutArrow.xScale = hori == .right ? -0.5 : 0.5
                tutArrow.yScale = verti == .top ? -0.5 : 0.5
            }
            tutInfo.horizontalAlignmentMode = hori
            tutInfo.verticalAlignmentMode = verti
            tutArrow.position = pos(mx: mx, my: my, x: x, y: y)
            tutInfo.position = tutArrow.position
            tutInfo.text = text
            tutArrow.alpha = 0.8
            tutInfo.alpha = 0.8
            tutArrow.removeFromParent()
            tutInfo.removeFromParent()
            cam.addChild(tutArrow)
            cam.addChild(tutInfo)
            tutInfo.run(.fadeIn(withDuration: 0.2))
            tutArrow.run(.fadeIn(withDuration: 0.2))
            animating = false
        }
    }
}
