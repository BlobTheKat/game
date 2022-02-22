//
//  Play.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//

import SpriteKit
import GameKit
import GoogleMobileAds
var waitForSound = Int()

let stopSound = SKAction.stop()
let playSound = SKAction.play()

var currentPlanetTexture = SKTexture()



extension Play{
    func playAd(_ done: @escaping () -> () = {}){
        adstop()
        adstop = timeout((ad?.adMetadata?[.init(rawValue: "CreativeDurationMs")] as? Double ?? 15000) / 1000 + 1){ [self] in
            //if ad is fullscreen then reward
            //Make sure canPresent throws error (i.e it cant be displayed because it is already being displayed)
            guard (try? ad?.canPresent(fromRootViewController: controller)) == nil else { return }
            //If it's being displayed that means they didnt skip it
            //If they skipped and rewatched, this timeout would be cancelled, so we know they definitely did watch it
            done()
        }
        ad?.present(fromRootViewController: controller, userDidEarnRewardHandler: {})
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: "ca-app-pub-5065501786618884/1136924485", request: request, completionHandler: { ad, error in
            self.ad = ad
            if let error = error{print(error.localizedDescription)}
        })
    }
    
    func construct() {
        debugToggle.position = pos(mx: -0.5, my: 0.5, x: 15, y: -40)
        debugToggle.lineWidth = 0
        debugToggle.fillColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.1)
        cam.addChild(debugToggle)
        debugToggle.zPosition = .infinity
        if !movemode{
            let x = UserDefaults.standard.integer(forKey: "sx")
            let y = UserDefaults.standard.integer(forKey: "sy")
            if x != 0{secx = x; ssecx = x}
            if y != 0{secy = y; ssecy = y}
        }
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
        
        
        //cam.addChild(loadingbg)
        loadingbg.lineWidth = 0
        loadingbg.position.y = -0.35 * self.size.height
        loadingbg.fillColor = .gray
        
        //cam.addChild(loading)
        loading.lineWidth = 0
        loading.position.y = -0.35 * self.size.height
        loading.fillColor = .white
        loading.zPosition = 1
        loading.xScale = 0
        loading.position.x = -150
        
        cam.position = CGPoint.zero
        self.addChild(cam)
        self.camera = cam
        cam.setScale(movemode ? 2 : 0.4)
        ship.alpha = 0
        let id = UserDefaults.standard.integer(forKey: "shipid")
        ship.suit(id > 0 ? id : 1)
        tunnel1.anchorPoint = CGPoint(x: 0, y: 0.5)
        tunnel1.position = pos(mx: -0.5, my: 0, x: -5)
        tunnel1.setScale(0.4)
        if !movemode{cam.addChild(tunnel1)}
        tunnel2.anchorPoint = CGPoint(x: 1, y: 0.5)
        tunnel2.position = pos(mx: 0.5, my: 0, x: 5)
        tunnel2.setScale(0.4)
        if !movemode{cam.addChild(tunnel2)}
        ship.death = 300
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
        //cam.addChild(accountIcon)
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
            return Particle[State(color: (r: 0.1, g: 0.7, b: 0.7), size: CGSize(width: 11, height: 2), zRot: 0, position: ship.position.add(x: ship.particleOffset, y: -5), alpha: i), State(color: (r: 1, g: 1, b: 1), size: CGSize(width: 5, height: 2), zRot: 0, position: ship.position.add(x: ship.particleOffset, y: -35), alpha: 0, delay: TimeInterval(i))]
        }
        ship.particleFrequency = 1
        self.label(node: tapToStart, movemode ? "   " : "loading sector   ", pos: pos(mx: 0, my: -0.3, x: movemode ? -20 : -153), size: 48, color: .white, font: "HalogenbyPixelSurplus-Regular", zPos: 999, isStatic: true)
        tapToStart.horizontalAlignmentMode = .left
        tapToStart.alpha = 0.7
        ship.zPosition = 7
        tapToStart.run(.repeatForever(.sequence([
            .wait(forDuration: 0.5),
            .run{
                self.tapToStart.text = movemode ? ".  " : "loading sector.  "
            },
            .wait(forDuration: 0.5),
            .run{
                self.tapToStart.text = movemode ? ".. " : "loading sector.. "
            },
            .wait(forDuration: 0.5),
            .run{
                self.tapToStart.text = movemode ? "..." : "loading sector..."
            },
            .wait(forDuration: 0.5),
            .run{
                self.tapToStart.text = movemode ? "   " : "loading sector   "
            }
        ])), withKey: "dotdotdot")
        
        if !movemode{self.addChild(inlightSpeed)}
        DEBUG_TXT.fontSize = 15
        DEBUG_TXT.position = pos(mx: -0.5, my: 0.5, x: 20, y: -20)
        DEBUG_TXT.color = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        DEBUG_TXT.fontColor = .white
        DEBUG_TXT.horizontalAlignmentMode = .left
        DEBUG_TXT.verticalAlignmentMode = .top
        DEBUG_TXT.numberOfLines = 20
        DEBUG_TXT.zPosition = .infinity
        //cam.addChild(DEBUG_TXT)
        avatar.alpha = 0.2
        api.position(completion: sectorpos)
        
        discord.anchorPoint = CGPoint.zero
        discord.position = pos(mx: -0.5, my: -0.5, x: 20, y: 20)
        discord.zPosition = 20
        discord.setScale(0.6)
        if !movemode{cam.addChild(discord)}
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
        border1.alpha = 0.5
        border2.alpha = 0.5
        self.addChild(border1)
        self.addChild(border2)
        
        addItemIcon.position = pos(mx: 0.5, my: 0, x: -170, y: 50)
        addItemIcon.size = CGSize(width: 50, height: 50)
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
        let _ = interval(3){
            self.tapToStart.run(SKAction.moveBy(x: 0, y: 10, duration: 2).ease(.easeOut))
        }
        let _ = timeout(1.5){
            let _ = interval(3){
                self.tapToStart.run(SKAction.moveBy(x: 0, y: -10, duration: 2).ease(.easeOut))
            }
        }
        avatar.alpha = 1
        if movemode{
            accountIcon.removeFromParent()
            discord.removeFromParent()
            removeTapToStart()
            ship.position.x = CGFloat(secx) - sector.1.pos.x
            ship.position.y = CGFloat(secy) - sector.1.pos.y
            /*var movex = CGFloat(), movey = CGFloat()
            if ship.position.x > sector.1.size.width / 2 - 1001{ ship.position.x += 500; movex -= 500 }
            if ship.position.x < sector.1.size.width / -2 + 1001{ ship.position.x -= 500; movex += 500 }
            if ship.position.y > sector.1.size.height / 2 - 1001{ ship.position.y += 500; movey -= 500 }
            if ship.position.y < sector.1.size.height / -2 + 1001{ ship.position.y -= 500; movey += 500 }
            ship.run(.moveBy(x: movex, y: movey, duration: 2).ease(.easeOut))*/
            ship.velocity = velo
            ship.zRotation = zrot
            playedLightSpeedOut = true
            ship.run(.scale(to: 0.25, duration: 0.5))
            removeAction(forKey: "inLightSpeed")
            inlightSpeed.removeFromParent()
            startGame()
            started = true
            movemode = false
        }
    }
    func startAnimation(){
        if animated{return}
        animated = true
        if movemode{return}
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
        
        playAd()
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
            a.fillColor = planet.ownedState == .yours ? UIColor(red: 0, green: 0.5, blue: 1, alpha: 1) : (planet.superhot ? .orange : .white)
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
    
    var upgradeStats: (price: String, time: String, powers: [(name: String, old: Double, new: Double, max: Double)], canGet: Bool)?{
        guard let item = planetLanded?.items[Int(itemRot)] else {return nil}
        let id = Int(item.type.rawValue)
        var lvl = 0
        for itm in planetLanded!.items{if itm?.type == .camp{lvl = Int(itm!.lvl);break}}
        let dat = items[Int(item.type.rawValue)][0]
        if Double(item.lvl) >= Double(Double(lvl) - (dat["available"]?.number ?? 1.0)) + 1.0{return nil}
        if item.upgradeEnd > 0 || items[id].count < item.lvl + 2{return nil}
        let old = items[id][Int(item.lvl)]
        let new = items[id][Int(item.lvl)+1]
        let max = items[id].count > item.lvl + 2 ? items[id][Int(item.lvl)+2] : new
        var pw = [(name: String, old: Double, new: Double, max: Double)]()
        for (k, v) in new{
            if k[0] == "_" || k == "price" || k == "price2" || k == "time"{continue}
            pw.append((name: k, old: old[k]?.number ?? 0, new: v.number!, max: (max[k] ?? v).number!))
        }
        return (price: formatPrice(new), time: formatTime(Int(new["time"]!.number!)), powers: pw.sorted(by: {(a,b) in a.name.count < b.name.count}), canGet: new["price"]?.number ?? 0 <= energyAmount && Float(new["price2"]?.number ?? 0) <= researchAmount)
    }
    func refreshXp(){
        stats.levelLabel.text = "level \(level)"
        stats.xpFill.xScale = 0.0737 * Double(xp) / Double(level)
        stats.xpLabel.text = "\(xp)xp"
        var i = 0
        for s in SHIPS{ if i * 2 + 1 <= level { s.texture = SKTexture(imageNamed: "box") } else { break }; i += 1 }
        i = 0
        for b in BADGES{ if i * 2 <= level { b.texture = SKTexture(imageNamed: "box") } else { break }; i += 1 }
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
        speedLabel.fontSize = 60
        speedLabel.zRotation = 0.165
        speedLabel.horizontalAlignmentMode = .left
        speedLabel.verticalAlignmentMode = .center
        speedLabel.position = CGPoint(x: -speedBG.size.width/2.7 ,y: -50)
        speedLabel.xScale = 1.3
        
        speedBG.addChild(speedLabel)
        dPad.position = pos(mx: 0.4, my: -0.4, x: -50, y: 50)
        dPad.zPosition = 10
        dPad.setScale(1.5)
        cam.addChild(dPad)
        avatar.anchorPoint.x = 0
        avatar.position = pos(mx: -0.5, my: 0.35, x: 50)
        avatar.alpha = 1
        avatar.zPosition = 10
        avatar.setScale(0.25)
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
        energyCount.text = ""
        energyCount.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        energyCount.zPosition = avatar.zPosition + 1
        energyCount.position = CGPoint(x: 165, y: -102)
        energyCount.fontSize = 40
        avatar.addChild(energyCount)
        researchCount.text = ""
        researchCount.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        researchCount.zPosition = avatar.zPosition + 1
        researchCount.position = CGPoint(x: 270, y: 71)
        researchCount.fontSize = 40
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
            statsLabel2[i].horizontalAlignmentMode = .left
            if i > 0{
                statsLabel2[i].position = CGPoint(x: statsLabel2[i - 1].position.x ,y: statsLabel2[i - 1].position.y + 60)
            }else{
                statsLabel2[i].position = CGPoint(x: statsLabel[i].position.x + 200, y: statsLabel[i].position.y)
            }
            statsWall.addChild(statsLabel2[i])
        }
        statsLabel[0].text = "kills:"
        statsLabel[1].text = "deaths:"
        statsLabel[2].text = "kdr:"
        statsLabel[3].text = "planets:"
        statsLabel[4].text = "travel:"
        
        statsLabel2[0].text = "..."
        statsLabel2[1].text = "..."
        statsLabel2[2].text = "..."
        statsLabel2[3].text = "..."
        statsLabel2[4].text = "..."
        
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
        navArrow.zPosition = 10
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
        //navBG.addChild(repairIcon)
        
        lightSpeedIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: repairIcon.position.y + (repairIcon.size.height * 1.2) )
        lightSpeedIcon.alpha = 1
        lightSpeedIcon.zPosition = 11
        lightSpeedIcon.setScale(1.1)
        //navBG.addChild(lightSpeedIcon)
        
        removeTrackerIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: mapIcon.position.y + (mapIcon.size.height * 1.2))
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
        
        coloIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: repairIcon.position.y + (repairIcon.size.height * 1.2) )
        coloIcon.zPosition = 11
        coloIcon.setScale(0.9)
        
        //COLONIZE LABELS
        
        coloStatsName.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coloStatsName.position = colonizeBG.pos(mx: 0, my: 0, x: -230, y: -240)
        coloStatsName.fontSize = 20
        coloStatsName.text = "Name: Big Ed"
        //colonizeBG.addChild(coloStatsName)
        
        coloStatsStatus.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coloStatsStatus.position = colonizeBG.pos(mx: 0, my: 0, x: -230, y: -270)
        coloStatsStatus.fontSize = 20
        coloStatsStatus.text = "status: unowned"
        colonizeBG.addChild(coloStatsStatus)
        
        coloStatsRecource.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coloStatsRecource.position = colonizeBG.pos(mx: 0, my: 0, x: -230, y: -300)
        coloStatsRecource.fontSize = 20
        coloStatsRecource.text = "resource: Blackstone"
        //colonizeBG.addChild(coloStatsRecource)
        
        coloStatsPrice.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coloStatsPrice.position = colonizeBG.pos(mx: 0, my: 0, x: -230, y: -330)
        coloStatsPrice.fontSize = 20
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
        
        
       
        
        editColoIcon.position = CGPoint(x: -navBG.size.width/1.2 ,y: repairIcon.position.y + (repairIcon.size.height * 1.2) )
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
        warning.setScale(2.4)
        healthBar.addChild(warning)
            
            
            
        mapBG.position = pos(mx: 0, my: 0)
        mapBG.zPosition = 9
        mapBG.setScale(0.2)
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
        healthBar.zPosition = 100
        healthBar.setScale(0.12)
        cam.addChild(healthBar)
            
            
        speedBG.position = CGPoint(x: healthBar.size.width * 2.1, y: -healthBar.size.height * 3)
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
        if cam.action(forKey: "warningAlpha") != nil{
            cam.removeAction(forKey: "warningAlpha")
            warning.alpha = 0
        }
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
        warningLabel.verticalAlignmentMode = .center
        warningLabel.position.x = -20
        warningLabel.fontSize = 60
        warningLabel.setScale(0.8)
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
        for icon in addItemNames{
            icon.removeFromParent()
        }
        upgradeTime.removeFromParent()
        upgradePrice.removeFromParent()
        upgradeName.removeFromParent()
        upgradeArrow.removeFromParent()
        upgradeOld.removeFromParent()
        upgradeNew.removeFromParent()
        upgradeOld2.removeFromParent()
        upgradeNew2.removeFromParent()
        upgradebtn.removeFromParent()
        upgradeNodes = []
        upgradingHintInterval()
        upgradingHintInterval = {}
        
        addItemIcon.texture = SKTexture(imageNamed: "addicon")
    }
    //This function renders the upgrading UI
    
    func renderUpgradeUI(){
        //remove upgrade nodes, and replace them with addItemIcons
        hideUpgradeUI()
        guard let (type: id, lvl: lvl, capacity: _, upgradeEnd: u) = planetLanded!.items[Int(itemRot)] else {return}
        guard let (price: price, time: time, powers: powers, canGet: canGet) = upgradeStats else {
            upgradePrice.fontColor = .white
            if u > 1{
                var time = Int(u) - Int(NSDate().timeIntervalSince1970)
                upgradeTime.text = "Time: \(formatTime(time))"
                upgradeTime.fontSize = 120
                buildBG.addChild(upgradeTime)
                upgradeTime.position = pos(mx: 1.5, my: -0.5)
                upgradeTime.horizontalAlignmentMode = .center
                upgradePrice.fontSize = 80
                buildBG.addChild(upgradePrice)
                upgradePrice.position = pos(mx: 1.5, my: -0.8, y: -30)
                upgradePrice.horizontalAlignmentMode = .center
                upgradePrice.zPosition = 3
                upgradeOld = SKSpriteNode(imageNamed: "finishnow")
                upgradeOld.position = pos(mx: 1.5, my: -0.8)
                buildBG.addChild(upgradeOld)
                upgradePrice.text = "Finish now (\(formatNum(ceil(Double(time) / 300))) gems)"
                upgradePrice.color = .green
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
                upgradePrice.position = pos(mx: 1.5, my: -0.8, y: -30)
                upgradePrice.horizontalAlignmentMode = .center
                upgradePrice.zPosition = 3
                upgradeOld = SKSpriteNode(imageNamed: "repair")
                upgradeOld.position = pos(mx: 1.5, my: -0.8)
                buildBG.addChild(upgradeOld)
                upgradePrice.text = "repair (\(formatPrice(items[Int(id.rawValue)][Int(lvl)], 1.5)))"
                upgradePrice.color = .orange
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
                upgradePrice.text = id == .camp ? "More levels coming soon! (maybe)" : "Upgrade main camp to unlock more levels"
                upgradePrice.color = .white
            }
            return
        }
        var required = 0
        if id == .camp{
            var used = [Int8](repeating: 0, count: 128)
            var lvl = 0
            for itm in planetLanded!.items{
                guard itm != nil else {continue}
                used[Int(itm!.type.rawValue)] += 1
                if itm!.type == .camp{lvl = Int(itm!.lvl)}
            }
            for i in 0...addItemIcons.count-1{
                if Double(used[i+1]) <= Double(Double(lvl) - (items[i+1][0]["available"]?.number ?? 1.0)) / (items[i+1][0]["every"]?.number ?? 1.0){
                    required = i + 1
                }
            }
        }
        upgradePrice.fontColor = canGet ? .white : UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)
        upgradePrice.color = .white
        upgradeTime.text = "Time: \(time)"
        upgradePrice.text = "Price: \(price)"
        upgradeTime.position = pos(mx: 0.7, my: -0.9)
        upgradeTime.horizontalAlignmentMode = .right
        upgradeTime.fontSize = 60
        buildBG.addChild(upgradeTime)
        upgradePrice.position = pos(mx: 0.8, my: -0.9)
        upgradePrice.horizontalAlignmentMode = .left
        upgradePrice.fontSize = 60
        buildBG.addChild(upgradePrice)
        upgradeOld = SKSpriteNode(imageNamed: "\(coloNames[Int(id.rawValue)])\(lvl)")
        upgradeNew = SKSpriteNode(imageNamed: "\(coloNames[Int(id.rawValue)])\(lvl+1)")
        upgradeOld.position = pos(mx: 0.6, my: -0.36)
        upgradeNew.position = pos(mx: 1.3, my: -0.36)
        upgradeOld2.position = pos(mx: 0.6, my: -0.67)
        upgradeNew2.position = pos(mx: 1.3, my: -0.67)
        upgradeName.position = pos(mx: 0.95, my: -0.2)
        upgradeName.text = coloDisplayNames[Int(id.rawValue)]
        let avg = upgradeOld.size.height + upgradeNew.size.height
        upgradeOld.setScale(300 / avg)
        upgradeNew.setScale(300 / avg)
        upgradeOld2.fontSize = 40
        upgradeNew2.fontSize = 40
        upgradeName.fontSize = 60
        upgradeOld2.text = "Level \(lvl)"
        upgradeNew2.text = "Level \(lvl+1)"
        upgradeArrow.position = pos(mx: 0.95, my: -0.45)
        upgradeArrow.setScale(0.3)
        upgradebtn.alpha = canGet ? 1 : 0.5
        upgradebtn.position = pos(mx: 0.95, my: -1.07)
        upgradebtn.setScale(0.7)
        buildBG.addChild(upgradeArrow)
        buildBG.addChild(upgradeOld)
        buildBG.addChild(upgradeNew)
        buildBG.addChild(upgradeOld2)
        buildBG.addChild(upgradeNew2)
        buildBG.addChild(upgradebtn)
        buildBG.addChild(upgradeName)
        var i = 0
        var oldOutlineY = -125.0
        for (name: name, old: old, new: new, max: max) in powers{
            if name == "unlocksitem" && required == 0{
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
            }else if name == "unlocksitem"{continue}
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
        if required > 0{
            upgradebtn.removeFromParent()
            let unlockslabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            let unlocksIcon = SKSpriteNode(imageNamed: coloNames[Int(required)]+"1")
            unlockslabel.text = "Required buildings:"
            unlockslabel.fontSize = 60
            unlockslabel.position = pos(mx: 2.5, my: 0, x: -300, y: oldOutlineY + 30)
            unlocksIcon.position = pos(mx: 2.5, my: 0, x: -300, y: oldOutlineY - 110)
            unlocksIcon.setScale(200 / unlocksIcon.size.height)
            upgradeNodes.append(unlockslabel)
            upgradeNodes.append(unlocksIcon)
            buildBG.addChild(unlockslabel)
            buildBG.addChild(unlocksIcon)
            oldOutlineY -= 400
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
        
        usingConstantLazer = true
        heatingLaser.alpha = 1
        stopInterval()
        if heatLevel <= 40{
            usedShoot = true
            heatLevel += 3
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
            for a in planetLanded!.items{if a?.type == .drill{
                tutorialProgress = .finishEditing
                if !showNav{
                    navArrow.run(SKAction.move(to: pos(mx: 0.43, my: 0 ), duration: 0.35).ease(.easeOut))
                    navArrow.run(SKAction.rotate(toAngle: 3.18, duration: 0.35).ease(.easeOut))
                    navBG.run(SKAction.move(to: pos(mx: 0.43, my: 0 ), duration: 0.35).ease(.easeOut))
                    showNav = true
                }
                ship.controls = true
            }}
            nextStep()
            
        }else if tutorialProgress == .followPlanet{
            tutInfo.text = "this planet is\nalready owned"
            tutInfo.fontColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)
        }
        vibratePhone(.light)
        coloStatsPrice.text = "price: \(formatNum(pow(100, Double(planetsOwned + 1)))) energy"
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
        DisplayWARNING("colonized successfuly", .achieved,false)
    }
    
    func planetEditMode(){
        
        presence = !presence
        
        buildBG.anchorPoint = CGPoint(x: 0, y: 1)
        buildBG.position = pos(mx: -0.5, my: 0, x: -50, y: 0)
        buildBG.alpha = 1
        buildBG.zPosition = 1000
        buildBG.setScale(0.4)
        coloArrow.anchorPoint = CGPoint(x: 0.5,y: 0)
        coloArrow.position = pos(mx: 0, my: 0.05, x: 0, y: 0)
        coloArrow.alpha = 1
        coloArrow.zPosition = 100
        coloArrow.setScale(0.15)
        if presence{
            cam.addChild(buildBG)
            cam.addChild(coloArrow)
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
            addItemIcon.removeFromParent()
            for n in planetLanded!.children{
                let itm = (n.userData?["type"] as? ColonizeItem)
                if n.name == nil && itm?.type == .satellite && itm?.upgradeEnd ?? 0 < 2{
                    n.run(.repeatForever(SKAction.rotate(byAngle: planetLanded!.angularVelocity + 0.05, duration: 1)))
                    (n as? SKSpriteNode)?.anchorPoint.y -= 2
                }
            }
            if planetTouched == nil{planetLanded = nil}
            hideUpgradeUI()
        }
        hideControl.toggle()
        if hideControl{
            hideControls()
        }else{
            showControls()
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
        guard badgeCropNode.name == nil else {return}
        let mustard = UIColor(red: 1, green: 0.7, blue: 0, alpha: 1)
        stats.levelbg.position.y = self.size.height * 0.95 - 20
        stats.levelLabel.text = "level \(level)"
        stats.levelLabel.fontColor = mustard
        stats.levelLabel.position.y = self.size.height * 0.95 - 40
        stats.levelLabel.fontSize = 40
        stats.xpBox.position.y = self.size.height * 0.75
        stats.xpBox.setScale(0.5)
        stats.xpLabel.text = "\(xp)xp"
        stats.xpLabel.position = pos(mx: 0, my: 0.75, x: -218, y: -12)
        stats.xpLabel.horizontalAlignmentMode = .left
        stats.xpLabel.zPosition = 2
        stats.xpLabel.fontSize = 30
        stats.xpFill.anchorPoint.x = 0
        stats.xpFill.position = pos(mx: 0, my: 0.75, x: -220, y: 0)
        stats.xpFill.setScale(0.5)
        stats.missionTitle.position.y = self.size.height * 0.75 - 75
        stats.missionTitle.text = "Missions:"
        stats.missionTitle.fontSize = 40
        stats.missionTitle.fontColor = .blue
        stats.rewards.position = pos(mx: 0.4, my: 0.45, x: -218.0, y: 20)
        stats.rewards.horizontalAlignmentMode = .left
        stats.rewards.text = "rewards:"
        stats.rewards.fontSize = 28
        statsWall.addChild(stats.xpBox)
        statsWall.addChild(stats.levelbg)
        statsWall.addChild(stats.levelLabel)
        statsWall.addChild(stats.xpLabel)
        statsWall.addChild(stats.xpFill)
        statsWall.addChild(stats.missionTitle)
        statsWall.addChild(stats.rewards)
        stats.missions = []
        for i in 0...2{
            guard i < missions.count else {continue}
            let box = SKSpriteNode(imageNamed: "progressOutline")
            let fill = SKSpriteNode(imageNamed: "progressgreen")
            let text = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            let rewardsbox = SKSpriteNode(imageNamed: "rewards")
            let xpReward = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            let gemReward = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            rewardsbox.position = pos(mx: 0.4, my: 0.45, x: -10.0, y: CGFloat(i * -60) + 2)
            rewardsbox.setScale(1.3)
            rewardsbox.anchorPoint = CGPoint(x: 1.0, y: 0.5)
            xpReward.text = "\(Int(missions[i].xp))"
            xpReward.position = pos(mx: 0.4, my: 0.45, x: -218.0, y: CGFloat(i * -60))
            xpReward.fontSize = 28
            xpReward.horizontalAlignmentMode = .left
            xpReward.verticalAlignmentMode = .center
            xpReward.fontColor = mustard

            gemReward.text = "\(Int(missions[i].gems))"
            gemReward.position = pos(mx: 0.4, my: 0.45, x: -70.0, y: CGFloat(i * -60))
            gemReward.fontSize = 28.8
            gemReward.fontColor = .green
            gemReward.verticalAlignmentMode = .center
            
            fill.position = pos(mx: -0.4, my: 0.45, x: 22.0, y: CGFloat(i * -60))
            fill.anchorPoint.x = 0
            fill.setScale(0.4)
            fill.xScale = (missions[i].val / missions[i].max) * 5.9
            box.position = pos(mx: -0.4, my: 0.45, x: 20.0, y: CGFloat(i * -60))
            box.setScale(0.4)
            box.anchorPoint.x = 0
            let label = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
            label.text = "\(missions[i].name)"
            label.position = pos(mx: -0.4, my: 0.45, x: 18.0, y: 20.0 + CGFloat(i * -60))
            label.fontSize = 25
            label.horizontalAlignmentMode = .left
            label.zPosition = 2
            let intval = Int(missions[i].val)
            text.text = "\(CGFloat(intval) == missions[i].val ? "\(intval)" : String(format: "%.2f", missions[i].val)) / \(Int(missions[i].max))"
            text.position = pos(mx: -0.4, my: 0.45, x: 22.0, y: CGFloat(i * -60))
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
        stats.missionTitle.removeFromParent()
        stats.rewards.removeFromParent()
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
    
    func missionCompleteNotification(missionTxt: String, gems: Int){
        
        let missionLabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
        
        if missionLabel.parent == nil{
        missionLabel.position = pos(mx: 0, my: 0.5, x: 0, y: 0)
        missionLabel.zPosition = 100000
        missionLabel.alpha = 0
        missionLabel.fontSize = 20
        missionLabel.fontColor = .green
        missionLabel.text = "\(missionTxt):   +\(gems)"
        cam.addChild(missionLabel)
        
        missionLabel.run(SKAction.fadeIn(withDuration: 0.5))
        missionLabel.run(SKAction.sequence([
        
            SKAction.moveBy(x: 0, y: -60, duration: 0.4).ease(.easeOut),
            SKAction.wait(forDuration: 3),
            SKAction.fadeOut(withDuration: 1.5),
            SKAction.run {
                missionLabel.removeFromParent()
            }
        ]))
        }
    }
}
