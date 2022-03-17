//
//  Story.swift
//  game
//
//  Created by Matthew on 21/01/2022.
//

import Foundation
import SpriteKit

class Story: SKScene{
    var destruction = -100
    var particles: [Particle] = []
    let PARTICLES_IN = { () -> Particle in
        let x = random(min: 120, max: 300)
        let y = random(min: -150, max: 100)
        return Particle[State(color: (r: 1, g: 0, b: 0), size: .init(width: 15, height: 15), zRot: 0, position: .init(x: x, y: y), alpha: 0.5), State(color: (r: 1, g: 0.7, b: 0), size: .init(width: 10, height: 10), zRot: 0, position: .init(x: 70, y: 40), alpha: 0.8, delay: 0.5)]
    }
    let PARTICLES_DESTROY = { (rayPos: CGPoint) -> Particle in
        let x = random(min: -100, max: 100)
        let y = random(min: -50, max: 150)
        return Particle[State(color: (r: 1, g: 1, b: 0), size: .init(width: 5, height: 5), zRot: 0, position: rayPos, alpha: 0.8), State(color: (r: 0.6, g: 0, b: 0), size: .init(width: 15, height: 15), zRot: 0, position: rayPos.add(x: x, y: y), alpha: 0.5, delay: 0.5), State(color: (r: 0.3, g: 0.3, b: 0.3), size: .init(width: 20, height: 20), zRot: 0, position: rayPos.add(x: x*1.5, y: y*1.5), alpha: 0, delay: 1)]
    }
    func PARTICLES_SMOKE() -> Particle{
        guard let point = damages.randomElement() else { return Particle() }
        return Particle[State(color: (r: 0.4, g: 0.4, b: 0.4), size: .init(width: 10, height: 10), zRot: 0, position: point, alpha: 0.5), State(color: (r: 0.4, g: 0.4, b: 0.4), size: .init(width: 7, height: 7), zRot: 0, position: point.add(x: random(min: -20, max: 20), y: 100), alpha: 0, delay: 6)]
    }
    var damages: [CGPoint] = []
    func newDamage(){
        let x = random(min: size.width / 2, max: size.width)
        let y = random(min: 0, max: size.height / 2 - planetbg.xScale * 100)
        damages.append(CGPoint(x: x, y: y))
    }
    var textLabel = SKLabelNode()
    var otherLabels: [SKLabelNode] = []
    let tapToContinue = SKLabelNode()
    let planetbg = SKSpriteNode(imageNamed: "story")
    let enemyship = SKSpriteNode(imageNamed: "storyship")
    var writing = false
    var stop = {}
    let TEXTS = [
        "humanity was at its peak\nbusiness was doing better than ever",
        "nasa had just mastered the warp drive\nallowing humans to visit nearby stars",
        "our visits were clearly not well recieved",
        "the \"pyramid of doom\" destroyed earth\nand killed the majority of its population",
        "I'm glad I had prepared\nfor this kind of situation",
        "I boarded my ship and made a rapid exit\nheaded for the unknown"
    ]
    var CB: [() -> ()] = []
    var i = -1 //which text we're at
    func nextText(){
        guard !writing else {return}
        i += 1
        if i == TEXTS.count{
            writing = true
            var i = 0
            var a = {}
            a = interval(0.1){
                //make a ship
                let p = SKSpriteNode()
                State(color: (r: 1, g: 0.5, b: 0), size: CGSize(width: 4, height: 3), zRot: 0, position: CGPoint(x: random(min: self.size.width * 0.7 - 100, max: self.size.width * 0.7 + 100), y: random(min: 100, max: 150)), alpha: 1).apply(to: p)
                p.run(.sequence([.moveBy(x: 0, y: self.size.height * 0.4 - 50, duration: 3).ease(.easeOut),.group([.moveBy(x: 600, y: 150, duration: 0.3), .fadeOut(withDuration: 0.5), .scale(to: CGSize(width: 3, height: 2), duration: 0.3)])]))
                p.zPosition = 3
                self.addChild(p)
                i += 1
                if i > 9{a()}
            }
            let _ = timeout(4.5){
                SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
                Play.renderTo(skview)
                SKScene.transition = SKTransition.crossFade(withDuration: 0)
            }
            return
        }
        for n in otherLabels{
            n.removeFromParent()
        }
        CB[i]()
        otherLabels = []
        tapToContinue.alpha -= 1
        writing = true
        var lines = TEXTS[i].split(separator: "\n")
        textLabel.text = String(lines.first!)
        var linex = textLabel.frame.width
        var liney = self.size.height - 40
        textLabel.position.y = liney
        textLabel.position.x = self.size.width - linex - 30
        textLabel.text = ""
        self.addChild(textLabel)
        var newlinecounter = 0
        stop = interval(0.04){ [self] in
            if newlinecounter > 0{newlinecounter -= 1;return}
            textLabel.text? += String(lines[0].first!)
            lines[0].removeFirst()
            if lines[0].count == 0{
                lines.removeFirst()
                otherLabels.append(textLabel)
                textLabel = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
                textLabel.position.y = liney
                textLabel.fontSize = 20
                textLabel.zPosition = 10
                textLabel.horizontalAlignmentMode = .left
                textLabel.fontColor = .init(red: 0.3, green: 0.8, blue: 0.5, alpha: 1)
                guard let first = lines.first else {
                    liney = self.size.height - 40
                    stop()
                    let _ = timeout(1){ [self] in
                        writing = false
                        tapToContinue.run(.fadeAlpha(by: 1, duration: 0.2))
                    }
                    return
                }
                textLabel.text = String(first)
                linex = textLabel.frame.width
                textLabel.position.x = self.size.width - linex - 30
                textLabel.text = ""
                self.addChild(textLabel)
                liney -= 30
                textLabel.position.y = liney
                newlinecounter = 10
            }
        }
    }
    override func didMove(to view: SKView) {
        CB = [
            {},
            {},
            enemyAppear,
            { [self] in
                //DESTROY EARTH >:D
                let ball = SKSpriteNode(imageNamed: "rayball")
                ball.alpha = -1
                enemyship.addChild(ball)
                ball.position.x = 70
                ball.position.y = 40
                ball.zPosition = 2
                var stop = {}
                stop = interval(0.03){ [self] in
                    let p = PARTICLES_IN()
                    particles.append(p)
                    enemyship.addChild(p)
                }
                let _ = timeout(1.5){ [self] in
                    //RAYTIME >:O
                    let ray = SKSpriteNode(imageNamed: "rayline")
                    ray.anchorPoint.x = 0
                    ray.xScale = 0
                    ray.position.x = 74
                    ray.position.y = 36
                    ray.zPosition = 1
                    ray.zRotation = -0.4
                    enemyship.addChild(ray)
                    var a = {}
                    var amount = 4.9995
                    var ad = -0.0001
                    var orx = CGFloat(), ory = CGFloat()
                    ray.run(.sequence([.scaleX(to: 2.5, y: 1, duration: 0.2),.wait(forDuration: 0.3),.rotate(byAngle: -0.1, duration: 3),.run{ [self] in
                        ad = 0.2
                        planetbg.position.x -= orx
                        planetbg.position.y -= ory
                        enemyship.position.x -= orx
                        enemyship.position.y -= ory
                        ball.run(.fadeOut(withDuration: 0.3))
                    },.fadeOut(withDuration: 0.3)]))
                    let _ = interval(0.1){ [self] in
                        var d = destruction
                        while d > 0{
                            let p = PARTICLES_SMOKE()
                            self.addChild(p)
                            particles.append(p)
                            d -= 100
                        }
                    }
                    planetbg.color = .orange
                    a = interval(0.04){ [self] in
                        planetbg.colorBlendFactor += 0.004
                        if amount >= 5{
                            var rayPos = ray.position
                            rayPos.y += sin(ray.zRotation) * ray.frame.width
                            rayPos.x += cos(ray.zRotation) * ray.frame.width
                            for _ in 1...5{
                                destruction += 1
                                if destruction % 60 == 0{
                                    newDamage()
                                }
                                let p = PARTICLES_DESTROY(rayPos)
                                p.zPosition = 3
                                enemyship.addChild(p)
                                particles.append(p)
                            }
                        }
                        amount -= ad
                        if amount <= 0{
                            a()
                            planetbg.run(.colorize(withColorBlendFactor: 0.3, duration: 3))
                            return
                        }
                        let rx = random(min: -amount, max: amount)
                        let ry = random(min: -amount, max: amount)
                        planetbg.position.x += rx - orx
                        planetbg.position.y += ry - ory
                        enemyship.position.x += rx - orx
                        enemyship.position.y += ry - ory
                        orx = rx
                        ory = ry
                    }
                }
                ball.run(.sequence([.fadeIn(withDuration: 1),.run{stop();self.planetbg.run(.fadeAlpha(by: -0.2, duration: 2))}]))
            },
            {},
            {}
        ]
        //label(node: textLabel, "", pos: pos(mx: 0.5, my: 0.3), size: 25, color: .init(red: 0.4, green: 0.8, blue: 0.6, alpha: 1))
        label(node: textLabel, "", pos: pos(mx: 1, my: 1, x: -50, y: -50), size: 20, color: .init(red: 0.3, green: 0.8, blue: 0.5, alpha: 1))
        textLabel.removeFromParent()
        textLabel.horizontalAlignmentMode = .left
        label(node: tapToContinue, "-tap to continue-", pos: pos(mx: 0.5, my: 0.1, y: 0), size: 18, color: .white)
        tapToContinue.alpha = 0
        pulsate(node: tapToContinue, amount: 0.6, duration: 3)
        planetbg.fitTo(self)
        self.addChild(planetbg)
        let _ = timeout(1){[self] in
            tapToContinue.alpha += 1
            nextText()
        }
        enemyship.position = pos(mx: 0.2, my: 0.6, x: 50)
        enemyship.setScale(planetbg.xScale)
        enemyship.alpha = 0
        self.addChild(enemyship)
    }
    func enemyAppear(){
        enemyship.run(.fadeIn(withDuration: 0.5))
        enemyship.run(.sequence([.moveTo(y: size.height / 2, duration: 6).ease(.easeOut),.repeatForever(.sequence([
            .moveBy(x: 0, y: 10, duration: 5).ease(.easeInEaseOut),
            .moveBy(x: 0, y: -10, duration: 5).ease(.easeInEaseOut)
        ]))]))
        
        var b = {}
        var i = 0.0
        b = interval(0.1){
            let p = SKSpriteNode()
            State(color: (r: 0.6, g: 0, b: 0.8), size: CGSize(width: 7, height: 7), zRot: 0, position: CGPoint(x: random(min: -100 - i * 10, max: 100 + i * 50), y: random(min: -200, max: -100)), alpha: 1).apply(to: p)
            p.run(.repeatForever(.sequence([.moveBy(x: 50, y: 0, duration: 10).ease(.easeInEaseOut),.moveBy(x: -50, y: 0, duration: 10).ease(.easeInEaseOut)])))
            p.zPosition = 3
            self.enemyship.addChild(p)
            i += 1
            if i > 20{b()}
        }
        var a = {}
        var count = 50
        var amount = 1.0
        var orx = CGFloat(), ory = CGFloat()
        a = interval(0.1){ [self] in
            count -= 1
            if count < 0{amount -= 0.05}
            if amount <= 0{
                planetbg.position.x -= orx
                planetbg.position.y -= ory
                enemyship.position.x -= orx
                enemyship.position.y -= ory
                return a()
            }
            let rx = random(min: -amount, max: amount)
            let ry = random(min: -amount, max: amount)
            planetbg.position.x += rx - orx
            planetbg.position.y += ry - ory
            enemyship.position.x += rx - orx
            enemyship.position.y += ry - ory
            orx = rx
            ory = ry
        }
    }
    override func touch(at _: CGPoint) {
        nextText()
    }
    override func update(_: TimeInterval){
        var i = 0
        for particle in particles{
            if particle.update(){
                particle.removeFromParent()
                particles.remove(at: particles.firstIndex(of: particle)!)
                i -= 1
            }
            i += 1
        }
    }
}
