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
    var gameFPS = 60.0
    var ship = Ship(radius: 15, mass: 100, texture: SKTexture(imageNamed: "spaceship"))
    var planets: [Planet] = []
    var cam = SKCameraNode()
    var thrust = false
    var thrustRight = false
    var thrustLeft = false
    var particles: [Particle] = []
    var objects: [Ship] = []
    let tapToStart =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular") // TAP TO START LABEL
    var camOffset = CGPoint(x: 0, y: 0.2)
    var vel = CGFloat()
    var startPressed = false
    var started = false
    let defaultSprite = SKSpriteNode(imageNamed: "default")
    let thrustButton = SKSpriteNode(imageNamed: "thrustOn")
    let dPad = SKSpriteNode(imageNamed: "Dpad")
    func cameraUpdate(){
        let x = ship.position.x - cam.position.x - camOffset.x * self.size.width * cam.xScale
        let y = ship.position.y - cam.position.y - camOffset.y * self.size.height * cam.yScale
        cam.position.x += x / 50
        cam.position.y += y / 50
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
        if !started{return}
        ship.landed = false
        for planet in planets{
            planet.gravity(ship)
            planet.update()
        }
        ship.producesParticles = false
        if thrust{
            ship.velocity.dx += -sin(ship.zRotation) / 30
            ship.velocity.dy += cos(ship.zRotation) / 30
            ship.producesParticles = true
        }
        if thrustRight && !ship.landed{
            ship.angularVelocity -= 0.002
        }
        if thrustLeft && !ship.landed{
            ship.angularVelocity += 0.002
        }
        var i = 0
        for s in objects{
            
            s.update(collisionNodes: objects.suffix(from: i))
            i += 1
        }
        var a = 0
        for i in particles{
            i.update()
            if i.alpha <= 0{
                i.removeFromParent()
                particles.remove(at: a)
            }
            a += 1
        }
        let vel = (CGFloat(sqrt(ship.velocity.dx*ship.velocity.dx+ship.velocity.dy*ship.velocity.dy))*CGFloat(gameFPS))
        pos.text = "x: \(ship.position.x.rounded() + 0), y: \(ship.position.y.rounded() + 0), v: \(vel.rounded()), b: \(Int(360-(ship.zRotation/(.pi)*180).truncatingRemainder(dividingBy: 360))%360)"
    }
    override func didMove(to view: SKView) {
        startAnimation()
        cam.position = CGPoint.zero
        self.addChild(cam)
        self.camera = cam
        cam.setScale(0.4)
        //setting tapToSrart label relative to camera (static)
        self.label(node: tapToStart, "tap to start", pos: pos(mx: 0, my: -0.4), size: fmed, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        //position indicator
        self.label(node: pos, "x: , y: , v: , b: ", pos: pos(mx: -0.5, my: -0.5, x: 20, y: 20), size: 20, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        pos.horizontalAlignmentMode = .left
        pos.verticalAlignmentMode = .top
        tapToStart.alpha = 0.7
        ship.zPosition = 5
        ship.position.y = 160
        self.addChild(ship)
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
        for i in 1...20{
            let trail = SKSpriteNode(imageNamed: "trail\((i%5)+1)")
            trails.append(trail)
            delay += 0.1
            let _ = timeout(delay) {
                self.moveTrail(trail: trail)
                self.vibrateObject(sprite: trail)
                self.cam.addChild(trail)
            }
        }
        vibrateCamera(camera: cam)
    }
    func moveTrail(trail: SKSpriteNode){
        let randomPosition = random(min: -50, max: 50)
        trail.position = pos(mx: randomPosition/100 , my: 0.5)
        trail.zPosition = 2
        trail.setScale(0.2)
        trail.run(SKAction.moveBy(x: 0, y: -self.size.height, duration: 0.5))
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
        self.tapToStart.run(SKAction.fadeOut(withDuration: 0.3).ease(.easeOut))
        self.tapToStart.run(SKAction.scale(by: 1.5, duration: 0.2))
        startPressed = true
        camOffset.y = 0
        cam.run(SKAction.scale(to: 0.6, duration: 1).ease(.easeInEaseOut))
        let _ = timeout(0.5) { [self] in
            let planet1 = Planet(radius: 150, texture: SKTexture(imageNamed: "planet1"))
            planet1.position.y = 400
            planet1.position.x = -50
            planet1.angularVelocity = 0.001
            planets.append(planet1)
            self.addChild(planet1)
        }
        cam.removeAction(forKey: "vibratingCamera")
        cam.removeAction(forKey: "vibratingCameras")
    }
    override func nodeDown(_ node: SKNode, at _: CGPoint) {
        if !startPressed{
            startGame()
        }
    }
    override func keyDown(_ key: UIKeyboardHIDUsage) {
        if key == .keyboardUpArrow{
            thrust = true
        }else if key == .keyboardRightArrow{
            thrustRight = true
        }else if key == .keyboardLeftArrow{
            thrustLeft = true
        }
    }
    override func keyUp(_ key: UIKeyboardHIDUsage) {
        if key == .keyboardUpArrow{
            thrust = false
        }else if key == .keyboardRightArrow{
            thrustRight = false
        }else if key == .keyboardLeftArrow{
            thrustLeft = false
        }
    }
    override func update(_ currentTime: TimeInterval){
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
