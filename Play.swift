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
    var gameFPS = 60.0
    var ship = Object(radius: 15, mass: 100, texture: .from(1))
    var planets: [Planet] = []
    var cam = SKCameraNode()
    var particles: [Particle] = []
    var objects: [Object] = []
    let tapToStart =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular") // TAP TO START LABEL
    var camOffset = CGPoint(x: 0, y: 0.2)
    var vel = CGFloat()
    var startPressed = false
    var started = false
    let thrustButton = SKSpriteNode(imageNamed: "thrustOff")
    let dPad = SKSpriteNode(imageNamed: "Dpad")
    
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
            if stress > 0.6{
                let ts = min((stress / 0.6 - 1) * scale, 2 - scale)
                cam.setScale(scale + ts / 50)
            }else if stress < 0.4{
                let ts = max((stress / 0.4 - 1) * scale, 0.5 - scale)
                cam.setScale(scale + ts / 50)
            }
        }
    }
    let pos = SKLabelNode()
    func spaceUpdate(){
        var a = 0
        for i in particles{
            i.update()
            if i.alpha <= 0{
                i.removeFromParent()
                particles.remove(at: a)
                a -= 1
            }
            a += 1
        }
        for planet in planets{
            for s in objects{
                planet.gravity(s)
            }
            planet.update()
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
    var hbstop = {}
    func hbstart(){
        hbstop()
        hbstop = interval(1, { [self] in
            send(Data([3]))
        })
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
        var stopAuth = {}
        send = connect("192.168.1.64:65152"){ [self](d) in
            var data = d
            let code: UInt8 = data.read()
            if code == 1{
                stopAuth()
                ready = true
                if view != nil{
                    didMove(to: view!)
                }
                sector = data.read()
                hbstart()
            }else if code == 127{
                dmessage = data.read() ?? "Disconnected!"
                Disconnected.renderTo(skview)
            }
        }
        let hello = try! messages.hello(name: "BlobKat")
        var tries = 0
        stopAuth = interval(0.5) { [self] in
            tries += 1
            if tries > 6{
                //failed
                stopAuth()
                dmessage = "Could not connect"
                Disconnected.renderTo(skview)
                return
            }
            send(hello)
        }
        self.addChild(ship)
        vibrateCamera(camera: cam)
        
        tunnel1.position = pos(mx: -0.12, my: 0)
        tunnel1.setScale(0.155)
        self.addChild(tunnel1)
        
        tunnel2.position = pos(mx: 0.12, my: 0)
        tunnel2.setScale(0.155)
        self.addChild(tunnel2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didMove(to view: SKView) {
        guard ready else{return}
        ship.run(SKAction.fadeAlpha(by: 1, duration: 1).ease(.easeOut))
        startAnimation()
        //setting tapToSrart label relative to camera (static)
        self.label(node: tapToStart, "tap to start", pos: pos(mx: 0, my: -0.4), size: fmed, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        //position indicator
        self.label(node: pos, "x: , y: , v: , b: ", pos: pos(mx: -0.5, my: -0.5, x: 20, y: 20), size: 20, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        pos.horizontalAlignmentMode = .left
        pos.verticalAlignmentMode = .top
        tapToStart.alpha = 0.7
        ship.zPosition = 5
        ship.producesParticles = true
        var step = 0
        ship.particle = { [self]() -> Particle in
            step = (step + 1) % 16
            return Particle(type: "", position: CGPoint(x: ship.position.x, y: ship.position.y - 5), velocity: CGVector(dx: 0, dy: -1), color: UIColor.cyan, size: CGSize(width: 11, height: 2), alpha: ship.alpha - 0.3, decayRate: 0.02, spin: 0, sizedif: CGVector(dx: -0.4, dy: 0), endcolor: UIColor.white).updates{ (this: Particle) in
                this.coldelta.r += 0.001
                this.decayRate = step < 8 ? 0.02 : 0.03
                this.sizedif.dx += 0.01
            }
        }
        ship.particleDelay = 1
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
        let randomPosition = random(min: -25, max: 25)
        trail.position = pos(mx: randomPosition/100 , my: 0.5)
        trail.zPosition = 2
        trail.setScale(0.2)
        trail.run(SKAction.moveBy(x: 0, y: -self.size.height - trail.size.height/2, duration: 0.2))
        let _ = timeout(0.5){
            if self.startPressed{
                trail.removeFromParent()
                self.trails.remove(at: self.trails.firstIndex(of: trail)!)
                
                if self.trails.count == 0{
                    self.started = true
                }
            }else{
                self.moveTrail(trail: trail)
            }
        }
    }
    func startGame(){
        hbstop()
        ship.producesParticles = false
        self.tapToStart.run(SKAction.fadeOut(withDuration: 0.3).ease(.easeOut))
        self.tapToStart.run(SKAction.scale(by: 1.5, duration: 0.2))
        startPressed = true
        camOffset.y = 0
        cam.run(SKAction.scale(to: 0.6, duration: 1).ease(.easeInEaseOut))
        let _ = timeout(0.5) { [self] in
            ship.controls = true
            ship.dynamic = true
            let planet1 = Planet(radius: 150, texture: .from(2))
            planet1.position.y = 400
            planet1.position.x = -50
            planet1.angularVelocity = 0.001
            planet1.zPosition = -1
            planets.append(planet1)
            self.addChild(planet1)
            let ast = Object(radius: 40, mass: 300, texture: .from(3), asteroid: true)
            self.addChild(ast)
            objects.append(ast)
            ast.position.x = 600
            ship.particle = ship.defParticle
            ship.particleDelay = 5
        }
        cam.removeAction(forKey: "vibratingCamera")
        cam.removeAction(forKey: "vibratingCameras")
        
        
        dPad.position = pos(mx: 0.35, my: -0.3)
        dPad.alpha = 0.1
        dPad.zPosition = 10
        dPad.setScale(0.45)
        cam.addChild(dPad)
        
        
        thrustButton.position = pos(mx: -0.35, my: -0.25)
        thrustButton.alpha = 1
        thrustButton.zPosition = 10
        thrustButton.setScale(0.1)
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
            print(point.x, dPad.position.x)
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
            thrustButton.texture = SKTexture(imageNamed: "thrustOff")
            ship.thrust = false
        }
        if dPad == node{
            ship.thrustLeft = false
            ship.thrustRight = false
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
        cameraUpdate()
        spaceUpdate()
    }
}
