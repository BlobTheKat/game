//6
class Planet{
  constructor(dict){
    this.x = +dict.x
    this.y = +dict.y
    this.radius = dict.radius
    this.mass = dict.mass
    this.z = 0
    this.dz = dict.spin
    this.superhot = dict.superhot
    this.filename = "pdata/" + (sector.x + this.x) + "_" + (sector.y + this.y) + ".json"
    let dat = null
    if(dict.resource)try{dat = JSON.parse(fs.readFileSync(this.filename))}catch(e){dat = null}
    [this.name, this.price = 0, this.price2 = 0] = dict.resource ? dict.resource.split(":") : []
    this.price *= 1
    this.price2 *= 1
    this.data = dat
    if(this.data && this.data.health > 4095){
      this.data.health -= 4096
      this.heal()
    }
  }
  heal(){
    this.data.health += 4096
    let stop = setInterval(function(){
      this.data.health += 64
      if(this.data.health > 8190){
        stop()
        this.data.health = 4095
      }
    }, 30)
  }
  toBuf(buf, id, pid){
    if(!this.data)return
    let it = this.data.items
    buf.short(id)
    buf.int(this.data.last || (this.data.last = NOW - 60))
    buf.byte((this.data.health || 4095) >> 4)
    buf.float(this.data.inbank || 0)
    buf.float(this.data.inbank2 || 0)
    buf.byte((this.data.name || "").length + (this.data.health > 4095 ? 128 : 0))
    buf.buffer(Buffer.from(this.data.name || ""))
    let k = Object.keys(it)
    if(k.length == 0)return buf.byte((this.data.owner ? 160 : 32) + ((!this.data.owner && !this.superhot) || this.data.owner == pid ? 64 : 0))
    buf.byte((this.data.owner ? 128 : 0) + ((!this.data.owner && !this.superhot) || this.data.owner == pid ? 64 : 0))
    buf.byte(k.length - 1)
    for(var i of k){
      if(it[i].finish < NOW){
        this.collect()
        it[i].finish = undefined
        if(it[i].id < 128)it[i].lvl++
        if(it[i].id == 0)this.data.camplvl = it[i].lvl
      }
      buf.byte((it[i].finish ? 128 : 0) + it[i].id)
      buf.byte(it[i].lvl)
      buf.byte(it[i].cap)
      buf.byte(i)
      if(it[i].finish || it[i].id > 127){
        buf.int(it[i].finish || 0)
      }
    }
  }
  collect(){
    let earned = 0, cap = 0, earned2 = 0, cap2 = 0
    for(var i in this.data.items){
      let itm = this.data.items[i]
      if(itm.finish)continue
      switch(itm.id){
        case 1:
        earned += ITEMS[1][itm.lvl].persec || 0
        cap += ITEMS[1][itm.lvl].storage || 0
        break
        case 3:
        earned2 += ITEMS[3][itm.lvl].persec || 0
        cap2 += ITEMS[3][itm.lvl].storage || 0
        break
      }
    }
    this.data.last = this.data.last || Math.floor(NOW - 60)
    let diff = Math.floor(NOW - this.data.last)
    this.data.last += diff
    unsaveds[this.filename] = this.data
    this.data.inbank = Math.min(cap, (this.data.inbank || 0) + Math.round(diff * earned))
    this.data.inbank2 = Math.min(cap2, (this.data.inbank2 || 0) + Math.round(earned2 * diff))
  }
}

class Asteroid extends Physics{
  constructor(dict){
    super()
    this.x = +dict.x
    this.y = +dict.y
    this.dx = +dict.dx || 0
    this.dy = +dict.dy || 0
    this.z = 0
    this.id = +dict.id
    this.dz = asteroids[this.id].spin
    this.radius = asteroids[this.id].radius
    this.mass = asteroids[this.id].mass
    this.respawnstate = [this.x, this.y, this.dx, this.dy]
    this.health = this.mass / 10
  }
  toBuf(buf){
    buf.float(this.x)
    buf.float(this.y)
    buf.byte(Math.max(Math.min(127, Math.round(this.dx / 4)), -128))
    buf.byte(Math.max(Math.min(127, Math.round(this.dy / 4)), -128))
    buf.byte(Math.round(this.z / PI256))
    buf.byte(Math.round(this.dz * 768))
    buf.short(6 + (this.id << 5))
    buf.short(this.health * 10 >= this.mass)
    return buf
  }
  respawn(){
    this.health = this.mass / 10
    this.x = this.respawnstate[0]
    this.y = this.respawnstate[1]
    this.dx = this.respawnstate[2]
    this.dy = this.respawnstate[3]
  }
}
