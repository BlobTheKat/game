//
//  Story.swift
//  game
//
//  Created by Matthew on 21/01/2022.
//

import Foundation
import SpriteKit

class Story: SKScene{
    var textLabel = SKLabelNode()
    var otherLabels: [SKLabelNode] = []
    let tapToContinue = SKLabelNode()
    let planetbg = SKSpriteNode(imageNamed: "story")
    let enemyship = SKSpriteNode(imageNamed: "storyship")
    var writing = false
    var stop = {}
    let TEXTS = [
        "humanity was at its peak, business was expanding",
        "NASA had just mastered the warp drive\nallowing humans to visit nearby stars",
        "and that's when some aliens\ntook that as a threat",
        "the \"pyramid of doom\" annihilated earth and the majority of its population",
        "I'm glad I had prepared for this kind of situation",
        "I boarded my ship and made a rapid exit, headed for the unknown"
        
        //2037 was the best but also the worst year ever
        //I had everything i needed to be happy... Everyone did...
        //When overnight and for no particular reason...
        //We got attacked, and all my dreams were
        //I just had time to escape with my life... and my ship
        //But now i'm all alone... with only one desire... REVENGE
        //the thing is... where do I start?
    ]
    var CB: [() -> ()] = []
    var i = -1 //which text we're at
    func nextText(){
        guard !writing else {return}
        i += 1
        if i == TEXTS.count{
            SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
            Play.renderTo(skview)
            SKScene.transition = SKTransition.crossFade(withDuration: 0)
            return
        }
        for n in otherLabels{
            n.removeFromParent()
        }
        CB[i]()
        otherLabels = []
        tapToContinue.alpha = 0
        writing = true
        var lines = TEXTS[i].split(separator: "\n")
        textLabel.text = String(lines.first!)
        var linex = textLabel.frame.width / -2
        var liney = self.size.height * 0.62
        textLabel.position.y = liney
        textLabel.position.x = self.size.width / 2 + linex
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
                textLabel.fontSize = 25
                textLabel.zPosition = 10
                textLabel.horizontalAlignmentMode = .left
                guard let first = lines.first else {
                    liney = self.size.height * 0.62
                    writing = false
                    stop()
                    tapToContinue.run(.fadeIn(withDuration: 0.2))
                    return
                }
                textLabel.text = String(first)
                linex = textLabel.frame.width / -2
                textLabel.position.x = self.size.width / 2 + linex
                textLabel.text = ""
                self.addChild(textLabel)
                liney -= 36
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
            {},
            {},
            {}
        ]
        
        
        label(node: textLabel, "", pos: pos(mx: 0.5, my: 0.62), size: 25)
        textLabel.removeFromParent()
        textLabel.horizontalAlignmentMode = .left
        /*textLabel.lineBreakMode = .byWordWrapping
        textLabel.preferredMaxLayoutWidth = self.size.width * 0.6*/
        label(node: tapToContinue, "-tap to continue-", pos: pos(mx: 0.5, my: 0.3, y: 0), size: 18, color: .white)
        tapToContinue.alpha = 0
        pulsate(node: tapToContinue, amount: 0.6, duration: 3)
        planetbg.fitTo(self)
        self.addChild(planetbg)
        let _ = timeout(1, nextText)
        enemyship.position = pos(mx: 0.2, my: 0.7, x: 50)
        enemyship.setScale(planetbg.xScale)
        enemyship.alpha = 0
        self.addChild(enemyship)
    }
    func enemyAppear(){
        enemyship.run(.fadeIn(withDuration: 0.5))
        enemyship.run(.sequence([.moveTo(y: size.height / 2, duration: 13).ease(.easeOut),.repeatForever(.sequence([
            .moveBy(x: 0, y: 10, duration: 5).ease(.easeInEaseOut),
            .moveBy(x: 0, y: -10, duration: 5).ease(.easeInEaseOut)
        ]))]))
        var count = 110
        var a = {}
        var amount = 1.0
        var orx = CGFloat(), ory = CGFloat()
        a = interval(0.1){ [self] in
            count -= 1
            if count < 0{amount -= 0.05}
            if amount <= 0{return a()}
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
}
