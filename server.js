process.stdout.write('\x1bc')
var PORT = 65152;
const VERSION = 1;
//client states: 0 (authed) 1 (idle) 2 (live) 3 (hidden)
var dgram = require('dgram');
var server = dgram.createSocket('udp4');
var fs = require('fs');
var fetch, verify
exit = process.exit
try{fetch = require('node-fetch')}catch(e){
    console.log("\x1b[31m[Error]\x1b[37m To run this server, you need to install node-fetch 2.6.2. Type this in the bash shell: \x1b[m\x1b[34mnpm i node-fetch@2.6.2\x1b[m")
    process.exit(1)
}
try{verify = require("gamecenter-identity-verifier").verify}catch(e){
    console.log("\x1b[31m[Error]\x1b[37m To run this server, you need to install gamcecenter-identity-verifier. Type this in the bash shell: \x1b[m\x1b[34mnpm i gamecenter-identity-verifier\x1b[m")
    process.exit(1)
}
let clients = new Map()
let FPS = 60
let G = 0.0001
let REGIONSIZE = 500000
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
    let ac = (lactive - (lactive = usage.active))
    return ac / (lidle - (lidle = usage.idle) + ac)
}
function readfile(path){
    let text
    try{text = fs.readFileSync(path)+''}catch(e){return null}
    text = text.split('\n').map(a=>a.replace(/#.*/,''))
    let i = 0
    let arr = []
    while(i < text.length){
        arr.push({})
        while(text[i]){
            let t = text[i].split(':')
            t[1] = t.slice(1).join(':')
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
let PI256 = 128 / Math.PI
let sin = Array.from({length: 256}, (_, i) => Math.sin(i / PI256))
sin.push()
//usage: sin[angle * PI256 & 255]
//or cos: sin[angle * PI256 + 64 & 255]

function idtoip(id,space=false){
    id = parseInt(id, 32)
    let port = id & 65535
    id = Math.floor(id / 65536)
    let a4 = id & 255
    id >>= 8
    let a3 = id & 255
    id >>= 8
    let a2 = id & 255
    id >>= 8
    let a1 = id & 255
    id >>= 8
    return a1+"."+a2+"."+a3+"."+a4+(space?" ":":")+port
}
function iptoid(ip){
    ip = ip.split(/:| /g)
    ip[0] = ip[0].split(".").reduce((a,b) => (a * 256) + (b&255), 0)
    ip = ip[0] * 65536 + (ip[1] & 65535)
    return ip.toString(32).toUpperCase()
}
function send(buffer, ip){
    ip = ip.split(/[: ]/g)
    server.send(buffer, ip[1], ip[0])
}

let FUNCS = {
    tp(player, x, y){
        player = clients.get(idtoip(player))
        if(!player)return "\x1b[33mNo such player"
        player.rubber = true
        player.x = +x
        player.y = +y
    },
    list(){
        let players = []
        for(var i in sector.objects){
            let cli = sector.objects[i]
            if(cli instanceof Asteroid)continue
            players.push(iptoid(cli.remote) + ": "+cli.remote+": "+cli.name+" (x: "+cli.x+", y: "+cli.y+")")
        }
        return players.join("\n")
    },
    kick(player, reason="Kicked"){
        player = idtoip(player)
        send(Buffer.concat([Buffer.of(127), strbuf(reason)]), player)
    }
}

function _(_){
    let __ = _.match(/\S+|"[^"]*"|'[^']*'/g).map(a => a[0]=="'"||a[0]=='"'?a.slice(1,-1):a)
    if(FUNCS[__[0]])return FUNCS[__[0]](...__.slice(1))
    return eval(_)
}
try{RESPONSE = null;require('basic-repl')('$',v=>([RESPONSE,RESPONSE=null][0]||_)(v))}catch(e){
    console.log("\x1b[33m[Warning]\x1b[37m If you would like to manage this server from the console, you need to install basic-repl. Type this in the bash shell: \x1b[m\x1b[34mnpm i basic-repl\x1b[m")
}
var ships = readfile('ships')
var asteroids = readfile('asteroids')
var sector = {objects:[],planets:[],time:0,w:0,h:0}
var meta = (readfile('meta')||[]).find(a=>(a.port||a.ip.split(":")[1])==process.argv[2]) || null
let xy = (process.argv[3]||"_NaN_NaN").slice(1).split("_").map(a=>+a)
if(xy[0] != xy[0] || xy[1] != xy[1])xy=null

if(process.argv[2] && !xy && !meta){process.exit(0)}
if(!meta || xy){
    if(typeof RESPONSE == "undefined")console.log("\x1b[31m[Error]\x1b[37m To set up this server, you need to install basic-repl. Type this in the bash shell: \x1b[m\x1b[34mnpm i basic-repl\x1b[m"),process.exit(0)
    console.log("Enter sector \x1b[33mX\x1b[m:")
    let x;
    function _w(X){
        if(+X != +X)return console.log("Enter sector \x1b[33mX\x1b[m:"),RESPONSE=_w
        x = X
        console.log("Enter sector \x1b[33mY\x1b[m:")
        RESPONSE = _v
        return '\x1b[1A'
    }
    function _v(y){
        if(+y != +y)return console.log("Enter sector \x1b[33mY\x1b[m:"),RESPONSE=_v
        //x, y
        let rx = 0//Math.floor(x / REGIONSIZE)
        let ry = 0//Math.floor(y / REGIONSIZE)
        console.log('Downloading region file...')
        let a = null
        try{
            a = fs.readFileSync('region_'+rx+'_'+ry+'.region')
        }catch(e){
        fetch('https://raw.githubusercontent.com/BlobTheKat/data/master/'+rx+'_'+ry+'.region').then(a=>a.buffer()).then(a=>{
            fs.writeFileSync('region_'+rx+'_'+ry+'.region', a)
            done(a)
        })}
        if(a)done(a)
        function done(dat){
            console.log('Parsing region')
            let sx, sy, w, h
            let i = 0
            while(true){
                sx = dat.readInt16LE(i) * 1000 + rx * REGIONSIZE;i+=2
                sy = dat.readInt16LE(i) * 1000 + ry * REGIONSIZE;i+=2
                w = dat.readUint16LE(i) * 1000;i+=2
                h = dat.readUint16LE(i) * 1000;i+=2
                if(x >= sx && x < sx + w && y >= sy && y < sy + h)break
                let len = dat.readUint32LE(i + 4)
                i += dat.readUint16LE(i) + dat.readUint16LE(i + 2) + 8
                while(len--){
                    let id = dat.readUint16LE(i)
                    let a = id & 2 ? 1 : 0
                    let b = id & 4 ? 1 : 0
                    let c = id & 8 ? 1 : 0
                    if(id & 1){
                        i += 10 + (b + c) * 4 + a * 2
                    }else{
                        i += b * 4 + a * 2 + 15
                        i += dat[i] + (id & 16 ? 2 : 1)
                        i += id & 32 ? dat[i] + 1 : 0
                    }
                }
            }
            sector.x = sx + w / 2
            sector.y = sy + h / 2
            sector.w = w
            sector.h = h
            sector.w2 = w / 2
            sector.h2 = h / 2
            let len = dat.readUint32LE(i + 4)
            i += dat.readUint16LE(i) + dat.readUint16LE(i + 2) + 8
            let arr = []
            while(len--){
                let id = dat.readUint16LE(i);i+=2
                let a = id & 2 ? 1 : 0
                let b = id & 4 ? 1 : 0
                let c = id & 8 ? 1 : 0
                let o
                if(id & 1){
                    let x = dat.readInt32LE(i);i += 4
                    let y = dat.readInt32LE(i);i += 4
                    let dx = 0
                    let dy = 0
                    if(a)i += 2
                    if(b)dx = dat.readFloatLE(i),i += 4
                    if(c)dy = dat.readFloatLE(i),i += 4
                    id >>= 4
                    sector.objects.push(new Asteroid(o={id,x,y,dx,dy}))
                }else{
                    let id2 = dat[i++]
                    let x = dat.readInt32LE(i);i += 4
                    let y = dat.readInt32LE(i);i += 4
                    let mass = dat.readInt32LE(i);i += 4
                    let spin = 0
                    if(a)i += 2
                    if(b)spin = dat.readFloatLE(i),i += 4
                    i += dat[i] + 1
                    let richness = 0.1
                    if(id & 16)richness = dat[i++] / 100
                    if(id & 32)i += dat[i] + 1
                    id >>= 8
                    id += id2 << 8
                    sector.planets.push(new Planet(o={radius:id,x,y,mass,spin,superhot:c,richness}))
                }
                arr.push(o)
            }
            console.log("Done! Enter \x1b[33mPORT\x1b[m:")
            let _u = function(p){
                if(+p != +p || p > 65535 || p < 0)return console.log("Enter \x1b[33mPORT\x1b[m:"), RESPONSE = _u
                let name = (meta && meta.path.replace(/^\//,"")) || 'sectors/sector_'+Math.round(sx/1000)+'_'+Math.round(sx/1000)
                fs.writeFileSync(name, arr.map(a=>Object.entries(a).map(a=>a.join(': ')).join('\n')).join('\n\n'))
                if(xy)return process.exit(0)
                fs.writeFileSync('meta', 'x: '+sx+'\ny: '+sy+'\nw: '+w+'\nh: '+h+'\nport: '+p+'\npath: '+name)
                setInterval(tick.bind(undefined, sector), 1000 / FPS)
                server.bind(PORT)
            }
            let p = process.argv[2]
            if(xy && +p == +p && p <= 65535 && p >= 0)_u(p);
            else if(xy)throw new Error('Invalid port')
            else RESPONSE = _u
            
        }
        return '\x1b[1A'
    }
    RESPONSE = _w
    if(xy)setImmediate(a=>(RESPONSE(xy[0]),RESPONSE(xy[1]),RESPONSE=null))
}else{
    setImmediate(function(){
        let data = readfile(meta.path.replace(/^\//,""))
        data.forEach(function(item){
            if(item.id)sector.objects.push(new Asteroid(item))
            else sector.planets.push(new Planet(item))
        })
        sector.w = meta.w
        sector.h = meta.h
        sector.x = meta.x + meta.w / 2
        sector.y = meta.y + meta.h / 2
        sector.w2 = sector.w / 2
        sector.h2 = sector.h / 2
        setInterval(tick.bind(undefined, sector), 1000 / FPS)
        server.bind(meta.port || meta.ip.split(":")[1] || PORT)
    })
}
server.on('listening', function() {
    console.log('\x1b[32mUDP Server listening on port '+(server.address().port)+'\x1b[m');
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
    toBuf(buf = Buffer.alloc(14), offset = 0){
        buf.writeFloatLE(this.x,offset)
        buf.writeFloatLE(this.y,offset+4)
        buf.writeInt8(Math.max(Math.min(127, Math.round(this.dx * FPS / 16)), -128),offset+8)
        buf.writeInt8(Math.max(Math.min(127, Math.round(this.dy * FPS / 16)), -128),offset+9)
        let PI2 = Math.PI * 2
        buf[offset+10] = Math.round(((this.z % PI2) + PI2) % PI2 * 40)
        buf.writeUInt8((this.dz * 768)&255, offset+11)
        buf.writeUint16LE(6 + (this.id << 5), offset + 12)
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
let A = {toBuf(){return Buffer.alloc(14)},updatep(){},update(){}}
class ClientData{
    constructor(name = "", id = "", remote = ""){
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
    ready(x, y, dx, dy, z, dz, id, thrust, w, h){
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
        this.ping()
    }
    validate(buffer = Buffer()){
        //let delay = -0.001 * FPS * (this.u - (this.u=Date.now()))
        if(buffer.length < 14)return Buffer.alloc(0)
        let x = buffer.readFloatLE(0)
        let y = buffer.readFloatLE(4)
        let dx = buffer.readInt8(8) / FPS * 16
        let dy = buffer.readInt8(9) / FPS * 16
        let z = buffer.readInt8(10) / 40
        let dz = buffer.readInt8(11) / 768
        let thrust = buffer.readUint16LE(12)
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
        
        let buf = Buffer.alloc(14)
        let update = 6
        if(Math.abs(this.dx - dx) < mult / 60)this.dx = dx, update--
        if(Math.abs(this.dy - dy) < mult / 60)this.dy = dy, update--
        if(Math.abs(this.x - x) < dx * 0.5)this.x = x, update--
        if(Math.abs(this.y - y) < dy * 0.5)this.y = y, update--
        if(Math.abs(this.dz - dz) < amult * 0.001)this.dz = dz, update--
        if(Math.abs(this.z - z) < dz * 0.5)this.z = z, update--
        if(!update)return this.toBuf()*/
        this.x = x
        this.y = y
        this.z = z
        this.dx = dx
        this.dy = dy
        this.dz = dz
        this.thrust = thrust & 31
        this.id = thrust >> 5
        return
    }
    toBuf(buf = Buffer.alloc(14), offset = 0, ref){
        if(performance.nodeTiming.duration - this.u._idleStart > 1000){return}
        buf.writeFloatLE(this.x,offset)
        buf.writeFloatLE(this.y,offset+4)
        buf.writeInt8(Math.max(Math.min(127, Math.round(this.dx * FPS / 16)), -128),offset+8)
        buf.writeInt8(Math.max(Math.min(127, Math.round(this.dy * FPS / 16)), -128),offset+9)
        let PI2 = Math.PI * 2
        buf[offset+10] = Math.round(((this.z % PI2) + PI2) % PI2 * 40)
        buf.writeUInt8((this.dz * 768)&255, offset+11)
        if(this.thrust & 24)console.log(this.thrust&31)
        buf.writeUint16LE((this.thrust & 31) + (this.id << 5) + (!(this.thrust & 16) && this.shoots == ref ? 16 : 0), offset + 12)
        if(this.shoots == ref)this.shoots = null
        return buf
    }
    ping(){
        clearTimeout(this.u)
        this.u = setTimeout(this.destroy.bind(this),5000)
    }
    destroy(){
        server.send(Buffer.concat([Buffer.of(127), strbuf('Disconnected for inactivity')]), this.remote.split(':')[1], this.remote.split(':')[0], e => e && console.log(e))
        this.wasDestroyed()
        
    }
    wasDestroyed(){
        clearTimeout(this.u)
        clients.delete(this.remote)
        sector.objects[sector.objects.indexOf(this)]=A
        while(sector.objects[sector.objects.length-1]==A)sector.objects.pop()
    }
}
const bundleId = "locus.tunnelvision"
server.on('message', async function(message, remote) {
    let send = a=>server.send(a,remote.port,remote.address,e => e && console.log(e))
    let address = remote.address + ':' + remote.port
    if(message[0] === 0){
        try{
            let version = message.readUint16LE(1)
            if(version < VERSION)return send(Buffer.of(120))
            let i
            let len = message.readUint8(3)
            let publicKeyUrl = message.subarray(4,i = 4 + len).toString()
            len = message.readUint16LE(i),i += 2
            let signature = message.subarray(i, i += len).toString("base64")
            len = message.readUint8(i++)
            let salt = message.subarray(i, i += len).toString("base64")
            len = message.readUint8(i++)
            let playerId = message.subarray(i, i += len).toString()
            let timestamp = message.readUint32LE(i) + message.readUint32LE(i + 4, void(i += 8)) * 4294967296
            len = message.readUint8(i++)
            let name = message.subarray(i, i += len).toString()
            let w = message.readUint16LE(i),i += 2
            let h = message.readUint16LE(i),i += 2
            if(clients.get(address) == timestamp || typeof clients.get(address) == "object")return send(Buffer.of(1))
            clients.set(address, timestamp)
            verify({publicKeyUrl, signature, salt, playerId, timestamp, bundleId}, async function(err){
                if(err && playerId){
                    send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf("Invalid identity")])))
                }else{
                    //fetch DB stuff
                    //let data = 
                    let cli = new ClientData(name, playerId, address)
                    clients.set(address, cli)
                    cli.ready(0, 0, 0, 0, 0, 0, 1, 0, w, h)
                    send(Buffer.of(1))
                }
            })
        }catch(e){
            send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf('Connection failed')])))
        }
        return
    }
    
    if(typeof clients.get(address) == "object")try{msg(message,send,address)}catch(e){console.log(e);send(Buffer.concat([Buffer.of(127), strbuf("Corrupt Packet")]))}
});

function msg(data, reply, address){
    let ship = clients.get(address)
    let delay = Math.min(Math.round(performance.nodeTiming.duration / 10 - ship.u._idleStart / 10), 255)
    ship.ping()
    if(data[0] == 3){
        reply(Buffer.of(4))
    }else if(data[0] == 5){
        ship.seq++
        let cc = data[15]
        let hitc = cc & 7
        let i = 16
        while(hitc--){
            let x = data.readUint32LE(i)
            let obj = sector.objects[x]
            if(!obj)continue
            if(obj instanceof ClientData && x <= sector.objects.indexOf(ship))continue
            ship.update(obj)
            i += 4
        }
        if(cc & 8){
            let x = data.readUint32LE(i)
            let obj = sector.objects[x]
            if(obj){
                ship.shoots = obj
            }
            i += 4
        }
        hitc = cc >> 4
        if(hitc){
            let buf = [Buffer.of(8)]
            while(hitc--){
                let x = data.readUint32LE(i)
                let obj = sector.objects[x]
                let name = (obj && obj.name) || ""
                buf.push(Buffer.alloc(4))
                buf[buf.length - 1].writeUint32LE(x)
                buf.push(strbuf(name))
                i += 4
            }
            reply(Buffer.concat(buf))
        }
        let a = ship.rubber ? true : ship.validate(data.slice(1,15))
        let buf = Buffer.alloc(a ? 16 : 2)
        buf[0] = 6
        buf[1] = delay
        if(a){
            buf[0] = 7
            ship.toBuf(buf,2)
            ship.rubber = false
        }
        let dat = [buf]
        for(var obj of sector.objects){
            if(obj == ship)continue
            dat.push(Buffer.alloc(14))
            obj.toBuf(dat[dat.length - 1], 0, ship)
        }
        buf = Buffer.concat(dat)
        reply(buf)
        
        if(!(ship.seq % 10)){
            
        }
    }else if(data[0] == 127){
        clients.get(address).wasDestroyed()
    }else if(data[0] == 9){
        let x = data.readFloatLE(1)
        let y = data.readFloatLE(5)
        //magic
        let newSector = 1
        ship.wasDestroyed()
    }else if(data[0] == 10){
        let planetIndex = data.readUint32LE(1)
        let planetLvl = data.readUint32LE(5)
        let planet = sector.planets[planetIndex]
        if(!planet){return}
        
        //magic
        
        let data = Buffer.alloc(5)
        data[0] = 11
        data.writeUint32LE(planetLvl)
        reply(data)
    }else reply(Buffer.concat([[127], strbuf("Illegal Packet")]))
}
