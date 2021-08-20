//
//  Deck.swift
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
    let tapToStart =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular") // TAP TO START LABEL
    var camOffset = CGPoint(x: 0, y: 0.2)
    var vel = CGFloat()
    var startPressed = false
    var started = false
    let thrustButton = SKSpriteNode(imageNamed: "thrustOff")
    let dPad = SKSpriteNode(imageNamed: "dPad")
    let avatar = SKSpriteNode(imageNamed: "avatar")
    var a = {}
    func ping(){
        a()
        a = timeout(5, {
            self.send(Data([127]))
            dmessage = "Lost connection!"
           // Disconnected.renderTo(skview)
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
                let ts = max((stress / 0.4 - 1) * scale, (ship.landed ? 0.5 : 2) - scale)
                cam.setScale(scale + ts / 50)
            }
        }
    }
    let pos = SKLabelNode()
    func spaceUpdate(){
        var a = 0
        for particle in particles{
            if particle.update(){
                particles.remove(at: particles.firstIndex(of: particle)!)
                particle.removeFromParent()
            }
        }
        a = 0
        for planet in planets{
            for s in objects{
                planet.gravity(s)
            }
            planet.update(a < planetindicators.count ? planetindicators[a] : nil)
            a += 1
        }
        a = 0
        for s in objects{
            s.update(collisionNodes: objects.suffix(from: a+1))
            a += 1
        }
        let vel = CGFloat(sqrt(ship.velocity.dx*ship.velocity.dx + ship.velocity.dy*ship.velocity.dy)) * CGFloat(gameFPS)
        pos.text = "x: \(ship.position.x.rounded() + 0), y: \(ship.position.y.rounded() + 0), v: \(vel.rounded()), b: \(Int(360-(ship.zRotation/(.pi)*180).truncatingRemainder(dividingBy: 360))%360)"
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
            send(data)
        })
    }
    func startHB(){
        istop()
        istop = interval(1, { [self] in
            send(Data([3]))
        })
    }
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
        if object.id == 0 && object.parent != nil{DispatchQueue.main.async{object.removeFromParent()}}
        if object.id != 0 && object.parent == nil{DispatchQueue.main.async{self.addChild(object)}}
    }
    override init(size: CGSize) {
        super.init(size: size)
        startAnimation()
        cam.position = CGPoint.zero
        self.addChild(cam)
        self.camera = cam
        cam.setScale(0.4)
        ship.position.y = 160
        ship.alpha = 0
        ship.id = 1
        var stopAuth = {}
        send = connect{[self](d) in
            var data = d
            let code: UInt8 = data.read()
            if code == 1{
                stopAuth()
                ready = true
                if view != nil{
                    didMove(to: view!)
                }
                sector = data.read()
                planets.removeAll()
                objects.removeAll()
                objects.append(ship)
                game.sector(Int(sector)) { p, o in
                    planets.append(contentsOf: p)
                    objects.append(contentsOf: o)
                    for p in p{
                        planetindicators.append(SKSpriteNode(imageNamed: "arrow"))
                        self.addChild(p)
                        p.zPosition = -1
                    }
                    for o in o{
                        if o.id != 0{self.addChild(o)}
                        
                        
                    }
                    
                    // place anything after its loaded 
                }
                startHB()
            }else if code == 127{
                dmessage = data.read() ?? "Disconnected!"
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
            }else if code == 4{
                ping()
            }else if code == 6{
                ping()
                var i = 1
                while data.count > 19{parseShip(&data, i);i += 1}
            }else if code == 7{
                ping()
                var i = 0
                while data.count > 19{parseShip(&data, i);i += 1}
                objects.removeLast(objects.count - i - 1)
            }
        }
        let hello = try! messages.hello(name: "BlobKat")
        var tries = 0
        stopAuth = interval(0.5) { [self] in
            tries += 1
            if tries > 6{
                stopAuth()
                dmessage = "Could not connect"
               // DispatchQueue.main.async{Disconnected.renderTo(skview)}
                return
            }
            send(hello)
        }
        tunnel1.position = pos(mx: -0.12, my: 0)
        tunnel1.setScale(0.155)
        self.addChild(tunnel1)
        
        tunnel2.position = pos(mx: 0.12, my: 0)
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
        //position indicator
        self.label(node: pos, "x: , y: , v: , b: ", pos: pos(mx: -0.5, my: -0.5, x: 20, y: 20), size: 20, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        pos.horizontalAlignmentMode = .left
        pos.verticalAlignmentMode = .top
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
        objects.append(ship)
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
    func startGame(){
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
        
        
        dPad.position = pos(mx: 0.35, my: -0.25)
        dPad.alpha = 1
        dPad.zPosition = 10
        dPad.setScale(0.2)
        cam.addChild(dPad)
        
        avatar.position = pos(mx: -0.385, my: 0.35)
        avatar.alpha = 1
        avatar.zPosition = 10
        avatar.setScale(0.085)
        cam.addChild(avatar)
        
        
        thrustButton.position = pos(mx: -0.35, my: -0.2)
        thrustButton.alpha = 1
        thrustButton.zPosition = 10
        thrustButton.setScale(0.16)
        cam.addChild(thrustButton)
        
        
        tunnel1.run(SKAction.moveBy(x: -200, y: 30, duration: 0.6).ease(.easeOut))
        tunnel1.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeOut))
        tunnel1.removeFromParent()
        tunnel2.run(SKAction.moveBy(x: 200, y: 30, duration: 0.6).ease(.easeOut))
        tunnel2.run(SKAction.fadeAlpha(to: 0, duration: 1).ease(.easeOut))
        tunnel2.removeFromParent()
    }
    override func nodeDown(_ node: SKNode, at point: CGPoint) {
        if !startPressed{
            startGame()
        }
        if thrustButton == node{
            thrustButton.texture = SKTexture(imageNamed: "thrustOn")
            ship.thrust = true
        }
        if dPad == node{
            if point.x > dPad.position.x{
                ship.thrustRight = true
                ship.thrustLeft = false
            }else{
                ship.thrustLeft = true
                ship.thrustRight = false
            }
        }
    }
    override func nodeMoved(_ node: SKNode, at point: CGPoint) {
        if dPad == node{
            if point.x > dPad.position.x{
                ship.thrustRight = true
                ship.thrustLeft = false
            }else{
                ship.thrustLeft = true
                ship.thrustRight = false
            }
        }
    }
    override func nodeUp(_ node: SKNode, at _: CGPoint) {
        if thrustButton == node{
            thrustButton.texture = SKTexture(imageNamed: "thrustOn")
            ship.thrust = false
        }else{
            
            thrustButton.texture = SKTexture(imageNamed: "thrustOff")
        }
        if dPad == node{
            ship.thrustLeft = false
            ship.thrustRight = false
            
        }
    }
    var d = Data()
    override func keyDown(_ key: UIKeyboardHIDUsage) {
        
        print(objects.map({ a in
            return a.size.width
        }))
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
        cameraUpdate()
        spaceUpdate()
    }
}
