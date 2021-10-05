var PORT = 65152;
const VERSION = 1;
//client states: 0 (authed) 1 (idle) 2 (live) 3 (hidden)
var dgram = require('dgram');
var server = dgram.createSocket('udp4');
var fetch
exit = process.exit
try{fetch = require('node-fetch')}catch(e){
    console.log("\x1b[31m[Error]\x1b[37m To run this server, you need to install node-fetch. Type this in the bash shell: \x1b[m\x1b[34mnpm i node-fetch@2.6.2")
    process.exit(1);
}
let clients = new Map()
let FPS = 60
let G = 0.0001
function strbuf(str){
    let b = Buffer.from("    "+str)
    b.writeUint32LE(b.length-4)
    return b
}
let {performance} = require('perf_hooks')
let lidle = performance.eventLoopUtilization().idle
let lactive = performance.eventLoopUtilization().active
let load = () => {
    let usage = performance.eventLoopUtilization()
    return (lactive - (lactive = usage.active)) / (lidle - (lidle = usage.idle))
}
async function readfile(path){
    let text = await fetch('https://aaa.blobkat.repl.co' + (path[0]=='/'?'':'/') + path).then(a=>a.text())
    if(text == "404 Not Found")return {error:"404"}
    text = text.split('\n').map(a=>a.replace(/#.*/,''))
    let i = 0
    let arr = []
    while(i < text.length){
        arr.push({})
        while(text[i]){
            let t = text[i].split(':',2)
            if(!t[1])continue
            t[1] = t[1].trim()
            if(t[1] == "true" || t[1] == "yes")t[1] = true
            else if(t[1] == "false" || t[1] == "no")t[1] = false
            else if(+t[1] == +t[1])t[1] = +t[1]
            arr[arr.length-1][t[0]]=t[1]
            i++
        }
        i++
    }
    return arr
}
let map = null
let ships = null
let sector = {objects:[],planets:[],time:0,w:0,h:0}
Promise.all([
    readfile('map').then(a=>map=a),
    readfile('asteroids').then(a=>asteroids=a),
    readfile('ships').then(a=>ships=a)
]).then(async function(){
    if(!map[process.argv[2]])console.error('\x1b[31;1mInvalid sector'),process.exit(0)
    await new Promise(r=>
    readfile(map[process.argv[2]].path).then(function(data){
        data.forEach(function(item){
            if(item.id)sector.objects.push(new Asteroid(item))
            else sector.planets.push(new Planet(item))
        })
        sector.w = map[process.argv[2]].w
        sector.h = map[process.argv[2]].h
        sector.w2 = sector.w / 2
        sector.h2 = sector.h / 2
        setInterval(tick.bind(undefined, sector), 1000 / FPS)
        r()
    }))
    server.bind(PORT)
})
server.on('listening', function() {
    console.log('\x1b[32mUDP Server listening on port 65152\x1b[m');
});
function tick(sector){
    for(var o of sector.objects){
        if(o == A)continue;
        for(var p of sector.planets){
            o.updatep(p)
        }
        if(o.u && performance.nodeTiming.duration - o.u._idleStart > 500)continue
        o.x += o.dx
        o.y += o.dy
        o.z += o.dz
    }
    sector.time++
}

class Planet{
    constructor(dict){
        this.x = +dict.x
        this.y = +dict.y
        this.radius = dict.radius
        this.mass = dict.mass
        this.z = 0
        this.dz = dict.spin
        this.superhot = dict.superhot
    }
}
class Asteroid{
    constructor(dict){
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
    }
    toBuf(buf = Buffer.alloc(20), offset = 0){
        buf.writeFloatLE(this.x,offset)
        buf.writeFloatLE(this.y,offset+4)
        buf.writeFloatLE(this.dx,offset+8)
        buf.writeFloatLE(this.dy,offset+12)
        let PI2 = Math.PI * 2
        buf[offset+16] = Math.round((this.z + PI2) % PI2 * 40)
        buf[offset+17] = this.angularVelocity * 768
        buf.writeUint16LE(6 + (this.id << 3), offset + 18)
        return buf
    }
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
        if((d < r && thing.superhot) || deathzone || Math.abs(this.x) > sector.w2 || Math.abs(this.y) > sector.h2){
            this.x = this.respawnstate[0]
            this.y = this.respawnstate[1]
            this.dx = this.respawnstate[2]
            this.dy = this.respawnstate[3]
            return
        }
        let M = thing.mass * G
        let m = Math.min(M / (16 * r) - M / d, 0)
        this.dx += (this.x - thing.x) * m
        this.dy += (this.y - thing.y) * m
        this.z += thing.dz * r / d
    }
}
let A = {toBuf(){return Buffer.alloc(20)},updatep(){},update(){}}
class ClientData{
    constructor(name = "Player", remote = ""){
        this.remote = remote+""
        this.name = name+""
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
    }
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
            //die
        }
        let M = thing.mass * G
        let m = Math.min(M / (16 * r) - M / d, 0)
        this.dx += (this.x - thing.x) * m
        this.dy += (this.y - thing.y) * m
        this.z += thing.dz * r / d
    }
    ready(x, y, dx, dy, z, dz, id, thrust){
        var i = sector.objects.indexOf(A)
        if(i != -1)sector.objects[i] = this
        else sector.objects.push(this)
        this.x = +x
        this.y = +y
        this.z = +z
        this.dx = +dx
        this.dy = +dy
        this.dz = +dz
        this.id = id >>> 0
        let dat = ships[this.id]
        this.radius = dat.radius
        this.mass = dat.mass
        this.speed = dat.speed
        this.spin = dat.spin
        this.thrust = thrust >>> 0
        this.state = id != 3 ? (dx || dy ? 2 : 1) : 3
        clearTimeout(this.u)
        this.u = setTimeout(this.destroy.bind(this),5000)
    }
    validate(buffer = Buffer()){
        //let delay = -0.001 * FPS * (this.u - (this.u=Date.now()))
        if(buffer.length < 20)return Buffer.alloc(0)
        let x = buffer.readFloatLE(0)
        let y = buffer.readFloatLE(4)
        let dx = buffer.readFloatLE(8)
        let dy = buffer.readFloatLE(12)
        let z = buffer.readInt8(16) / 40
        let dz = buffer.readInt8(17) / 768
        let thrust = buffer[18]
        let id = thrust >> 3 + buffer[19] * 32
        /*if(true){
            this.ship = (ship << 8) + level
        }
        let mult = 1
        let amult = 1
        if(thrust & 1){
            this.dx += -sin(z) * mult / 30
            this.dy += cos(z) * mult / 30
            producesParticles = true
        }
        if(dx < this.dx)this.dx = dx, update = true
        if(dy < this.dy)this.dy = dy, update = true
        this.thrust = thrust & 7
        if(thrust & 4) dz -= 0.002
        if(thrust & 2) dz += 0.002
        this.x += dx
        this.y += dy
        this.z += dz
        
        let buf = Buffer.alloc(20)
        let update = 6
        if(Math.abs(this.dx - dx) < mult / 60)this.dx = dx, update--
        if(Math.abs(this.dy - dy) < mult / 60)this.dy = dy, update--
        if(Math.abs(this.x - x) < dx * 0.5)this.x = x, update--
        if(Math.abs(this.y - y) < dy * 0.5)this.y = y, update--
        if(Math.abs(this.dz - dz) < amult * 0.001)this.dz = dz, update--
        if(Math.abs(this.z - z) < dz * 0.5)this.z = z, update--
        if(!update)return this.tobuf()*/
        this.x = x
        this.y = y
        this.z = z
        this.dx = dx
        this.dy = dy
        this.dz = dz
        this.thrust = thrust & 7
        this.id = id
        return Buffer.alloc(0)
    }
    toBuf(buf = Buffer.alloc(20), offset = 0){
        buf.writeFloatLE(this.x,offset)
        buf.writeFloatLE(this.y,offset+4)
        buf.writeFloatLE(this.dx,offset+8)
        buf.writeFloatLE(this.dy,offset+12)
        let PI2 = Math.PI * 2
        buf[offset+16] = Math.round((this.z + PI2) % PI2 * 40)
        buf[offset+17] = this.angularVelocity * 768
        buf.writeUint16LE((this.thrust & 7) + (this.id << 3), offset + 18)
        return buf
    }
    ping(){
        clearTimeout(this.u)
        this.u = setTimeout(this.destroy.bind(this),5000)
    }
    destroy(){
        server.send(Buffer.concat([Buffer.of(127), strbuf('Disconnected for inactivity')]), this.remote.split(' ')[1], this.remote.split(' ')[0], e => e && console.log(e))
        clients.delete(this.remote)
        sector.objects[sector.objects.indexOf(this)]=A
        while(sector.objects[sector.objects.length]==A)sector.objects.pop()
    }
    wasDestroyed(){
        clearTimeout(this.u)
        clients.delete(this.remote)
        sector.objects[sector.objects.indexOf(this)]=A
        while(sector.objects[sector.objects.length]==A)sector.objects.pop()
    }
}
server.on('message', function(message, remote) {
    let send = a=>server.send(a,remote.port,remote.address,e => e && console.log(e))
    let address = remote.address + ' ' + remote.port
    if(message[0] === 0){
        try{
            let version = message.readUint16LE(1)
            if(version < VERSION)return send(Buffer.of(120))
            let len = message.readUint32LE(3)
            if(len > 64)throw new RangeError()
            let name = message.subarray(7,7+len).toString()
            clients.set(address, new ClientData(name, address))
            clients.get(address).ready(0, 0, 0, 0, 0, 0, 1, 0, 0)
            send(Buffer.of(1))
        }catch(e){
            console.log(e)
            send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf('Connection failed')])))
        }
        return
    }
    if(clients.has(address))msg(message,send,address)
});

