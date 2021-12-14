process.stdout.write('\x1bc')
var PORT = 65152;
const VERSION = 1;
const SERVERCOUNT = 1n;
const crypto = require("crypto")
//client states: 0 (authed) 1 (idle) 2 (live) 3 (hidden)
var dgram = require('dgram');
var server = dgram.createSocket('udp4');
var fs = require('fs');
const PRIVATE_KEY = fs.readFileSync(".i", "utf-8")
var fetch, verify, Buf, BufWriter, TYPES
exit = process.exit
function sign(doc){
	const signer = crypto.createSign('RSA-SHA256')
	signer.write(doc)
	signer.end()
	return signer.sign(PRIVATE_KEY, 'binary')
}
try{fetch = require('node-fetch')}catch(e){
    console.log("\x1b[31m[Error]\x1b[37m To run this server, you need to install node-fetch 2.6.2. Type this in the bash shell: \x1b[m\x1b[34mnpm i node-fetch@2.6.2\x1b[m")
    process.exit(1)
}
try{({Buf, BufWriter, TYPES} = require('buf.js'))}catch(e){
    console.log("\x1b[31m[Error]\x1b[37m To run this server, you need to install buf.js. Type this in the bash shell: \x1b[m\x1b[34mnpm i buf.js\x1b[m")
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
let unsaveds = {}
setInterval(function(){
    for(a in unsaveds){
        fs.writeFileSync(a, JSON.stringify(unsaveds[a]))
    }
}, 9e5)
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
                    let resource = "none"
                    if(id & 16)richness = dat[i++] / 100
                    if(id & 32)resource = dat.slice(i + 1, i += dat[i] + 1).toString()
                    id >>= 8
                    id += id2 << 8
                    sector.planets.push(new Planet(o={radius:id,x,y,mass,spin,superhot:c,richness,resource}))
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
        sector.w = meta.w
        sector.h = meta.h
        sector.x = meta.x + meta.w / 2
        sector.y = meta.y + meta.h / 2
        sector.w2 = sector.w / 2
        sector.h2 = sector.h / 2
        let data = readfile(meta.path.replace(/^\//,""))
        data.forEach(function(item){
            if(item.id)sector.objects.push(new Asteroid(item))
            else sector.planets.push(new Planet(item))
        })
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
		this.filename = "pdata/" + (sector.x + this.x) + "_" + (sector.y + this.y) + ".json"
		let dat
		try{if(!dict.resource)throw null;dat = JSON.parse(fs.readFileSync(this.filename))}catch(e){dat = null}
		this.resource = dict.resource
		this.data = dat
	}
	toBuf(buf, id){
		if(!this.data)return
		let it = this.data.items
		buf.short(id)
		buf.int(this.last || (this.last = Date.now()/1000 - 6))
		let k = Object.keys(it).slice(0,127)
		buf.byte(k.length + (this.resource && !this.data.owner && !this.superhot ? 128 : 0))
		for(var i of k){
			buf.byte(it[i].id)
			buf.byte(it[i].lvl)
			buf.byte(it[i].cap)
			buf.byte(i)
		}
	}
}
const PI2 = Math.PI * 2
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
    toBuf(buf){
        buf.float(this.x)
        buf.float(this.y)
        buf.byte(Math.max(Math.min(127, Math.round(this.dx * FPS / 16)), -128))
        buf.byte(Math.max(Math.min(127, Math.round(this.dy * FPS / 16)), -128))
        buf.byte(Math.round(((this.z % PI2) + PI2) % PI2 * 40))
        buf.byte((this.dz * 768)&255)
        buf.short(6 + (this.id << 5))
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
let A = {toBuf(a){a.int(0);a.int(0);a.int(0);a.short(0)},updatep(){},update(){}}


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
        this.data = {}
				this.crits = []
    }
    give(amount){this.data.bal=(this.data.bal||0)+amount}
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
    ready(x, y, dx, dy, z, dz, id, thrust, w){
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
        this.range = w * w
    }
    validate(buffer){
        //let delay = -0.001 * FPS * (this.u - (this.u=Date.now()))
        let x = buffer.float()
        let y = buffer.float()
        let dx = buffer.byte() / FPS * 16
        let dy = buffer.byte() / FPS * 16
        let z = buffer.byte() / 40
        let dz = buffer.byte() / 768
        let thrust = buffer.ushort()
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
    }
    toBuf(buf, ref){
        if(performance.nodeTiming.duration - this.u._idleStart > 1000){buf.int(0);buf.int(0);buf.int(0);buf.short(0);return}
        buf.float(this.x)
        buf.float(this.y)
        buf.byte(Math.max(Math.min(127, Math.round(this.dx * FPS / 16)), -128))
        buf.byte(Math.max(Math.min(127, Math.round(this.dy * FPS / 16)), -128))
        buf.byte(Math.round(((this.z % PI2) + PI2) % PI2 * 40))
        buf.byte((this.dz * 768)&255)
        buf.short((this.thrust & 31) + (this.id << 5) + (!(this.thrust & 16) && this.shoots == ref ? 16 : 0))
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
		save(){
			let buf = Buffer.from(JSON.stringify(this.data))
			let sig = sign(buf)
			buf = Buffer.concat([Buffer.of(sig.length, sig.length >> 8), sig, buf])
			sig = Number((BigInt("0x" + this.playerid.slice(3)) % SERVERCOUNT))
			
		}
}
const bundleId = "locus.tunnelvision"
let delay
function code_func(a){this.buf[0][0]=a;return this}
function code_crit(a){this.buf[0][0]=a+128;return this}
function snd(remote,c,buf=this){if(buf.toBuf)buf=buf.toBuf();c&&(c[buf[1]]=buf,c[(buf[1]-3)&255]=undefined);server.send(buf,remote.port,remote.address,e => e && console.log(e))}
server.on('message', async function(m, remote) {
    let send = a=>server.send(a,remote.port,remote.address,e => e && console.log(e))
    let address = remote.address + ':' + remote.port
    let message = new Buf(m.buffer)
    let code = message.ubyte()
    let ship = clients.get(address)
    message.critical = 0
    if(code > 127){
        code -= 128
        message.critical = message.ubyte() + 256 //when its encoded again it will be put in the 0-255 range again
        //With this you can now reliably check if its critical without having to use a comparing operator
    }
		if(message.critical && typeof ship == "object" && ship.crits[message.critical])return send(ship.crits[message.critical])
    if(code === 0 && message.critical){
        try{
            let version = message.ushort()
            if(version < VERSION)return send(Buffer.concat([Buffer.of(127), strbuf('Please Update')]))
            let len = message.ubyte()
            let publicKeyUrl = message.str(len)
            len = message.ushort()
            let signature = Buffer.from(message.buffer(len)).toString("base64")
            len = message.ubyte()
            let salt = Buffer.from(message.buffer(len)).toString("base64")
            len = message.ubyte()
            let playerId = message.str(len)
            let timestamp = message.uint() + message.uint() * 4294967296
            len = message.ubyte()
            let name = message.str(len)
            let w = message.ushort()
            if(ship == timestamp || typeof ship == "object")return send(Buffer.of(129, message.critical, 0, 0, 0, 0, 0, 0, 0, 0))
            clients.set(address, timestamp)
            verify({publicKeyUrl, signature, salt, playerId, timestamp, bundleId}, async function(err){
                if(err && playerId){
                    send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf("Invalid identity")])))
                }else{
                    //fetch DB stuff
                    //let data = 
                    let cli = new ClientData(name, playerId, address)
                    clients.set(address, cli)
                    cli.ready(0, 0, 0, 0, 0, 0, 1, 0, w)
                    let buf = Buffer.alloc(10)
                    buf[0] = 129
                    buf[1] = message.critical
                    buf.writeUint32LE(cli.data.bal >>> 0, 2)
                    buf.writeUint16LE((cli.data.bal / 4294967296) & 65535, 6)
                    send(buf)
                }
            })
        }catch(e){
            console.log(e)
            send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf('Connection failed')])))
        }
        return
    }
    if(typeof ship != "object")return
		let r = new BufWriter()
		r.code = message.critical ? code_crit : code_func
		r.send = snd.bind(r, remote, message.critical ? ship.crits : null)
		r.byte(0)
		message.critical && r.byte(message.critical)
    delay = Math.min(Math.round(performance.nodeTiming.duration / 10 - ship.u._idleStart / 10), 255)
    try{ship.ping();msgs[code].call(ship,message,r)}catch(e){console.log(e);send(Buffer.concat([Buffer.of(127), strbuf("Bad Packet")]))}
});
let msgs = {
	3(data, res){
		res.code(4).send()
	},
	127(data, res){
		this.wasDestroyed()
	},
	10(data, res){
		let planetIndex = data.int()
		let _ = data.int()
		let planet = sector.planets[planetIndex]
		if(!planet || !planet.resource || (planet.data && planet.data.owner) || planet.superhot)return res.code(13).send()
		if(!(this.data.bal >= 10))return res.code(13).send()
		planet.data = {}
		planet.data.owner = this.playerid
		this.data.bal -= 10
		unsaveds[planet.filename] = planet.data
		res.code(11).send()
	},
	9(data, res){
		let x = data.float()
		let y = data.float()
		//magic
		let newSector = 1
		this.wasDestroyed()
	},
	5(data, res){
		this.seq++
		let a = this.rubber ? true : this.validate(data)
		let cc = data.ubyte()
		let hitc = cc & 7
		while(hitc--){
			let x = data.uint()
			let obj = sector.objects[x]
			if(!obj)continue
			if(obj instanceof ClientData && x <= sector.objects.indexOf(this))continue
			this.update(obj)
		}
		if(cc & 8){
			let x = data.uint()
			let obj = sector.objects[x]
			if(obj){
				this.shoots = obj
			}
		}
		hitc = cc >> 4
		if(hitc){
			let buf = new BufWriter()
			buf.byte(8)
			while(hitc--){
				let x = data.uint()
				let obj = sector.objects[x]
				let name = (obj && obj.name) || ""
				buf.int(x)
				buf.buffer(strbuf(name))
			}
			res.send(buf.toBuf())
		}
		
		let energy = data.int() + (data.int() << 32)
		this.data.bal = energy
		res.code(a ? 7 : 6)
		res.byte(delay)
		if(a){
			this.toBuf(res)
			this.rubber = false
		}
		for(var obj of sector.objects){
			if(obj == this)continue
			obj.toBuf(res, this)
		}
		res.send()
		if(!(this.seq % 10)){
			let buf = new BufWriter()
			if(data.critical)buf.byte(140),buf.byte(data.critical)
			else buf.byte(12)
			for(let i in sector.planets){
				let x = sector.planets[i].x - this.x
				let y = sector.planets[i].y - this.y
				if(x * x + y * y > this.range)continue
				sector.planets[i].toBuf(buf, i)
			}
			res.send(buf.toBuf())
		}
	},
	14(data, res){
		let x = data.ushort()
		let planet = sector.planets[x]
		if(!planet || planet.data.owner != this.playerid)return res.code(16).send()
		x = data.ubyte()
		if(!planet.data.items || !planet.data.items[x])return res.code(16).send()
		x = planet.data.items[x]
		if(data.length > data.i){
			//rotate
			x.rot = data.ubyte()
		}else{
			//lvlup
			if(!(this.data.bal >= 10))return res.code(16).send()
			x.lvl++
			this.data.bal -= 10
			unsaveds[planet.filename] = planet.data
		}
		res.code(15).send()
	},
	17(data, res){
		let x = data.ushort()
		let planet = sector.planets[x]
		if(!planet || !planet.data || planet.data.owner != this.playerid || !planet.data.items)return res.code(19).send()
		let earned = 0
		for(var i in planet.data.items){
			let itm = planet.data.items[i]
			if(itm.id == 0){
				earned += 1
			}
		}
		res.code(18)
		planet.last = planet.last || Math.floor(Date.now()/1000 - 6)
		let diff = Math.floor(Date.now()/1000 - planet.last)
		this.data.bal += earned * diff
		res.int((earned * diff) >>> 0)
		planet.last += diff
		unsaveds[planet.filename] = planet.data
		res.send()
	},
	20(data, res){
		let x = data.ushort()
		let planet = sector.planets[x]
		if(!planet || planet.data.owner != this.playerid)return res.code(21).send()
		x = data.ubyte()
		let i = data.ubyte()
		if((planet.data.items = planet.data.items || {})[x])return res.code(21).send()
		planet.data.items[x] = {id: i, lvl: 1, cap: 0}
		unsaveds[planet.filename] = planet.data
		res.code(22).send()
	}
}
