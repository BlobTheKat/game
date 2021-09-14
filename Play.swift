//
//  Play.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//

import SpriteKit

class Play: PlayConvenience{
    var latency = 0.0
    var lastUpdate: TimeInterval? = nil
    var ship = Object(radius: 15, mass: 100, texture: .named("ship1"))
    var planets: [Planet] = []
    var planetindicators: [SKSpriteNode] = []
    var cam = SKCameraNode()
    var particles: [Particle] = []
    var objects: [Object] = []
    let tapToStart =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    let speedLabel =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
    var camOffset = CGPoint(x: 0, y: 0.2)
    var vel = CGFloat()
    var currentSpeed = Int()
    var startPressed = false
    var started = false
    var showMap = false
    var actionStopped = false
    var coolingDown = false
    var heatLevel = 0
    var usingConstantLazer = false
    var showNav = false
    let thrustButton = SKSpriteNode(imageNamed: "thrustOff")
    let heatingLaser = SKSpriteNode(imageNamed: "heating0")
    let dPad = SKSpriteNode(imageNamed: "dPad")
    
    let speedBG = SKSpriteNode(imageNamed: "speedBG")
    
    let shipDirection = SKSpriteNode(imageNamed: "direction")
    let mapBG = SKSpriteNode(imageNamed: "mapBG")
    let FakemapBG = SKSpriteNode(imageNamed: "fakeMapBG")
    let playerArrow = SKSpriteNode(imageNamed: "playerArrow")
    let star1 = SKSpriteNode(imageNamed: "stars")
    let star2 = SKSpriteNode(imageNamed: "stars")
    let star3 = SKSpriteNode(imageNamed: "stars")
    let star4 = SKSpriteNode(imageNamed: "stars")
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
    