function msg(data, reply, address){
    let ship = clients.get(address)
    ship.ping()
    let delay = Math.min(Math.round(performance.nodeTiming.duration / 10 - ship.u._idleStart / 10), 255)
    if(data[0] == 3){
        reply(Buffer.of(4))
    }
    if(data[0] == 5){
        let hitc = data[21]
        if(hitc <= 10 && hitc > 0){
            let i = 22
            while(hitc--){
                let x = data.readUint32LE(i)
                let obj = sector.objects[x]
                if(!obj)continue
                if(obj instanceof ClientData && x <= sector.objects.indexOf(ship))continue
                ship.update(obj)
                i += 4
            }
        }
        let a = ship.validate(data.slice(1,21))
        let buf = Buffer.alloc(a.length ? 22 : 2)
        buf[0] = 6
        buf[1] = delay
        if(a.length){
            buf[0] = 7
            buf.writeUint32LE(a.readUint32LE(),2)
            buf.writeUint32LE(a.readUint32LE(4),6)
            buf.writeUint32LE(a.readUint32LE(8),10)
            buf.writeUint32LE(a.readUint32LE(12),14)
            buf.writeUint32LE(a.readUint32LE(16),18)
        }
        let dat = [buf]
        for(var obj of sector.objects){
            if(obj == ship)continue
            dat.push(Buffer.alloc(20))
            obj.toBuf(dat[dat.length - 1])
        }
        buf = Buffer.concat(dat)
        reply(buf)
    }
    if(data[0] == 127){
        clients.get(address).wasDestroyed()
    }
    if(data[0] == 7){
        let x = data.readFloatLE(1)
        let y = data.readFloatLE(5)
        //magic
        let newSector = 1
        console.log("destroyed >:D")
        ship.wasDestroyed()
    }
}
try{require('basic-repl')('$',_=>eval(_))}catch(e){
    console.log("\x1b[33m[Warning]\x1b[37m If you would like to manage this server from the console, you need to install basic-repl. Type this in the bash shell: \x1b[m\x1b[34mnpm i basic-repl")
}
