//
//  PlayControls.swift
//  game
//
//  Created by Matthew on 20/01/2022.
//

import Foundation
import SpriteKit
import GameKit

extension Play{
    override func nodeDown(_ node: SKNode, at point: CGPoint) {
        if fiddlenode == nil && nodeToFiddle?.zPosition ?? -.infinity < node.zPosition {nodeToFiddle = node}
        if statsWall.parent != nil && !swiping{
            switch node{
            case statsIcons[1]:
                shipSuit = -1
                statsLabel[0].text = "kills:"
                statsLabel[1].text = "deaths:"
                statsLabel[2].text = "kdr:"
                statsLabel[3].text = "planets:"
                statsLabel[4].text = "travel:"
                statsLabel[0].fontColor = .white
                equip.removeFromParent()
                if badgeCropNode.name != "badge"{
                    removeWallIcons()
                    var i = 0
                    statsIcons[0].texture = SKTexture(imageNamed: "shop")
                    statsIcons[1].texture = SKTexture(imageNamed: "statsbtn")
                    statsIcons[2].texture = SKTexture(imageNamed: "ship")
                    badgeCropNode.name = "badge"
                    let w = 0.4 * self.size.width, h = 0.5 * self.size.height
                    badgeCropNode.position.y = h
                    badgeCropNode.position.x = -w
                    let n = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: -h), size: CGSize(width: w * 2, height: h * 2)))
                    n.fillColor = .white
                    n.lineWidth = 0
                    badgeCropNode.maskNode = n
                    badgeCropNode.removeAllChildren()
                    for b in BADGES{
                        if i * 2 + 2 <= level{
                            //unlock
                            b.texture = SKTexture(imageNamed: "box")
                        }else{
                            //lock
                            b.texture = SKTexture(imageNamed: "boxlock")
                        }
                        if i == badge{
                            b.setScale(1.2)
                        }
                        b.removeFromParent()
                        badgeCropNode.addChild(b)
                        b.position.y = self.size.height / (i & 1 == 0 ? 4 : -4)
                        b.position.x = CGFloat(i >> 1) * 200 + 150
                        i += 1
                    }
                    badgeCropNode.removeFromParent()
                    statsWall.addChild(badgeCropNode)
                }else{
                    badgeCropNode.removeFromParent()
                    badgeCropNode.name = nil
                    wallIcons()
                    statsIcons[1].texture = SKTexture(imageNamed: "badge")
                }
                break
            case statsIcons[0]:
                shipSuit = -1
                statsLabel[0].text = "kills:"
                statsLabel[1].text = "deaths:"
                statsLabel[2].text = "kdr:"
                statsLabel[3].text = "planets:"
                statsLabel[4].text = "travel:"
                statsLabel[0].fontColor = .white
                equip.removeFromParent()
                if badgeCropNode.name != "shop"{
                    removeWallIcons()
                    statsIcons[0].texture = SKTexture(imageNamed: "statsbtn")
                    statsIcons[1].texture = SKTexture(imageNamed: "badge")
                    statsIcons[2].texture = SKTexture(imageNamed: "ship")
                    let w = 0.4 * self.size.width, h = 0.5 * self.size.height
                    badgeCropNode.position.y = h
                    badgeCropNode.position.x = -w
                    let n = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: -h), size: CGSize(width: w * 2, height: h * 2)))
                    n.fillColor = .white
                    n.lineWidth = 0
                    badgeCropNode.maskNode = n
                    badgeCropNode.removeAllChildren()
                    badgeCropNode.name = "shop"
                    
                    //DISPLAY SHOP
                    let cheapPass = SKSpriteNode(imageNamed: "cheap_pass")
                    let pass = SKSpriteNode(imageNamed: "pass")
                    let cheapPrice = SKSpriteNode(imageNamed: "price300")
                    let price = SKSpriteNode(imageNamed: "price1000")
                    let gems1 = SKSpriteNode(imageNamed: "gems60")
                    let gems2 = SKSpriteNode(imageNamed: "gems300")
                    let gems3 = SKSpriteNode(imageNamed: "gems1000")
                    let gems4 = SKSpriteNode(imageNamed: "gems5000")
                    let dummy = SKSpriteNode(imageNamed: "blank")
                    dummy.setScale(0)
                    cheapPass.position = CGPoint(x: w, y: 80)
                    cheapPrice.position = CGPoint(x: w, y: -100)
                    pass.position = CGPoint(x: w * 2.5 + 50, y: 80)
                    price.position = CGPoint(x: w * 2.5 + 50, y: -100)
                    gems1.position = CGPoint(x: w * 4, y: 80)
                    gems2.position = CGPoint(x: w * 4 + 160, y: 80)
                    gems3.position = CGPoint(x: w * 4, y: -80)
                    gems4.position = CGPoint(x: w * 4 + 160, y: -80)
                    dummy.position.x = w * 5 + 80
                    badgeCropNode.addChild(cheapPass)
                    badgeCropNode.addChild(cheapPrice)
                    badgeCropNode.addChild(pass)
                    badgeCropNode.addChild(price)
                    badgeCropNode.addChild(gems1)
                    badgeCropNode.addChild(gems2)
                    badgeCropNode.addChild(gems3)
                    badgeCropNode.addChild(gems4)
                    badgeCropNode.addChild(dummy)
                    pass.setScale(1.2)
                    price.setScale(1.2)
                    cheapPass.setScale(1.2)
                    cheapPrice.setScale(1.2)
                    
                    badgeCropNode.removeFromParent()
                    statsWall.addChild(badgeCropNode)
                }else{
                    badgeCropNode.name = nil
                    badgeCropNode.removeFromParent()
                    wallIcons()
                    statsIcons[0].texture = SKTexture(imageNamed: "shop")
                }
                break
            case statsIcons[2]:
                shipSuit = -1
                statsLabel[0].text = "kills:"
                statsLabel[1].text = "deaths:"
                statsLabel[2].text = "kdr:"
                statsLabel[3].text = "planets:"
                statsLabel[4].text = "travel:"
                statsLabel[0].fontColor = .white
                equip.removeFromParent()
                if badgeCropNode.name != "ship"{
                    removeWallIcons()
                    statsIcons[0].texture = SKTexture(imageNamed: "shop")
                    statsIcons[1].texture = SKTexture(imageNamed: "badge")
                    statsIcons[2].texture = SKTexture(imageNamed: "statsbtn")
                    let w = 0.4 * self.size.width, h = 0.5 * self.size.height
                    badgeCropNode.position.y = h
                    badgeCropNode.position.x = -w
                    let n = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: -h), size: CGSize(width: w * 2, height: h * 2)))
                    n.fillColor = .white
                    n.lineWidth = 0
                    badgeCropNode.maskNode = n
                    badgeCropNode.removeAllChildren()
                    badgeCropNode.name = "ship"
                    
                    //DISPLAY SHIPS
                    var i = 0
                    for s in SHIPS{
                        s.removeFromParent()
                        if i * 2 + 1 <= level{
                            //unlock
                            s.texture = SKTexture(imageNamed: "box")
                        }else{
                            //lock
                            s.texture = SKTexture(imageNamed: "boxlock")
                        }
                        badgeCropNode.addChild(s)
                        s.position.y = self.size.height / (i & 1 == 0 ? 4 : -4)
                        s.position.x = CGFloat(i >> 1) * 200 + 150
                        i += 1
                    }
                    
                    badgeCropNode.removeFromParent()
                    statsWall.addChild(badgeCropNode)
                }else{
                    badgeCropNode.name = nil
                    badgeCropNode.removeFromParent()
                    wallIcons()
                    statsIcons[2].texture = SKTexture(imageNamed: "ship")
                }
                break
            case equip:
                UserDefaults.standard.set(shipSuit, forKey: "shipid")
                ship.suit(shipSuit)
                equip.texture = SKTexture(imageNamed: "equipped")
            default:break
            }
            return
        }
        switch node{
        case addItemIcon:
            if tutorialProgress == .gemFinish{return}
            hideUpgradeUI()
            if tutorialProgress == .addItem{ nextStep(); lastSentEnergy += 150 }
            //render additem ui
            var used = [Int8](repeating: 0, count: 128)
            var lvl = 0
            for itm in planetLanded!.items{
                guard itm != nil else {continue}
                used[Int(itm!.type.rawValue)] += 1
                if itm!.type == .camp{lvl = Int(itm!.lvl)}
            }
            for i in 0...addItemIcons.count-1{
                addItemIcons[i].position = CGPoint(x: 600 + CGFloat(i) * 400, y: -220)
                addItemPrices[i].position = addItemIcons[i].position
                addItemPrices[i].position.y -= 250
                addItemPrices[i].fontSize = 60
                if Double(used[i+1]) >= Double(Double(lvl) - (items[i+1][0]["available"]?.number ?? 1.0)) / (items[i+1][0]["every"]?.number ?? 1.0) + 1.0{
                    addItemIcons[i].alpha = 0.5
                }else{
                    addItemIcons[i].alpha = 1
                    buildBG.addChild(addItemPrices[i])
                }
                buildBG.addChild(addItemIcons[i])
                
            }
            break
        case backIcon:
            if buyScreenShowing{
                colonizeBG.removeFromParent()
                showControls()
                buyScreenShowing = false
            }
            break
        case buyIcon:
            if tutorialProgress == .buyPlanet{
                nextStep()
            }
            if energyAmount >= planetLanded!.price {
                if buyScreenShowing{
                    colonizeBG.removeFromParent()
                    coloIcon.removeFromParent()
                    showControls()
                    buyScreenShowing = false
                }
                
                colonize(planetLanded!)
            }else{
                DisplayWARNING("not enough energy",.warning,false)
            }
            break
        case editColoIcon:
            if tutorialProgress == .editPlanet{ nextStep() }
            else if tutorialProgress.rawValue > 8 && tutorialProgress != .done{
                return
            }
            planetEditMode()
            if !hideControl{
                hideControl.toggle()
                hideControls()
            }else{
                hideControl.toggle()
                showControls()
            }
            
            break
        case collect:
            if planetLanded == nil{break}
            if collectedLabel2.text != ""{
                collectFrom(planetLanded!);planetLanded!.last=NSDate().timeIntervalSince1970
            }else{
                if energyAmount < Double(Int(10000 - planetLanded!.health*10000)){
                    DisplayWARNING("not enough energy",.warning,false)
                    break
                }
                //restore
                restore(planetLanded!)
            }
            break
        case upgradebtn:
            guard let item = planetLanded?.items[Int(itemRot)] else {break}
            let itm = items[Int(item.type.rawValue)][Int(item.lvl + 1)]
            let price = itm["price"]?.number ?? 0
            let price2 = Float(itm["price2"]?.number ?? 0)
            if energyAmount < price || researchAmount < price2{
                DisplayWARNING("not enough energy",.warning,false)
            }
            changeItem(planetLanded!, Int(itemRot))
            hideUpgradeUI()
            break
        case upgradePrice:
            if upgradePrice.fontColor == .green{
                //skip time
                guard let end = planetLanded?.items[Int(itemRot)]?.upgradeEnd else {break}
                guard end > 1 else {return}
                let price = ceil(Double(Int(end) - Int(NSDate().timeIntervalSince1970)) / 300)
                if Double(gemCount) < price{
                    DisplayWARNING("not enough gems",.warning,false)
                    break
                }
                if tutorialProgress == .gemFinish && planetLanded?.items[Int(itemRot)]?.type == .drill{ nextStep(); ship.controls = true; planetEditMode() }
                skipBuild(planetLanded!, itemRot)
            }else if upgradePrice.fontColor == .orange{
                //repair
                guard let item = planetLanded?.items[Int(itemRot)] else {break}
                let price = (items[Int(item.type.rawValue)][Int(item.lvl)]["price"]?.number ?? 0) * 1.5
                let price2 = (items[Int(item.type.rawValue)][Int(item.lvl)]["price2"]?.number ?? 0) * 1.5
                if energyAmount < price || Double(researchAmount) < price2{
                    self.DisplayWARNING("not enough energy",.warning,false)
                    break
                }
                repair(planetLanded!, itemRot)
            }
            
            break
        case coloArrow:
            if tutorialProgress == .gemFinish{return}
            var a: CGFloat = 0
            if point.x > coloArrow.position.x{
                repeat{
                    a += 1
                    itemRot &+= 1
                }while planetLanded!.items[Int(itemRot)] == nil
            }else{
                repeat{
                    a -= 1
                    itemRot &-= 1
                }while planetLanded!.items[Int(itemRot)] == nil
            }
            planetLanded!.run(.rotate(byAngle: a * PI256, duration: abs(a) / 180.0).ease(.easeInEaseOut))
            renderUpgradeUI()
            break
        default:
            break
        }
        if removeTrackerIcon == node{
            removeTrackers()
        }
        if accountIcon == node{
            gkview?.present(controller, animated: true){
                if GKLocalPlayer.local.isAuthenticated{
                    //get token
                    self.gameCenterAuthed()
                }else{
                    //create token
                    self.gameGuest()
                }
            }
            tapToStartPressed = true
        }
        if cockpitIcon == node{
          //  cockpitIcon.texture = SKTexture(imageNamed: "cockpitOn")
        }
        if let n = node as? Object{
            guard n != ship else {return}
            guard n as? Planet == nil else{return}
            if let i = tracked.firstIndex(of: n){
                for i in n.children{
                    if i.zPosition == 9{i.removeFromParent()}
                }
                tracked.remove(at: i)
                trackArrows.remove(at: i)
            }else{
                let tracker1 = SKSpriteNode(imageNamed: "tracker1")
                let tracker2 = SKSpriteNode(imageNamed: "tracker2")
                tracker1.zPosition = 9
                tracker1.setScale(1)
                n.addChild(tracker1)
                tracker1.run(.repeatForever(.rotate(byAngle: -.pi, duration: 1)))
                tracker2.zPosition = 9
                tracker2.setScale(1)
                n.addChild(tracker2)
                tracker2.run(.repeatForever(.rotate(byAngle: .pi, duration: 1.3)))
                tracked.append(n)
                
                let a = SKSpriteNode(imageNamed: "arrow2")
                a.anchorPoint = CGPoint(x: 0.5, y: 1)
                a.setScale(0.25)
                trackArrows.append(a)
            }
        }
        if repairIcon == node{
            if isWarning{
                warning.removeAction(forKey: "warningAlpha")
                warning.alpha = 0
                isWarning = false
            }else{
                DisplayWARNING("Placeholder",.warning,true)
                isWarning = true
            }
        }
        
        if warning == node{
            warning.removeAction(forKey: "warningAlpha")
            warning.alpha = 0
        }
        
        if accountIcon == node{
            
            if !showAccount{
                accountIcon.run(SKAction.moveBy(x: 0, y: -200, duration: 0.35).ease(.easeOut))
                accountBG.run(SKAction.moveBy(x: 0, y: -300, duration: 0.35).ease(.easeOut))
                showAccount = true
            }else{
                accountIcon.run(SKAction.moveBy(x: 0, y: 200, duration: 0.35).ease(.easeOut))
                accountBG.run(SKAction.moveBy(x: 0, y: 300, duration: 0.35).ease(.easeOut))
                showAccount = false
            }
            
        }
        if navArrow == node{
            if tutorialProgress == .openNavigations{
                if editColoIcon.parent != nil{
                    tutorialProgress = .buyPlanet
                }
                nextStep()
            }
            if showNav == false{
            navArrow.run(SKAction.move(to: pos(mx: 0.43, my: 0 ), duration: 0.35).ease(.easeOut))
            navArrow.run(SKAction.rotate(toAngle: 3.18, duration: 0.35).ease(.easeOut))
                navBG.run(SKAction.move(to: pos(mx: 0.43, my: 0 ), duration: 0.35).ease(.easeOut))
                showNav = true
            }else if showNav == true{
                navArrow.run(SKAction.move(to: pos(mx: 0.43, my: 0.5 ), duration: 0.35).ease(.easeOut))
                navArrow.run(SKAction.rotate(toAngle: 0, duration: 0.35).ease(.easeOut))
                navBG.run(SKAction.move(to: pos(mx: 0.43, my: 0.5  ), duration: 0.35).ease(.easeOut))
                showNav = false
            }
        }
        if thrustButton == node{
            if point.y > thrustButton.position.y + 50{
                thrustButton.texture = SKTexture(imageNamed: "shooting2")
                startLazer()
            }else{
                thrustButton.texture = SKTexture(imageNamed: "thrustOn")
                
                pauseLazer()
                ship.thrust = true
                if !playingThrustSound{
                    thrustSound.removeAllActions()
                    thrustSound.removeFromParent()
                    thrustSound.run(SKAction.changeVolume(to: 1.5, duration: 0.1))
                    self.addChild(thrustSound)
                    playingThrustSound = true
                }
            }
            
        }
        if dPad == node{
            if point.x > dPad.position.x{
                ship.thrustRight = true
                dPad.texture = SKTexture(imageNamed: "dPadRight")
                ship.thrustLeft = false
            }else{
                ship.thrustLeft = true
                dPad.texture = SKTexture(imageNamed: "dPadLeft")
                ship.thrustRight = false
            }
        }
        
        if mapIcon == node{
            mapIcon.texture = SKTexture(imageNamed: "mapT")
            
            if showMap == false{
                mapBG.alpha = 1
                FakemapBG.alpha = 1
                showMap = true
                FakemapBG.position = CGPoint(x: -mainMap.position.x/10 - playerArrow.position.x/10 ,y: -mainMap.position.y/10 - playerArrow.position.y/10)
            }else if showMap == true{
                mapBG.alpha = 0
                FakemapBG.alpha = 0
                showMap = false
            }
        }
        if coloIcon == node{
            if tutorialProgress == .planetIcon{
                nextStep()
            }
            if !buyScreenShowing{
                buyScreenShowing = true
                cam.addChild(colonizeBG)
                hideControls()
            }
        }
    }
    override func nodeMoved(_ node: SKNode, at point: CGPoint) {
        if dPad == node{
            if point.x > dPad.position.x{
                ship.thrustRight = true
                dPad.texture = SKTexture(imageNamed: "dPadRight")
                ship.thrustLeft = false
            }else{
                ship.thrustLeft = true
                dPad.texture = SKTexture(imageNamed: "dPadLeft")
                ship.thrustRight = false
            }
        }
        if thrustButton == node{
            if point.y > thrustButton.position.y + 50{
                if !usingConstantLazer{
                    startLazer()
                }
                
            }else{
                thrustButton.texture = SKTexture(imageNamed: "thrustOn")
                self.action(forKey: "constantLazer")?.speed = 0
                pauseLazer()
                ship.thrust = true
            }
            
        }
    }
    
    override func nodeUp(_ node: SKNode, at _: CGPoint) {
        if !swiping && node.parent == buildBG, var i = addItemIcons.firstIndex(of: node as? SKSpriteNode ?? ship){
            guard node.alpha == 1 else{
                DisplayWARNING("upgrade camp to build more",.warning,false)
                return
            }
            i += 1
            if tutorialProgress == .buyDrill && i != 1{ return }
            let price = items[i][1]["price"]?.number ?? 0
            let price2 = Float(items[i][1]["price2"]?.number ?? 0)
            if energyAmount < price || researchAmount < price2{
                DisplayWARNING("not enough energy",.warning,false)
                return
            }
            var pos = UInt8()
            var gap = 0
            var curGap = 0
            var start = -1
            for i in 0...255{
                if planetLanded!.items[i] == nil{
                    curGap += 1
                }else{
                    if curGap >= gap{
                        if start == -1{start = curGap;curGap = 0;continue}
                        gap = curGap
                        pos = UInt8((i - curGap / 2) & 255)
                        curGap = 0
                    }else{
                        curGap = 0
                    }
                }
            }
            if start + curGap > gap{
                gap = start + curGap
                pos = UInt8((start - (start + curGap) / 2) & 255)
            }
            
            if gap < Int(min(32, ceil(10 / planetLanded!.radius))) * 2 + 1{
                //yell at the user
                DisplayWARNING("create more space", .warning, true)
                return
            }
            itemRot = pos
            planetLanded!.run(.rotate(toAngle: CGFloat(pos) * PI256, duration: 0.5).ease(.easeInEaseOut))
            makeItem(planetLanded!, pos, .init(rawValue: UInt8(i))!)
            if tutorialProgress == .buyDrill{ nextStep() }
        }
        if !swiping && node.parent == badgeCropNode && badgeCropNode.name == "ship" && node.position.x < size.width * 0.8{
            let id = badgeCropNode.children.firstIndex(of: node)! + 1
            statsLabel[4].text = "speed:"
            statsLabel[3].text = "agility:"
            statsLabel[2].text = "damage:"
            statsLabel[1].text = "size: \(Int(ships[id]["radius"]?.number ?? 15) * 2)m,"
            statsLabel[0].text = ""
            statsLabel2[4].text = "\(Int((ships[id]["speed"]?.number ?? 1) * 100))"
            statsLabel2[3].text = "\(Int((ships[id]["spin"]?.number ?? 1) * 10))"
            let dmg = SHOOTDAMAGES[id-1].reduce(0) { a, b in return a + b}
            statsLabel2[2].text = "\(Int(dmg)) (\(Int(dmg * (ships[id]["shootspeed"]?.number ?? 0.05) * 60))/s)"
            statsLabel2[1].text = "\(formatNum(ships[id]["mass"]?.number ?? 300))tons"
            statsLabel2[0].text = ""
            if level < id * 2 - 1{
                statsLabel[0].text = "Unlocks at level \(id * 2 - 1)"
                statsLabel[0].fontColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)
                equip.removeFromParent()
            }else{
                equip.position = pos(mx: 0.7, my: 0, y: 70)
                equip.setScale(0.4)
                equip.removeFromParent()
                statsWall.addChild(equip)
                equip.texture = SKTexture(imageNamed: "equip")
            }
            shipSuit = id
        }
        if !swiping && node.parent == badgeCropNode && badgeCropNode.name == "badge" && node.position.x < size.width * 0.8{
            let id = badgeCropNode.children.firstIndex(of: node)! + 1
            if level >= id * 2{
                //equip badge
                node.setScale(1.2)
                BADGES[badge].setScale(1)
                badge = id
            }
        }
        if thrustButton == node{
            thrustSound.run(SKAction.sequence([
                SKAction.changeVolume(to: 0, duration: 0.2),
                SKAction.run{
                    self.thrustSound.removeFromParent()
                    self.playingThrustSound = false
                }
            ]))
            self.playingThrustSound = false
            pauseLazer()
            ship.thrust = false
            if tutorialProgress == .thrust{ nextStep() }
            thrustButton.texture = SKTexture(imageNamed: "thrustOff")
        }
        if dPad == node{
            dPad.texture = SKTexture(imageNamed: "dPad")
            ship.thrustLeft = false
            ship.thrustRight = false
            if tutorialProgress == .dpad { nextStep() }
        }
        if dragRemainder.isInfinite{dragRemainder = 0}
        if mapIcon == node{
            mapIcon.texture = SKTexture(imageNamed: "map")
        }
        if cockpitIcon == node && statsWall.parent == nil{
            cam.addChild(statsWall)
            statsWall.position.y = self.size.height / 2
            statsWall.run(.moveTo(y: 0, duration: 0.5))
            statsWall.alpha = 0.99
            let _ = timeout(0.5){self.statsWall.alpha = 1}

            for navigations in AllNav{
                navigations.run(SKAction.fadeOut(withDuration: 0.1))
            }
        }
    }
    
    
    
    
    
    
    
    override func touch(at p: CGPoint) {
        if nodeToFiddle != nil{nodeToFiddle!.fiddle();nodeToFiddle = nil}
        if tutInfo.text == "done" { tutArrow.run(SKAction.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()])); tutInfo.text = ""; ship.controls = true; if hideControl{hideControl = false; showControls()} }
        if !hideControl{showControls()}
        if mapPress1 == nil{
            mapPress1 = p
        }else if mapPress2 == nil{
            mapPress2 = p
        }else{
            (mapPress1, mapPress2) = (mapPress2, p)
        }
        if  !showAccount && !startPressed && !tapToStartPressed && children.count > MIN_NODES_TO_START{
            if !playedLightSpeedOut{
                accountIcon.removeFromParent()
                removeTapToStart()
                ship.position.x = CGFloat(secx) - sector.1.pos.x
                ship.position.y = CGFloat(secy) - sector.1.pos.y
                self.run(lightSpeedOut)
                playedLightSpeedOut = true
                //anim
                var mov = 0.1
                var up = 0.07
                var stop = {}
                let stop1 = interval(0.05){
                    mov = -sign(mov) * max(0, abs(mov) + up)
                    if(abs(mov) < 0.01){
                        return stop()
                    }
                    self.ship.xScale *= 0.99
                    self.cam.run(SKAction.moveBy(x: mov, y: 0, duration: 0.05).ease(.easeOut))
                }
                let stop2 = interval(0.06){
                    self.cam.run(SKAction.moveBy(x: 0, y: mov, duration: 0.06).ease(.easeOut))
                }
                stop = {stop1();stop2()}
                let _ = timeout(2) {
                    up = -0.5
                    self.ship.run(.scale(to: 0.25, duration: 0.5))
                    self.startGame()
                    self.removeAction(forKey: "inLightSpeed")
                    self.inlightSpeed.removeFromParent()
                }
            }
        }
        tapToStartPressed = false
        
        if presence && moveItemIcon.contains(p){
            if dragRemainder.isNaN{dragRemainder = 0;oldItemRot = itemRot;coloArrow.removeFromParent()}
            else{
                guard let l = planetLanded!.children.first(where: {$0.userData?["rot"] as? UInt8 == itemRot}) as? SKSpriteNode else {return}
                if l.color == .red{
                    let amount = CGFloat(Int8(bitPattern: oldItemRot &- itemRot))
                    planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] = planetLanded!.items[Int(itemRot)]
                    planetLanded!.items[Int(itemRot)] = nil
                    itemRot &+= UInt8(Int(amount) & 255)
                    planetLanded!.run(.rotate(byAngle: amount * PI256, duration: abs(amount) / 180.0))
                    l.run(.rotate(byAngle: -amount * PI256, duration: abs(amount) / 180.0))
                    l.userData?["rot"] = itemRot
                    l.color = .clear
                    l.colorBlendFactor = 0
                }
                if coloArrow.parent == nil{cam.addChild(coloArrow)}
                changeItem(planetLanded!, Int(oldItemRot), Int(itemRot))
            }
        }
    }
    override func swipe(from a: CGPoint, to b: CGPoint) {
        swiping = true
        if !dragRemainder.isNaN{
            if abs(a.x) > self.size.width / 5{
                dragRemainder = sign(a.x) * .infinity
                return
            }else if dragRemainder.isInfinite{
                dragRemainder = 0
            }
            dragRemainder += (b.x - a.x) / 12
            let d = dragRemainder
            dragRemainder.formRemainder(dividingBy: 1)
            var amount = round(d - dragRemainder + 0.1)
            guard amount != 0 else {return} //shortcut
            while planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] != nil{amount += sign(amount)}
            let newRot = UInt8((Int(itemRot) + Int(amount)) & 255)
            let box = UInt8(min(32, ceil(3000 / planetLanded!.radius)))
            var red = false
            var i = newRot &- box &+ 1
            while i != newRot &+ box{
                if planetLanded!.items[Int(i)] != nil && i != itemRot{ red = true }
                i &+= 1
            }
            guard let l = planetLanded!.children.first(where: {$0.userData?["rot"] as? UInt8 == itemRot}) as? SKSpriteNode else {return}
            planetLanded!.items[(Int(itemRot) + Int(amount)) & 255] = planetLanded!.items[Int(itemRot)]
            planetLanded!.items[Int(itemRot)] = nil
            itemRot &+= UInt8(Int(amount) & 255)
            planetLanded!.run(.rotate(byAngle: amount * PI256, duration: abs(amount) / 10.0))
            l.run(.rotate(byAngle: -amount * PI256, duration: abs(amount) / 10.0))
            l.userData?["rot"] = itemRot
            if red{
                l.colorBlendFactor = 0.5
                l.color = .red
            }else{
                l.colorBlendFactor = 0
                l.color = .clear
            }
            return
        }else if addItemIcons[0].parent != nil{
            if statsWall.parent == nil || b.y < -50{
                var x = (b.x - a.x) * 2.5
                var correct = addItemIcons[0].position.x + x - 600
                if correct > 0{x -= correct}else{
                    correct = addItemIcons.last!.position.x + x - (self.size.width * 2.5 - 300)
                    if correct < 0{x -= correct}
                }
                for n in addItemIcons{
                    n.position.x += x
                }
                for n in addItemPrices{
                    n.position.x += x
                }
                return
            }
        }
        if statsWall.parent != nil && statsWall.alpha == 1 && abs(b.y-a.y) > abs(b.x-a.x) * 2{
            statsWall.removeAllActions()
            statsWall.position.y = max(statsWall.position.y + b.y - a.y, 0)
            return
        }else if statsWall.parent != nil && statsWall.alpha == 1{
            if badgeCropNode.parent != nil && badgeCropNode.children.count > 0{
                appleSwipe = (b.x - a.x)
                var x = appleSwipe * 2
                var correct = badgeCropNode.children.first!.position.x + x - badgeCropNode.children.first!.frame.width
                if correct > 0{x -= correct}else{
                    correct = badgeCropNode.children.last!.position.x + x - (self.size.width * 0.8) + badgeCropNode.children.last!.frame.width
                    if correct < 0{x -= correct}
                }
                for node in badgeCropNode.children{
                    node.position.x += x
                }
            }
            return
        }
        guard showMap else {return}
        if dPad.contains(b) || thrustButton.contains(b){return}
        if mapPress1 != nil && mapPress2 != nil{
            var dx = mapPress1!.x - mapPress2!.x
            var dy = mapPress1!.y - mapPress2!.y
            let d1 = dx * dx + dy * dy
            if closest(a, mapPress1!, mapPress2!){
                mapPress1 = b
            }else{
                mapPress2 = b
            }
            dx = mapPress1!.x - mapPress2!.x
            dy = mapPress1!.y - mapPress2!.y
            let d2 = dx * dx + dy * dy
            var z = sqrt(d2 / d1)
            if FakemapBG.xScale * z > 1{z = 1 / FakemapBG.xScale}
            if FakemapBG.xScale * z < 0.02{z = 0.02 / FakemapBG.xScale}
            FakemapBG.xScale *= z
            FakemapBG.yScale *= z
            FakemapBG.position.x *= z
            FakemapBG.position.y *= z
        }
        FakemapBG.position.x += b.x - a.x
        FakemapBG.position.y += b.y - a.y
    }
    override func release(at point: CGPoint){
        if statsWall.parent != nil && statsWall.alpha == 1{
            if statsWall.position.y > size.height / 4{
                statsWall.run(SKAction.sequence([SKAction.moveTo(y: self.size.height / 2, duration: 0.5).ease(.easeOut),SKAction.removeFromParent()]))
                shipSuit = -1
                statsLabel[0].text = "kills:"
                statsLabel[1].text = "deaths:"
                statsLabel[2].text = "kdr:"
                statsLabel[3].text = "planets:"
                statsLabel[4].text = "travel:"
                statsLabel[0].fontColor = .white
                equip.removeFromParent()
                statsWall.alpha = 0.99
                let _ = timeout(0.5){self.statsWall.alpha = 1}
                for navigations in AllNav{
                    navigations.run(SKAction.fadeIn(withDuration: 0.1))
                }
            }else{
                statsWall.run(SKAction.moveTo(y: 0, duration: 0.5).ease(.easeOut))
                statsWall.alpha = 0.99
                let _ = timeout(0.5){self.statsWall.alpha = 1}
            }
        }
        swiping = false
        if mapPress2 != nil{
            //both
            if closest(point, mapPress1!, mapPress2!){
                mapPress1 = mapPress2
                mapPress2 = nil
            }else{
                mapPress2 = nil
            }
        }else if mapPress1 != nil{
            //1
            mapPress1 = nil
        }
    }
    
    func nextStep(_ next: Bool? = true){
        if next == nil{
            if tutorialProgress == .done{return}
            if tutorialProgress.rawValue > 3{
                tutorialProgress = .followPlanet
            }
        }
        guard !animating else {return}
        animating = true
        let i = tutorialProgress.rawValue + (next != nil ? (next! ? 1 : -1) : 0)
        tutorialProgress = .init(rawValue: i)!
        if tutInfo.parent != nil{tutInfo.run(.fadeOut(withDuration: 0.2))}
        if tutArrow.parent != nil{tutArrow.run(.fadeOut(withDuration: 0.2))}
        if tutorialProgress == .done{
            let _ = timeout(0.3){ [self] in
                ship.controls = true
                tutArrow.position = .zero
                tutArrow.setScale(1)
                tutArrow.texture = SKTexture(imageNamed: "tutdone")
                tutArrow.size = tutArrow.texture!.size()
                tutArrow.setScale(0.6)
                tutArrow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                tutInfo.text = "done"
                tutArrow.removeFromParent()
                cam.addChild(tutArrow)
                tutArrow.run(.fadeIn(withDuration: 0.2))
            }
            return
        }
        tutInfo.fontSize = 25
        tutInfo.zPosition = .infinity
        tutArrow.zPosition = .infinity
        tutInfo.numberOfLines = 10
        let _ = timeout(0.3){ [self] in
            let (hori, verti, mx: mx, my: my, x: x, y: y, text) = tutorials[i]
            if hori == .center{
                tutArrow.anchorPoint = CGPoint(x: 0.5, y: 0.6)
                tutArrow.texture = SKTexture(imageNamed: "tut2")
                tutArrow.xScale = hori == .right ? -0.5 : 0.5
                tutArrow.yScale = verti == .top ? -0.5 : 0.5
            }else{
                tutArrow.texture = SKTexture(imageNamed: "tut")
                tutArrow.anchorPoint = CGPoint(x: 0.15, y: 0.3)
                tutArrow.xScale = hori == .right ? -0.5 : 0.5
                tutArrow.yScale = verti == .top ? -0.5 : 0.5
            }
            tutInfo.horizontalAlignmentMode = hori
            tutInfo.verticalAlignmentMode = verti
            tutArrow.position = pos(mx: mx, my: my, x: x, y: y)
            tutInfo.position = tutArrow.position
            tutInfo.text = text
            tutArrow.alpha = 0.8
            tutInfo.alpha = 0.8
            tutArrow.removeFromParent()
            tutInfo.removeFromParent()
            cam.addChild(tutArrow)
            cam.addChild(tutInfo)
            tutInfo.run(.fadeIn(withDuration: 0.2))
            tutArrow.run(.fadeIn(withDuration: 0.2))
            animating = false
        }
    }
    
    
    
    
    
    
    
    override func keyDown(_ key: UIKeyboardHIDUsage) {
        hideControls()
        if let b = boolfiddle, key == .keyboardComma || key == .keyboardPeriod{b.setTo(!b.value);return}
        if let b = bytefiddle{if key == .keyboardComma{b.setTo(b.value&-1);return}else if key == .keyboardPeriod{b.setTo(b.value&+1);return}else if key == .keyboardN{b.setTo(b.value&-10);return}else if key == .keyboardM{b.setTo(b.value&+10);return}}
        if let f = floatfiddle{if key == .keyboardComma{f.setTo(f.value-1);return}else if key == .keyboardPeriod{f.setTo(f.value+1);return}else if key == .keyboardN{f.setTo(f.value-10);return}else if key == .keyboardM{f.setTo(f.value+10);return}else if key == .keyboardSemicolon{f.setTo(f.value-0.1);return}else if key == .keyboardQuote{f.setTo(f.value+0.1);return}}
        boolfiddle = nil
        floatfiddle = nil
        bytefiddle = nil
        switch key{
        case .keyboardX:
            floatfiddle = reg.x
            break
        case .keyboardY:
            floatfiddle = reg.y
            break
        case .keyboardZ:
            floatfiddle = reg.z
            break
        case .keyboardS:
            floatfiddle = reg.s
            break
        case .keyboardI:
            boolfiddle = reg.i
            break
        case .keyboardO:
            floatfiddle = reg.o
            break
        case .keyboardP:
            boolfiddle = reg.p
            break
        case .keyboardOpenBracket:
            floatfiddle = reg.mx
            break
        case .keyboardCloseBracket:
            floatfiddle = reg.my
            break
        case .keyboardHyphen:
            floatfiddle = reg.sx
            break
        case .keyboardEqualSign:
            floatfiddle = reg.sy
            break
        case .keyboardR:
            bytefiddle = reg.r
            break
        case .keyboardG:
            bytefiddle = reg.g
            break
        case .keyboardB:
            bytefiddle = reg.b
            break
        case .keyboardGraveAccentAndTilde:
            let node = "<#node#" + ">"
            let label = fiddlenode as? SKLabelNode != nil
            UIPasteboard.general.string = "\(node).position = pos(mx: \(rnd(reg.mx.value)), my: \(rnd(reg.my.value))\(reg.x.value != 0 || reg.y.value != 0 ? ", x: \(rnd(reg.x.value)), y: \(rnd(reg.y.value))":""))\n\(reg.o.value < 1 ? "\(node).alpha = \(rnd(reg.o.value))\n":"")\(reg.s.value != 1 ? (label ? "\(node).fontSize = \(rnd(reg.s.value*32))\n":"\(node).setScale(\(rnd(reg.s.value)))\n"):"")\(reg.z.value != 0 ? "\(node).zPosition = \(rnd(reg.z.value))\n":"")\( reg.sx.value != 0.5 || reg.sy.value != 0.5 ? (label ? "\(reg.sx.value > 0.55 ? "\(node).horizontalAlignmentMode = .right\n" : (reg.sx.value < 0.45 ? "\(node).horizontalAlignmentMode = .left\n" : ""))\(reg.sy.value > 0.55 ? "\(node).verticalAlignmentMode = .top\n" : (reg.sy.value >= 0.45 ? "\(node).verticalAlignmentMode = .center\n" : ""))" : "\(node).anchorPoint = CGPoint(x: \(rnd(reg.sx.value)), y: \(rnd(reg.sy.value)))\n"):"")\(reg.r.value != 255 || reg.g.value != 255 || reg.b.value != 255 && (label || fiddlenode as? SKSpriteNode != nil) ? "\(node).\(label ? "fontColor" : "color") = UIColor(red: \(rnd(Double(reg.r.value) / 255)), green: \(rnd(Double(reg.g.value) / 255)), blue: \(rnd(Double(reg.b.value) / 255))\n":"")"
        case .keyboardF:
            if fiddlenode == nil{fiddlenode = SKNode();fiddlenode!.name="!"}
            else if fiddlenode!.name != "!"{fiddlenode = nil}
        default:break
        }
        if key == .keyboardUpArrow || key == .keyboardW{
            ship.thrust = true
            if !playingThrustSound{
                thrustSound.removeAllActions()
                thrustSound.removeFromParent()
                thrustSound.run(SKAction.changeVolume(to: 1.5, duration: 0.1))
                self.addChild(thrustSound)
                playingThrustSound = true
            }
        }else if key == .keyboardRightArrow || key == .keyboardD{
            ship.thrustRight = true
        }else if key == .keyboardLeftArrow || key == .keyboardA{
            ship.thrustLeft = true
        }else if key == .keyboardDownArrow || key == .keyboardK{
            startLazer()
        }else if key == .keyboardTab{
            if showMap == false{
                mapBG.alpha = 1
                FakemapBG.alpha = 1
                showMap = true
                
                FakemapBG.position = CGPoint(x: -mainMap.position.x/10 - playerArrow.position.x/10 ,y: -mainMap.position.y/10 - playerArrow.position.y/10)
            }else if showMap == true{
                mapBG.alpha = 0
                FakemapBG.alpha = 0
                showMap = false
            }
        }
        if key == .keyboardC{
            ship.encode(data: &shipStates)
        }else if key == .keyboardV{
            guard shipStates.count >= 16 else{return}
            ship.decode(data: &shipStates)
        }else if key == .keyboardBackslash{
            send(Data([127]))
            dmessage = "Disconnected :O"
            end()
            Disconnected.renderTo(skview)
        }else if key == .keyboardF3 || key == .keyboardSlash{
            if DEBUG_TXT.parent == nil{
                cam.addChild(DEBUG_TXT)
                avatar.alpha = 0.1
            }else{DEBUG_TXT.removeFromParent();avatar.alpha = 1}
        }
        if key == .keyboardSpacebar{
            if  !showAccount && !startPressed && !tapToStartPressed && children.count > MIN_NODES_TO_START{
                if !playedLightSpeedOut{
                    accountIcon.removeFromParent()
                    removeTapToStart()
                    
                    self.run(lightSpeedOut)
                    playedLightSpeedOut = true
                    //anim
                    var mov = 0.1
                    var up = 0.07
                    var stop = {}
                    let stop1 = interval(0.05){
                        mov = -sign(mov) * max(0, abs(mov) + up)
                        if(abs(mov) < 0.01){
                            return stop()
                        }
                        self.ship.xScale *= 0.99
                        self.cam.run(SKAction.moveBy(x: mov, y: 0, duration: 0.05).ease(.easeOut))
                    }
                    let stop2 = interval(0.06){
                        self.cam.run(SKAction.moveBy(x: 0, y: mov, duration: 0.06).ease(.easeOut))
                    }
                    stop = {stop1();stop2()}
                    let _ = timeout(2) {
                        up = -0.5
                        self.ship.run(.scale(to: 0.25, duration: 0.5))
                        self.startGame()
                        self.removeAction(forKey: "inLightSpeed")
                        self.inlightSpeed.removeFromParent()
                    }
                }
            }
        }
    }
    override func keyUp(_ key: UIKeyboardHIDUsage) {
        if key == .keyboardUpArrow || key == .keyboardW{
            ship.thrust = false
            if tutorialProgress == .thrust{ nextStep() }
            thrustSound.run(SKAction.sequence([
                SKAction.changeVolume(to: 0, duration: 0.2),
                SKAction.run{
                    self.thrustSound.removeFromParent()
                    self.playingThrustSound = false
                }
            ]))
            self.playingThrustSound = false
        }else if key == .keyboardRightArrow || key == .keyboardD{
            ship.thrustRight = false
            if tutorialProgress == .dpad { nextStep() }
        }else if key == .keyboardLeftArrow || key == .keyboardA{
            ship.thrustLeft = false
            if tutorialProgress == .dpad { nextStep() }
        }else if key == .keyboardDownArrow || key == .keyboardS || key == .keyboardK{
            pauseLazer()
        }else if key == .keyboardL{
            self.end()
            SKScene.transition = SKTransition.crossFade(withDuration: 1.5)
            DPlay.renderTo(skview)
            SKScene.transition = SKTransition.crossFade(withDuration: 0)
        }
    }
}
