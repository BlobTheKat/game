//5
function tick(sector){
  for(var o of sector.objects){
    if(o == EMPTY || !(o.x || o.y))continue;
    for(var p of sector.planets){
      o.updatep(p)
    }
    //if(o.u && performance.nodeTiming.duration - o.u._idleStart > 500)continue
    o.x += o.dx
    o.y += o.dy
    o.z += o.dz
  }
  sector.time++
  NOW = Math.floor(Date.now()/1000)
}

class Physics{
  update(thing){
    let d = this.x - thing.x
    let r = this.y - thing.y
    d = d * d + r * r
    r = (this.radius + thing.radius) * (this.radius + thing.radius)
    if(d >= r * 4)return
    let sum = this.mass + thing.mass
    let diff = this.mass - thing.mass
    let nvx = (this.dx * diff + (2 * thing.mass * thing.dx)) / sum
    let nvy = (this.dy * diff + (2 * thing.mass * thing.dy)) / sum
    thing.dx = ((2 * this.mass * this.dx) - thing.dx * diff) / sum
    thing.dy = ((2 * this.mass * this.dy) - thing.dy * diff) / sum
    this.dx = nvx
    this.dy = nvy
  }
  updatep(thing){
    let d = this.x - thing.x
    let r = this.y - thing.y
    d = d * d + r * r
    r = (this.radius + thing.radius) * (this.radius + thing.radius)
    let deathzone = thing.mass * thing.mass * G * G / d > this.speed * this.speed / 1000
    if((d < r && thing.superhot) || deathzone){
        if(this.respawnstate)return this.respawn()
    }
    if((Math.abs(this.x) > sector.w2 || Math.abs(this.y) > sector.h2) && this.respawnstate)return this.respawn()
    let M = thing.mass * G
    let m = Math.min(M / (16 * r) - M / d, 0)
    this.dx += (this.x - thing.x) * m
    this.dy += (this.y - thing.y) * m
    this.z += thing.dz * r / d
  }
}