    var a = {}
    func ping(){
        a()
        a = timeout(5, {
            self.send(Data([127]))
            dmessage = "Lost connection!"
            Disconnected.renderTo(skview)
        })
    }
    let tunnel1 = SKSpriteNode(imageNamed: "tunnel1")
    let tunnel2 = SKSpriteNode(imageNamed: "tunnel2")
    func cameraUpdate(){
        let x = ship.position.x - cam.position.x - camOffset.x * self.size.width * cam.xScale
        let y = ship.position.y - cam.position.y - camOffset.y * self.size.height * cam.yScale
        cam.position.x += x / 30
        cam.position.y += y / 30
        if started{
            let xStress = abs(x / (self.size.width * cam.xScale))
            let yStress = abs(y / (self.size.height * cam.yScale))
            let stress = xStress*2 + yStress*2

            let scale = (cam.xScale + cam.yScale) / 2
            if stress > 0.5{
                let ts = min((stress / 0.6 - 1) * scale, 8 - scale)
                cam.setScale(scale + ts / 50)
            }else if stress < 0.3{
                let ts = max((stress / 0.4 - 1) * scale, (ship.landed ? 1 : 2) - scale)
                cam.setScale(scale + ts / 50)
            }
        }
        
        
        shipDirection.zRotation = -atan2(ship.velocity.dx, ship.velocity.dy)
        let shipX = floor((ship.position.x )/2440)
        let shipY = floor((ship.position.y )/2440)
        
        
        star1.position = CGPoint(x: shipX * 2440 ,y: shipY * 2440 )
        star2.position = CGPoint(x: shipX * 2440 + 2440 ,y: shipY * 2440 )
        star3.position = CGPoint(x: shipX * 2440 ,y: shipY * 2440 + 2440 )
        star4.position = CGPoint(x: shipX * 2440 + 2440 ,y: shipY * 2440 + 2440)
        
        star1.texture!.filteringMode = .nearest
        star2.texture!.filteringMode = .nearest
        star3.texture!.filteringMode = .nearest
        star4.texture!.filteringMode = .nearest
    }
    var hits: [UInt32] = []
    func spaceUpdate(){
        if coolingDown{
            self.removeAction(forKey: "constantLazer1")
        }
        playerArrow.position = CGPoint(x: (self.ship.position.x/10), y: (self.ship.position.y/10))
        playerArrow.zRotation = ship.zRotation
        
        var a = 0
        defer{
            for particle in particles{
                if particle.update(){
                    particles.remove(at: particles.firstIndex(of: particle)!)
                    particle.removeFromParent()
                }
            }
        }
        a = 0
        for s in objects{s.landed = false}
        for planet in planets{
            for s in objects{
                if s.landed{continue}
                planet.gravity(s)
            }
            planet.update(a < planetindicators.count ? planetindicators[a] : nil)
            a += 1
        }
        a = 0
        for s in objects{
            s.update()
            if s != ship{
                let x = ship.position.x - s.position.x
                let y = ship.position.y - s.position.y
                let d = (x * x + y * y)
                let r = (ship.radius + s.radius) * (ship.radius + s.radius)
                if d < r{
                    let q = sqrt(r / d)
                    ship.position.x = s.position.x + x * q
                    ship.position.y = s.position.y + y * q
                    //self and node collided
                    //simplified elastic collision
                    let sum = ship.mass + s.mass
                    let diff = ship.mass - s.mass
                    let newvelx = (ship.velocity.dx * diff + (2 * s.mass * s.velocity.dx)) / sum
                    let newvely = (ship.velocity.dy * diff + (2 * s.mass * s.velocity.dy)) / sum
                    //s.velocity.dx = ((2 * ship.mass * ship.velocity.dx) - s.velocity.dx * diff) / sum
                    //s.velocity.dy = ((2 * ship.mass * ship.velocity.dy) - s.velocity.dy * diff) / sum
                    ship.velocity.dx = newvelx
                    ship.velocity.dy = newvely
                    hits.append(UInt32(a - 1))
                }
            }
            a += 1
        }
        let vel = CGFloat(sqrt(ship.velocity.dx*ship.velocity.dx + ship.velocity.dy*ship.velocity.dy)) * CGFloat(gameFPS)
        speedLabel.text = "\(Int(vel/2)).00"
    }
    var send = {(_: Data) -> () in}
    var ready = false
    var sector: UInt32 = 0
    var istop = {}
    func startData(){
        istop()
        istop = interval(0.1, { [self] in
            //send playerdata
            var data = Data([5])
            ship.encode(data: &data)
            if hits.count > 10{
                hits.removeLast(hits.count - 10)
            }
            data.write(UInt8(hits.count))
            for hit in hits{
                data.write(hit)
            }
            hits = []
            send(data)
        })
    }
    func startHB(){
        istop()
        istop = interval(1, { [self] in
            send(Data([3]))
        })
    }
    let physics = DispatchQueue.main
    func parseShip(_ data: inout Data, _ i: Int){
        guard i < objects.count else {
            let object = Object()
            object.decode(data: &data)
            objects.append(object)
            if object.id != 0{DispatchQueue.main.async{self.addChild(object)}}
            return
        }
        let object = objects[i]
        object.decode(data: &data)
        DispatchQueue.main.async{if object.id == 0 && object.parent != nil{object.removeFromParent()}}
        DispatchQueue.main.async{if object.id != 0 && object.parent == nil{self.addChild(object)}}
    }
    var loaded = 2
    var loadstack: (p: [Planet]?, o: [Object]?) = (p: nil, o: nil)
    func sectorid(_ s: UInt32){
        sector = s
        planets.removeAll()
        objects.removeAll()
        objects.append(ship)
        game.sector(Int(sector)) { [self] p, o in
            loadstack.p = p
            loadstack.o = o
            loaded -= 1
            if loaded == 0{didLoad()}
        }
    }
    func didLoad(){
        planets.append(contentsOf: loadstack.p!)
        objects.append(contentsOf: loadstack.o!)
        for p in loadstack.p!{
            planetindicators.append(SKSpriteNode(imageNamed: "arrow"))
            self.addChild(p)
            p.zPosition = -1
        }
        for p in planetindicators{
            p.alpha = 0
        }
        for o in loadstack.o!{
            if o.id != 0{self.addChild(o)}
        }
        ready = true
        if view != nil{
            didMove(to: view!)
        }
    }
    var delay: UInt8 = 0
    override init(size: CGSize) {
        super.init(size: size)
        api.sector(completion: sectorid)
        startAnimation()
        cam.position = CGPoint.zero
        self.addChild(cam)
        self.camera = cam
        cam.setScale(0.4)
        ship.position.y = 160
        ship.alpha = 0
        ship.id = 1
        var stopAuth = {}
        var authed = false
        send = connect{[self](d) in
            var data = d
            let code: UInt8 = data.read()
            if code == 1{
                if !authed{
                    authed = true
                    stopAuth()
                    loaded -= 1
                    if loaded == 0{didLoad()}
                    startHB()
                }
            }else if code == 127{
                dmessage = data.read() ?? "Disconnected!"
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
            }else if code == 4{
                ping()
            }else if code == 6{
                ping()
                delay = data.read()
                physics.async{ [self] in
                    var i = 1
                    while data.count > 19{parseShip(&data, i);i += 1}
                }
            }else if code == 7{
                ping()
                delay = data.read()
                physics.async { [self] in
                    var i = 0
                    while data.count > 19{parseShip(&data, i);i += 1}
                    objects.removeLast(objects.count - i - 1)
                }
            }
        }
        let hello = try! messages.hello(name: "BlobKat")
        var tries = 0
        stopAuth = interval(0.5) { [self] in
            tries += 1
            if tries > 10{
                stopAuth()
                dmessage = "Could not connect"
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
                return
            }
            send(hello)
        }
        tunnel1.position = pos(mx: -0.125, my: 0)
        tunnel1.setScale(0.155)
        self.addChild(tunnel1)
        
        tunnel2.position = pos(mx: 0.125, my: 0)
        tunnel2.setScale(0.155)
        self.addChild(tunnel2)
        self.addChild(ship)
        vibrateCamera(camera: cam)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    var moved = false

    
    override func didMove(to view: SKView) {
        
        
        guard ready else{return}
        guard !moved else {return}
        moved = true
        ship.run(SKAction.fadeAlpha(by: 1, duration: 1).ease(.easeOut))
        //setting tapToStart label relative to camera (static)
        self.label(node: tapToStart, "tap to start", pos: pos(mx: 0, my: -0.4), size: fmed, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        self.run(SKAction.repeat(SKAction.sequence([
            SKAction.run{
                if self.children.count < 70{
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
            let _ = self.interval(3){
                self.tapToStart.run(SKAction.moveBy(x: 0, y: -10, duration: 2).ease(.easeOut))
            }
        }
    }
    var trails: [SKSpriteNode] = []
    func startAnimation(){
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
    }
    func moveTrail(trail: SKSpriteNode){
        var stop = {}
        var stopped = false
        stop = interval(0.5){ [self] in
            if stopped{return}
            if startPressed{
                trail.removeFromParent()
                stop()
                stopped = true
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
    var planetsMP = [SKShapeNode]()
    var amountOfPlanets = 0
    func startGame(){
        if children.count > 70{
            self.removeAction(forKey: "loading")
            for planets in planets{
                
                
                planetsMP.append(SKShapeNode(circleOfRadius: planets.radius/10))
                planetsMP[amountOfPlanets].position = CGPoint(x: planets.position.x/10, y: planets.position.y/10)
                planetsMP[amountOfPlanets].alpha = 0
                planetsMP[amountOfPlanets].zPosition = 8
                planetsMP[amountOfPlanets].fillColor = UIColor.white
                FakemapBG.addChild(planetsMP[amountOfPlanets])
                amountOfPlanets += 1
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
            speedLabel.color = UIColor.white
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
        avatar.alpha = 1
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
        mapBG.alpha = 0
        mapBG.zPosition = 9
        mapBG.setScale(0.12)
        cam.addChild(mapBG)
            
        FakemapBG.position = pos(mx: 0, my: 0)
        FakemapBG.alpha = 1
        FakemapBG.zPosition = 9
        FakemapBG.setScale(0.1)
        cam.addChild(FakemapBG)
            
        
        playerArrow.alpha = 0
        playerArrow.zPosition = 9
        playerArrow.setScale(2)
        FakemapBG.addChild(playerArrow)
            
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
                    constantLazer()
                }
            }else{
                thrustButton.texture = SKTexture(imageNamed: "thrustOn")
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
                for map in planetsMP{
                    map.alpha = 1
                }
                playerArrow.alpha = 1
                showMap = true
                
                FakemapBG.position = CGPoint(x: -playerArrow.position.x/10 ,y: -playerArrow.position.y/10)
            }else if showMap == true{
                mapBG.alpha = 0
                for map in planetsMP{
                    map.alpha = 0
                }
                playerArrow.alpha = 0
                showMap = false
            }
        }
    }
    
    func constantLazer(){
        usingConstantLazer = true
        self.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.run(self.shootLazer),
            SKAction.wait(forDuration: 0.3)
        ])), withKey: "constantLazer1")
        
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
                    default:
                        print("error")
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
            }
        
        
        
        ]), withKey: "constantLaser")
    }
    func shootLazer(){
        
            let bullet1 = SKSpriteNode(imageNamed: "bullet")
            let bullet2 = SKSpriteNode(imageNamed: "bullet")
            
            bullet1.position = CGPoint(x: self.ship.position.x,y: self.ship.position.y)
            bullet1.zPosition = 4
            bullet1.anchorPoint = CGPoint(x: -5 , y: 0 )
            bullet1.setScale(0.2)
            bullet1.zRotation = self.ship.zRotation
            self.addChild(bullet1)
        bullet1.run(SKAction.moveBy(x: ship.velocity.dx * CGFloat(gameFPS) - sin(ship.zRotation) * 1500 , y: ship.velocity.dy * CGFloat(gameFPS) + cos(ship.zRotation) * 1500, duration: 1).ease(.easeOut))
            let _ = timeout(0.8) {
                bullet1.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0, duration: 0.2),
                    SKAction.run{ bullet1.removeFromParent()}
                ]))
                            }
            
            bullet2.position = CGPoint(x: self.ship.position.x,y: self.ship.position.y)
            bullet2.zPosition = 4
            bullet2.anchorPoint = CGPoint(x: 6 , y: 0 )
            bullet2.setScale(0.2)
            bullet2.zRotation = self.ship.zRotation
            self.addChild(bullet2)
        bullet2.run(SKAction.moveBy(x: ship.velocity.dx * CGFloat(gameFPS) - sin(ship.zRotation) * 1500 , y: ship.velocity.dy * CGFloat(gameFPS) + cos(ship.zRotation) * 1500, duration: 1).ease(.easeOut))
            let _ = timeout(0.8) {
                bullet2.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0, duration: 0.2),
                    SKAction.run{ bullet2.removeFromParent()}
                ]))
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
                thrustButton.texture = SKTexture(imageNamed: "shooting1")
                if !usingConstantLazer{
                    self.actionStopped = false
                    constantLazer()
                }
                
            }else{
                thrustButton.texture = SKTexture(imageNamed: "thrustOn")
                self.removeAction(forKey: "constantLazer")
                self.removeAction(forKey: "constantLazer1")
                self.heatLevel = 0
                self.heatingLaser.alpha = 0
                self.actionStopped = true
                self.coolingDown = false
                self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
                usingConstantLazer = false
            
            }
            
        }
    }
    override func nodeUp(_ node: SKNode, at _: CGPoint) {
        if thrustButton == node{
            thrustButton.texture = SKTexture(imageNamed: "thrustOn")
            self.removeAction(forKey: "constantLazer")
            self.removeAction(forKey: "constantLazer1")
            self.heatLevel = 0
            self.heatingLaser.alpha = 0
            self.actionStopped = true
            self.coolingDown = false
            self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
            usingConstantLazer = false
            ship.thrust = false
        }else{
            
            thrustButton.texture = SKTexture(imageNamed: "thrustOff")
            usingConstantLazer = false
            self.removeAction(forKey: "constantLazer1")
            self.removeAction(forKey: "constantLazer")
            self.heatLevel = 0
            self.actionStopped = true
            self.heatingLaser.alpha = 0
            self.coolingDown = false
            self.heatingLaser.texture = SKTexture(imageNamed: "heating0")
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
    override func update(_ currentTime: TimeInterval){
        if view == nil{return}
        //this piece of code prevents speedhack and/or performance from slowing down gametime by running update more or less times based on delay (the currentTime parameter)
        let ti = 1/gameFPS
        if lastUpdate == nil{
            lastUpdate = currentTime - ti
        }
        latency += currentTime - lastUpdate! - ti
        lastUpdate = currentTime
        if latency > ti{
            latency -= ti
            update(currentTime)
        }else if latency < -ti{
            latency += ti
            return
        }
        physics.async{
            self.cameraUpdate()
            self.spaceUpdate()
        }
    }
    override func swipe(from a: CGPoint, to b: CGPoint) {
        guard showMap else {return}
        if dPad.contains(b) || thrustButton.contains(b){return}
        FakemapBG.position.x += b.x - a.x
        FakemapBG.position.y += b.y - a.y
    }

}
