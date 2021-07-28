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
    var ship = Ship()
    var planets: [Planet] = []
    var cam = SKCameraNode()
    var thrust = false
    var thrustRight = false
    var thrustLeft = false
    
    let tapToStart =  SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular") // TAP TO START LABEL
    func cameraUpdate(){
        let x = ship.position.x - cam.position.x// - self.size.width / 2
        let y = ship.position.y - cam.position.y// - self.size.height / 2
        
        cam.position.x += x / 100
        cam.position.y += y / 100
        
    }
    
    func spaceUpdate(){
        return
        if thrust{
            ship.velocity.dx += -sin(ship.zRotation) / 50
            ship.velocity.dy += cos(ship.zRotation) / 50
        }
        if thrustRight{
            ship.angularVelocity -= 0.002
        }
        if thrustLeft{
            ship.angularVelocity += 0.002
        }
        ship.angularVelocity *= 0.95
        
        for planet in planets{
            planet.gravity(ship)
        }
        ship.update()
       
    }
    override func didMove(to view: SKView) {
        
        
  
        cam.position = pos(mx: 0.0, my: 0.0)
        self.addChild(cam)
        self.camera = cam
        cam.setScale(0.5)
        
        cam.run(SKAction.scale(to: 1, duration: 1).ease(.easeInEaseOut))
        //SETTING TAP TO START LABEL RELATIVE TO CAM
        self.label(node: tapToStart, "tap to start", pos: pos(mx: 0, my: -0.4), size: fmed, color: UIColor.white, font: "HalogenbyPixelSurplus-Regular", zPos: 1000, isStatic: true)
        tapToStart.alpha = 0.7
        ship.body(radius: 15, mass: 100)
        ship.position.y = 200
        let planet1 = Planet(radius: 150)
        planets.append(planet1)
        self.addChild(planet1)
        let planet2 = Planet(radius: 300, mass: 500)
        planets.append(planet2)
        self.addChild(planet2)
        planet2.position = CGPoint(x: 800, y: 300)
        self.addChild(ship)
    }
    
    func startGame(){
        self.tapToStart.run(SKAction.fadeOut(withDuration: 0.3).ease(.easeOut))
        self.tapToStart.run(SKAction.scale(by: 1.5, duration: 0.2))
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            
            if tapToStart.contains(touch.location(in: cam)){//TAP TO START HAS BEEN PRESSED
                startGame()
            }
            
            
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

print("hi")
