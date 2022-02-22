//
//  Updating.swift
//  game
//
//  Created by Matthew on 22/02/2022.
//

import Foundation
import SpriteKit

var SECTOR_PATH = ""
class Updating: SKScene{
    var version = ""
    var fetch = ""
    var reallyDone = {}

    func done(){
        i -= 1
        print("done", i)
        if i == 0{
            //Really done
            UserDefaults.standard.set(version, forKey: "v")
            DispatchQueue.main.async{self.reallyDone()}
        }else{
            frac += (1 - frac) / CGFloat(i)
            progress(frac)
        }
    }
    func progress(_ frac: CGFloat){
        self.loading.run(.scaleX(to: frac, duration: 0.3).ease(.easeOut))
        self.loading.run(.moveTo(x: (frac - 1) * 150 + self.size.width / 2, duration: 0.3).ease(.easeOut))
    }
    var i = 0
    var frac = CGFloat()
    let loading = SKShapeNode(rect: CGRect(x: -150, y: 0, width: 300, height: 3))
    let loadingbg = SKShapeNode(rect: CGRect(x: -150, y: 0, width: 300, height: 3))

    override func didMove(to view: SKView){
        game.fetch("https://locus.tunnelvision.online/files") { [self] (str: String) in
            let data = GameData(data: str)[0]
            let ov = data["version"]!.string!
            let v = ov.split(separator: ".")
            let cv = (UserDefaults.standard.string(forKey: "v") ?? "0.0.0").split(separator: ".")
            fetch = data["behaviour"]!.string!
            SECTOR_PATH = data["sectors"]!.string!
            version = ov
            if v[0] > cv[0] || v[1] > cv[1] || v[2] > cv[2]{
                //oh no
                update()
                return
            }
            reallyDone()
        } _: { err in
            self.reallyDone()
        }
    }
    
    func update(){
        loadingbg.lineWidth = 0
        loadingbg.position = pos(my: 0.2)
        loadingbg.fillColor = .gray
        self.addChild(loading)
        loading.lineWidth = 0
        loading.position = pos(my: 0.2, x: -150)
        loading.fillColor = .white
        loading.zPosition = 1
        loading.xScale = 0
        self.addChild(loadingbg)
        let note = SKLabelNode(fontNamed: "HalogenbyPixelSurplus-Regular")
        note.text = "updating"
        note.fontSize = 60
        note.position = pos()
        self.addChild(note)
        
        //load stuff
        //taking advantage of weird global variable behaviour here
        GameData.fetch = fetch
        i += 4
        ships.load{self.done();ships = $0}
        asteroids.load{self.done();asteroids = $0}
        itemIndex.load {
            self.done()
            itemIndex = $0
            var i = 0
            self.i += items.count
            for itm in items{
                let ix = i
                itm.load{
                    self.done()
                    items[ix] = $0
                }
                i += 1
            }
        }
        missionTXTS.load{
            self.done()
            missionTXTS = $0
            for (k, v) in MISSIONS{
                let key = k + ""
                self.i += 1
                v.load{
                    self.done()
                    MISSIONS[key] = $0
                }
            }
        }
    }
}
