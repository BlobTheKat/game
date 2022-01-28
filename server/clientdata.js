//7
class ClientData extends Physics{
  constructor(name = "", id = "", remote = ""){
    super()
    this.name = name
    this.playerid = id
    this.remote = remote+""
    this.state = 0
    this.x = 0.0
    this.y = 0.0
    this.dx = 0.0
    this.dy = 0.0
    this.z = 0.0
    this.dz = 0.0
    this.thrust = 0
    this.id = 0
    this.u = null
    this.shoots = null
    this.seq = 0
    this.seq2 = 0
    this.last = 0
    this.data = {}
    this.crits = []
    clientKeys[this.i = clientI++] = this
  }
  xp(a){
    this.data.xp += Math.floor(a)
    while(this.data.xp >= this.data.lvl * 100){
      this.data.xp -= this.data.lvl * 100
      this.data.lvl++
    }
  }
  give(amount=0, amount2=0){
    this.data.bal = (this.data.bal||0) + amount
    this.data.bal2 = (this.data.bal2||0) + amount2
    this.xp(amount / 50 + amount2 / 10)
  }
  take(amount=0,amount2=0){
    if(!(this.data.bal >= amount && this.data.bal2 >= amount2))return false
    this.data.bal -= amount
    this.data.bal2 -= amount2
    this.xp(amount / 50 + amount2 / 10)
    return true
  }
  ready(x, y, id, w){
    this.ix = sector.objects.indexOf(EMPTY)
    if(this.ix == -1)this.ix = sector.objects.length
    sector.objects[this.ix] = this
    this.x = +x
    this.y = +y
    this.id = id >>> 0
    let dat = ships[this.id]
    this.radius = dat.radius
    this.mass = dat.mass
    this.speed = dat.speed
    this.spin = dat.spin
    this.state = id != 3 ? 1 : 3
    this.ping()
    this.range = w * w
  }
  validate(buffer){
    //let delay = -0.001 * FPS * (this.u - (this.u=NOW))
    let x = buffer.float()
    let y = buffer.float()
    let dx = buffer.byte() * 4
    let dy = buffer.byte() * 4
    let z = buffer.byte() * PI256
    let dz = buffer.byte() / 768
    let thrust = buffer.ushort()
    this.cosmetic = buffer.ushort()
    /*if(true){
      this.ship = (ship << 8) + level
    }
    let mult = 1
    let amult = 1
    if(thrust & 1){
      this.dx += -sin(z) * mult / 30
      this.dy += cos(z) * mult / 30
    }
    if(dx < this.dx)this.dx = dx, update = true
    if(dy < this.dy)this.dy = dy, update = true
    this.thrust = thrust & 7
    if(thrust & 4) dz -= 0.002
    if(thrust & 2) dz += 0.002
    this.x += dx
    this.y += dy
    this.z += dz
    
    let buf = Buffer.alloc(16)
    let update = 6
    if(Math.abs(this.dx - dx) < mult / 60)this.dx = dx, update--
    if(Math.abs(this.dy - dy) < mult / 60)this.dy = dy, update--
    if(Math.abs(this.x - x) < dx * 0.5)this.x = x, update--
    if(Math.abs(this.y - y) < dy * 0.5)this.y = y, update--
    if(Math.abs(this.dz - dz) < amult * 0.001)this.dz = dz, update--
    if(Math.abs(this.z - z) < dz * 0.5)this.z = z, update--
    if(!update)return this.toBuf()*/
    if(this.x || this.y){
      let d = Math.max(Math.abs(this.x - x), Math.abs(this.y - y))
      this.mission("travel", d/1000)
      this.data.stats.travel += d
    }
    this.x = x
    this.y = y
    this.z = z
    this.dx = dx
    this.dy = dy
    this.dz = dz
    this.thrust = thrust & 31
    this.id = thrust >> 5
  }
  toBuf(buf, ref){
    if(performance.nodeTiming.duration - this.u._idleStart > 1000){buf.int(0);buf.int(0);buf.int(0);buf.int(0);return}
    buf.float(this.x)
    buf.float(this.y)
    buf.byte(Math.max(Math.min(127, Math.round(this.dx / 4)), -128))
    buf.byte(Math.max(Math.min(127, Math.round(this.dy / 4)), -128))
    buf.byte(Math.round(this.z / PI256))
    buf.byte(Math.round(this.dz * 768))
    buf.short((this.thrust & 31) + (this.id << 5) + (!(this.thrust & 16) && this.shoots == ref ? 16 : 0))
    buf.short(this.cosmetic)
    if(this.shoots == ref)this.shoots = null
    return buf
  }
  ping(){
    clearTimeout(this.u)
    this.u = setTimeout(this.destroy.bind(this),5000)
  }
  destroy(){
    server.send(Buffer.concat([Buffer.of(127), strbuf('Disconnected for inactivity')]), this.remote.split(':')[1], this.remote.split(':')[0])
    this.wasDestroyed()
  }
  wasDestroyed(){
    clearTimeout(this.u)
    clients.delete(this.remote)
    sector.objects[sector.objects.indexOf(this)]=EMPTY
    while(sector.objects[sector.objects.length-1]==EMPTY)sector.objects.pop()
    delete clientKeys[this.i]
    fs.writeFileSync("users/"+this.playerid, JSON.stringify(this.data))
  }
  save(){
    let buf = Buffer.from(JSON.stringify(this.data))
    let sig = sign(buf)
    buf = Buffer.concat([Buffer.of(sig.length, sig.length >> 8), sig, buf])
    sig = Number((BigInt("0x" + this.playerid) % SERVERCOUNT))
  }
  mission(key, value){
    if(!this.data.missions)this.data.missions = {travel: 10, planets: 1, destroy: 5}
    if(!this.data.missions[key])return
    if(value >= this.data.missions[key]){
      this.data.missionlvls[key] |= 0
      let {xp, gems} = missionStats[key][this.data.missionlvls[key]]
      if(this.data.missionlvls[key] < missionStats[key].length)this.data.missionlvls[key]++
      this.xp(xp)
      this.data.gems += gems
      delete this.data.missions[key]
      
      let name = missions[Math.floor(Math.random() * missions.length)]
      while(this.data.missions[name])name = missions[Math.floor(Math.random() * missions.length)]
      this.data.missions[name] = missionStats[name][this.data.missionlvls[name]||0].amount
    }else{
      this.data.missions[key] -= value
    }
  }
}
