//
//  GameScene.swift
//  game
//
//  Created by BlobKat on 04/07/2021.
//

import SpriteKit

class Menu: SKScene {
	//YOUR CODE IS TRASH
	let play = SKLabelNode()
	let settings = SKLabelNode()
	override func didMove(to view: SKView) {
		self.label(node: play, "Play", pos: pos(mx: 0.5, my: 0.5, y: 0), size: fmed)
		play.alpha = 0
		play.run(SKAction.moveBy(x: 0, y: 60, duration: 1).ease(.easeOut))
		play.run(SKAction.fadeIn(withDuration: 1).ease(.easeOut))
		self.label(node: settings, "Settings", pos: pos(mx: 0.5, my: 0.5, y: -60), size: fmed)
		settings.alpha = 0
		let _ = timeout(0.5){ [self] in
			settings.run(SKAction.moveBy(x: 0, y: 60, duration: 1).ease(.easeOut))
			settings.run(SKAction.fadeIn(withDuration: 1).ease(.easeOut))
			
		}
		//self.label(node: trade, "", pos: pos(mx: 0.5, my: 0.5, y: -60), size: fmed)
	}
	
	
	override func nodeDown(_ node: SKNode, at point: CGPoint) {
		if node == play{
			play.fontSize -= 4
			Play.renderTo(skview)
		}
	}
	
	override func nodeMoved(_ node: SKNode, at point: CGPoint) {
		
	}
	
	override func nodeUp(_ node: SKNode, at point: CGPoint) {
		
	}
}
