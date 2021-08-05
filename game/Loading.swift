//
//  Loading.swift
//  game
//
//  Created by Adam Reiner on 05/08/2021.
//

import Foundation
import SpriteKit

class Loading: SKScene{
    override init(size: CGSize){
        super.init(size: size)
        SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
        Play.renderTo(skview)
        SKScene.transition = SKTransition.crossFade(withDuration: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
