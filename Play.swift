//
//  Deck.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//

import SpriteKit

class Play: SKScene{
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
    let tapToStart =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular") // TAP TO START LABEL
    var camOffset = CGPoint(x: 0, y: 0.2)
    var vel = CGFloat()
    
    var started = false
    func cameraUpdate(){
        let x = ship.position.x - cam.position.x - camOffset.x * self.size.width * cam.xScale
        let y = ship.position.y - cam.position.y - camOffset.y * self.size.height * cam.yScale
        cam.position.x += x / 50
        cam.position.y += y / 50
        if started{
            let tg = max(pow(vel+36,0.6)/50,0.5) - cam.xScale
            cam.xScale += tg / 50
            cam.yScale += tg / 50
        }
    }
    let pos = SKLabelNode()
    func spaceUpdate(){
        if !started{return}
        var landed = false
        for planet in planets{
            if !landed{
                landed = planet.gravity(ship)
            }
            planet.update()
        }
        ship.producesParticles = false
        if thrust{
            ship.velocity.dx += -sin(ship.zRotation) / 30
            ship.velocity.dy += cos(ship.zRotation) / 30
            ship.producesParticles = true
        }
        if thrustRight && !landed{
            ship.angularVelocity -= 0.002
        }
        if thrustLeft && !landed{
            ship.angularVelocity += 0.002
        }
        ship.angularVelocity *= 0.95
        ship.update()
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
        pos.text = "x: \(ship.position.x.rounded() + 0), y: \(ship.position.y.rounded() + 0), v: \(vel.rounded())"
    }
    override func didMove(to view: SKView) {
        cam.position = CGPoint.zero
        self.addChild(cam)
        self.camera = cam
        cam.setScale(0.4)
        //SETTING TAP TO START LABEL RELATIVE TO CAM
        self.label(node: tapToStart, "tap to start", pos: pos(mx: 0, my: -0.4), size: fmed, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        self.label(node: pos, "x: , y: ", pos: pos(mx: -0.5, my: -0.5, x: 20, y: 20), size: 20, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        pos.horizontalAlignmentMode = .left
        pos.verticalAlignmentMode = .top
        tapToStart.alpha = 0.7
        ship.zPosition = 5
        ship.position.y = 160
        self.addChild(ship)
        let _ = interval(3) {
            
            self.tapToStart.run(SKAction.moveBy(x: 0, y: 10, duration: 2).ease(.easeOut))
        }
        let _ = timeout(1.5) {
            let _ = self.interval(3){
                self.tapToStart.run(SKAction.moveBy(x: 0, y: -10, duration: 2).ease(.easeOut))
            }
        }
    }
    func startGame(){
        self.tapToStart.run(SKAction.fadeOut(withDuration: 0.3).ease(.easeOut))
        self.tapToStart.run(SKAction.scale(by: 1.5, duration: 0.2))
        started = true
        let planet1 = Planet(radius: 150, texture: SKTexture(imageNamed: "planet1"))
        planets.append(planet1)
        self.addChild(planet1)
        camOffset.y = 0
        cam.run(SKAction.scale(to: 0.6, duration: 1).ease(.easeInEaseOut))
    }
    override func nodeDown(_ node: SKNode, at _: CGPoint) {
        if node == tapToStart{
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
        //
        cameraUpdate()
        spaceUpdate()
    }
}
