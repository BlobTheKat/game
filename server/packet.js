//10
//res = response
//data = data input

const STATSOBJ = {travel: TYPES.FLOAT, planets: TYPES.USHORT}
function processData(data, res){
    let rubber = this.rubber > 0 ? (data.int(),data.int(),data.int(),data.int(),this.rubber--) : this.validate(data)
    let bitfield = data.ubyte()
    let hitc = bitfield & 7
    while(hitc--){
        let x = data.uint()
        this.dx = data.float()
        this.dy = data.float()
        let obj = sector.objects[x - (x <= this.ix)]
        if(!obj)continue
        if(obj instanceof ClientData && x <= sector.objects.indexOf(this))continue
        this.update(obj)
    }
    if(bitfield & 8){
        let x = data.uint()
        let obj = sector.objects[x - (x <= this.ix)]
        if(obj){
            this.shoots = obj
            if(obj instanceof Asteroid)if((obj.health -= damages[this.id]) <= 0){
                this.mission("destroy", 1)
                obj.respawn()
            }
        }
    }
    hitc = (bitfield >> 4) & 7
    if(hitc){
        let buf = new BufWriter()
        buf.byte(8)
        while(hitc--){
            let x = data.uint()
            let obj = sector.objects[x - (x <= this.ix)]
            let name = (obj && obj.name) || ""
            buf.int(x)
            buf.buffer(strbuf(name))
        }
        res.send(buf.toBuf())
    }
    
    if(bitfield & 128){
        //planet shot
        let p = sector.planets[data.ushort()]
        if(p && !(this.seq & 3) && p.data && p.data.owner && !(p.data.health > 4095)){
            p.data.health = (p.data.health || 4095) - 25
            if(p.data.health < 1){
                //destroyed
                p.data.health = 2048
                //TODO: remove 1 from planet stats of old owner
                p.data.owner = this.playerid
                p.data.name = this.name
                this.mission("steal", 1)
                p.collect()
                p.inbank = Math.floor((p.inbank || 0) / 2)
                p.inbank2 = Math.floor((p.inbank2 || 0) / 2)
                for(let i in p.data.items){
                    if(p.data.items[i].finish){
                        p.data.items[i].lvl++
                        p.data.items[i].finish = undefined
                    }
                    if(p.data.items[i].id < 128)p.data.items[i].id += 128
                }
            }
        }
    }
    
    let energy = data.int()
		this.mission("energy", energy)
    this.xp(energy / 10)
    this.give(energy)
    res.code(rubber ? RESP.DATA2 : RESP.DATA)
    res.byte(this.seq)
    if(rubber){
        res.double(this.data.bal)
        res.float(this.data.bal2)
        this.toBuf(res, this)
    }
    for(let obj of sector.objects){
        if(obj == this)continue
        obj.toBuf(res, this)
    }
    res.short(this.data.lvl)
    res.short(this.data.xp)
    res.send()
    if(!(this.seq % 10)){
        let buf = new BufWriter()
        if(data.critical)buf.byte(140),buf.byte(data.critical)
        else buf.byte(RESP.PLANETDATA)
        for(let i in sector.planets){
            let x = sector.planets[i].x - this.x
            let y = sector.planets[i].y - this.y
            if(x * x + y * y > this.range)continue
            sector.planets[i].toBuf(buf, i, this.playerid)
        }
        res.send(buf.toBuf())
        buf = new BufWriter()
        buf.byte(2)
        buf.obj(STATSOBJ, this.data.stats)
        buf.float(this.data.gems)
        for(let i in this.data.missions){
            buf.str(i)
            buf.byte(this.data.missionlvls[i])
            buf.float(this.data.missions[i])
        }
        buf.byte(0)
        res.send(buf.toBuf())
        
    }
}
let msgs = {
    [CODE.ADWATCHED](data, res){
        if(this.data.adcd > NOW){
            return res.code(RESP.ADWATCHED).send()
        }
        this.data.adcd = Math.max(NOW - 86400, this.data.adcd) + 21600
        this.data.gems += 5
        res.code(RESP.ADWATCHED)
        res.float(this.data.gems)
        res.float(this.data.adcd - NOW)
        res.send()
    },
    [CODE.PING](data, res){
        res.code(RESP.PONG).send()
    },
    [CODE.DISCONNECT](data, res){
        this.wasDestroyed()
    },
    [CODE.PLANETBUY](data, res){
        const planet = sector.planets[data.int()]
        if(!planet || !planet.name || (planet.data && planet.data.owner) || planet.superhot)return res.code(ERR.PLANETBUY).send()
        if(!this.take(planet.price, planet.price2))return res.code(ERR.PLANETBUY).send()
        planet.data = {owner: this.playerid, name: this.name, items: {0: {id: 0, lvl: 1, cap: 0}}, health: 4095, camplvl: 1}
        unsaveds[planet.filename] = planet.data
        this.mission("planets", 1)
        res.double(this.data.bal)
        res.float(this.data.bal2)
        res.code(RESP.PLANETBUY).send()
        this.data.stats.planets++
    },
    [CODE.MOVESECTOR](data, res){
        let x = data.float()
        let y = data.float()
        //magic
        
        let newSector = 1
        this.wasDestroyed()
    },
    [CODE.DATA](data, res){
        if(this.id == 0)this.id = 1
        this.seq++
        let seq2 = data.byte() + (this.seq2 & -256)
        if(seq2 < this.seq2)seq2 += 256
        let diff = seq2 - this.seq2
        if(diff > 127)return
        this.seq2 = seq2
        this.last = Math.min(NOW*1000 + 300, Math.max(NOW, this.last + diff * 100))
        diff = this.last - NOW*1000
        if(diff <= 0)processData.call(this, data, res)
        else setTimeout(processData.bind(this, data, res), diff - 2)
    },
    [CODE.CHANGEITEM](data, res){
        let x = data.ushort()
        let planet = sector.planets[x]
        if(!planet || !planet.data || planet.data.owner != this.playerid)return res.code(ERR.CHANGEITEM).send()
        x = data.ubyte()
        if(!planet.data.items || !planet.data.items[x])return res.code(ERR.CHANGEITEM).send()
        if(data.length > data.i){
            //rotate
            let y = data.ubyte()
            if(planet.data.items[y])return res.code(ERR.CHANGEITEM).send()
            planet.data.items[y] = planet.data.items[x]
            delete planet.data.items[x]
            if(planet.data.items[y].id == 0)planet.data.camp = y
        }else{
            //lvlup
            let item = planet.data.items[x]
            if(!item)return res.code(ERR.CHANGEITEM).send()
            let dat = ITEMS[item.id][item.lvl+1]
            if(!dat)return res.code(ERR.CHANGEITEM).send()
            if(item.lvl >= (planet.data.camplvl - ITEMS[item.id][0].available) + 1)return res.code(ERR.CHANGEITEM).send()
            if(!this.take(dat.price, dat.price2))return res.code(ERR.CHANGEITEM).send()
            if(item.id===1)this.mission("drill", 1)
            if(item.id===2)this.mission("canon",1)
            planet.collect()
            item.finish = (NOW + dat.time) >>> 0
            unsaveds[planet.filename] = planet.data
        }
        res.double(this.data.bal)
        res.float(this.data.bal2)
        res.code(RESP.CHANGEITEM).send()
    },
    [CODE.COLLECT](data, res){
        let planet = sector.planets[data.ushort()]
        if(!planet || !planet.data || planet.data.owner != this.playerid || !planet.data.items)return res.code(ERR.COLLECT).send()
        planet.data.name = this.name
        res.code(RESP.COLLECT)
        planet.collect()
        this.mission("energy", planet.data.inbank) //resourse balance
        this.mission("research", planet.data.inbank2) //research balance
        this.data.bal += planet.data.inbank
        this.data.bal2 += planet.data.inbank2
        res.double(this.data.bal)
        res.float(this.data.bal2)
        planet.data.inbank = 0
        planet.data.inbank2 = 0
        res.send()
    },
    //Add an item to planet
    [CODE.MAKEITEM](data, res){
        let planet = sector.planets[data.ushort()]
        if(!planet || planet.data.owner != this.playerid)return res.code(ERR.MAKEITEM).send()
        let x = data.ubyte()
        let i = data.ubyte()
        if(!i || (planet.data.items = planet.data.items || {})[x])return res.code(ERR.MAKEITEM).send()
        let num = 0
        for(itm in planet.data.items)if(planet.data.items[itm].id == i)num++
        if(num >= (planet.data.camplvl - ITEMS[i][0].available)/ITEMS[i][0].every + 1)return res.code(ERR.MAKEITEM).send()
        let dat = ITEMS[i][1]
        if(!this.take(dat.price, dat.price2))return res.code(ERR.MAKEITEM).send()
				this.mission("build", 1)
        planet.data.items[x] = {id: i, lvl: 0, cap: 0, finish: (NOW + dat.time) >>> 0}
        unsaveds[planet.filename] = planet.data
        res.double(this.data.bal)
        res.float(this.data.bal2)
        res.code(RESP.MAKEITEM).send()
    },
    [CODE.SKIPBUILD](data, res){
        let x = data.ushort()
        let planet = sector.planets[x]
        if(!planet || !planet.data || planet.data.owner != this.playerid)return res.code(ERR.SKIPBUILD).send()
        x = data.ubyte()
        if(!planet.data.items || !planet.data.items[x] || !planet.data.items[x].finish)return res.code(ERR.SKIPBUILD).send()
        let item = planet.data.items[x]
        let price = Math.ceil((item.finish - NOW) / 300)
        if(this.data.gems < price || price < 1)return res.code(ERR.SKIPBUILD).send()
        this.data.gems -= price
        planet.collect()
        item.finish = 1 //skip
        unsaveds[planet.filename] = planet.data
        res.float(this.data.gems)
        res.code(RESP.SKIPBUILD).send()
    },
    [CODE.REPAIR](data, res){
        let x = data.ushort()
        let planet = sector.planets[x]
        if(!planet || !planet.data || planet.data.owner != this.playerid)return res.code(ERR.REPAIR).send()
        x = data.ubyte()
        if(!planet.data.items || !planet.data.items[x] || planet.data.items[x].id < 128)return res.code(ERR.REPAIR).send()
        let item = planet.data.items[x]
        let {price, price2, time} = ITEMS[item.id-128][item.lvl]
        if(!this.take((price||0) * 1.5, (price2||0) * 1.5))return res.code(ERR.REPAIR).send()
        item.id -= 128
        item.lvl--
        item.finish = Math.floor(NOW + (time || 0) * 0.5)
        unsaveds[planet.filename] = planet.data
        res.double(this.data.bal)
        res.float(this.data.bal2)
        res.code(RESP.REPAIR).send()
    },
    [CODE.RESTORE](data, res){
        let x = data.ushort()
        let planet = sector.planets[x]
        if(!planet || !planet.data || planet.data.owner != this.playerid)return res.code(ERR.RESTORE).send()
        if(planet.data.health > 4095)return
        if(!this.take(Math.floor(10000 - (planet.data.health>>4)*39.0625)))return res.code(ERR.RESTORE).send()
        planet.heal()
        unsaveds[planet.filename] = planet.data
        res.double(this.data.bal)
        res.code(RESP.RESTORE).send()
    }
}
