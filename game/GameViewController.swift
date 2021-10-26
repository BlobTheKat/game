//
//  GameViewController.swift
//  game
//
//  Created by BlobKat on 04/07/2021.
//

import UIKit
import SpriteKit
import GameplayKit

var skview: SKView = SKView()
var controller: UIViewController = UIViewController()
var server = servers.uswest

class GameViewController: UIViewController {

    override func viewDidLoad() {
        SKScene.font = "HalogenbyPixelSurplus-Regular"
        super.viewDidLoad()
        if let view = self.view as! SKView? {
            controller = self
            skview = view
            SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
            Play.renderTo(skview)
            SKScene.transition = SKTransition.crossFade(withDuration: 0)
            view.preferredFramesPerSecond = 60
            view.showsNodeCount = true
            view.showsFPS = true
        }
        if let s = UserDefaults.standard.string(forKey: "server"){
            server = s
        }
    }
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for key in presses{
            if let a = key.key?.keyCode{
                skview.scene?.keyDown(a)
            }
        }
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for key in presses{
            if let a = key.key?.keyCode{
                skview.scene?.keyUp(a)
            }
        }
    }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for key in presses{
            if let a = key.key?.keyCode{
                skview.scene?.keyUp(a)
            }
        }
    }
}
