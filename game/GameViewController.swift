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
let fsmall: CGFloat = 32
let fmed: CGFloat = 48
let fbig: CGFloat = 72
var server = servers.uswest

class GameViewController: UIViewController {

    override func viewDidLoad() {
        SKScene.font = "BlobBits"
        super.viewDidLoad()
        if let view = self.view as! SKView? {
            skview = view
            Menu.renderTo(view)
            view.preferredFramesPerSecond = 60
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsPhysics = true
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
