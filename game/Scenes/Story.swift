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
    var writing = false
    var stop = {}
    let TEXTS = [
        "a long long time ago in\na far far away galaxy",
        "there once was an adam so big\n he blew up earth",
        "your goal is to fix it by\nluring him with vr headsets",
        "and feeding him the\nultimate weapon: MUSHROOMS",
        "this will destroy him\nand save humanity forever"
    ]
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
        stop = interval(0.04){ [self] in
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
            }
        }
        
    }
    override func didMove(to view: SKView) {
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
    }
    override func touch(at _: CGPoint) {
        nextText()
    }
}
