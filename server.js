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

const SHIP = {
	bal: 1e7, bal2: 0, gems: 1000
}

let prefixes = {
	s: 1,
	m: 60,
	h: 3600,
	d: 86400,
	K: 1000,
	M: 1000000,
	k: 1000,
	ms: 0.001,
	"%": 0.01
}

let E = {}
function fetchdata(i){
	return new Promise(r => {
		//for now we only get user data from local files
		//this is faster and more convenient than, for example, SQL or some 3rd party hosted database
		fs.readFile("users/" + i, E, function(err, dat){
			if(err)return r({}) //If no file, then send empty object
			try{
				r(JSON.parse(dat)) //send data
			}catch(_){ //we dont care about error
				r({}) //send empty object
			}
		})
	})
}


function prefixify(a){
	a = a.match(/^(-?(?:\d+\.\d*|\.?\d+)(?:e[+-]?\d+)?)([a-zA-Z%]*)$/)
	if(!a)return NaN
	return a[1] * (prefixes[a[2]] || 1)
}

Object.fallback = function(a, ...b){
	for(let o of b) for(let i in o) if(!(i in a))a[i] = o[i]
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
let clientKeys = []
let clientI = 0
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
			t[1] = t.slice(1).join(':').split("#")[0]
			if(!t[1]){i++;continue}
			t[1] = t[1].trim()
			let p = prefixify(t[1])
			if(t[1] == "true" || t[1] == "yes")t[1] = true
			else if(t[1] == "false" || t[1] == "no")t[1] = false
			else if(p == p)t[1] = p
			arr[arr.length-1][t[0]]=t[1]
			i++
		}
		i++
	}
	return arr
}
const PI256 = Math.PI / 128
let sin = Array.from({length: 256}, (_, i) => Math.sin(i * PI256))
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
		if(player=="*"){let a = [];for(let i in clientKeys)a.push(FUNCS.tp(i,x,y));return a.join("\n")}
		player = clientKeys[player]
		if(!player)return "\x1b[31mNo such player"
		player.rubber = 1
		let i
		if(i = (x.match(/.[\~\^]/)||{index:-1}).index+1)[x, y] = [x.slice(0,i), x.slice(i)]
		if(x[0] == "~")x = player.x + +x.slice(1)
		if(y[0] == "~")y = player.y + +y.slice(1)
		if(x[0] == "^" && y[0] == "^"){
			x = (+x.slice(1))/180*Math.PI - player.z
			y = +y.slice(1);
			[x, y] = [player.x + Math.sin(x) * y, player.y + Math.cos(x) * y]
		}
		player.x = +x
		player.y = +y
		return "\x1b[90m[Teleported "+player.name+" to x: "+Math.round(player.x)+" y: "+Math.round(player.y)+"]"
	},
	list(){
		let players = []
		for(var i in clientKeys){
			let cli = clientKeys[i]
			players.push(i + ": "+cli.remote+": "+cli.name+" (x: "+cli.x+", y: "+cli.y+")")
		}
		return players.join("\n")
	},
	kick(player, reason="Kicked"){
		if(player=="*"){let a = [];for(let i in clientKeys)a.push(FUNCS.kick(i,reason));return a.join("\n")}
		player = clientKeys[player]
		if(!player)return "\x1b[31mNo such player"
		send(Buffer.concat([Buffer.of(127), strbuf(reason)]), player.remote)
		return "\x1b[90m[Kicked "+player.name+" with reason '"+reason+"']"
	},
	debug(player){
		console.log(clientKeys[player] || "\x1b[31mNo such player")
	},
	freeze(player, time = Infinity){
		time-=0
		if(player=="*"){let a = [];for(let i in clientKeys)a.push(FUNCS.freeze(i,time));return a.join("\n")}
		player = clientKeys[player]
		if(!player)return "\x1b[31mNo such player"
		player.rubber = time * 10
		return time ? "\x1b[90m[Froze " + player.name + " for"+(time==Infinity?"ever":" "+time+"s")+"]" : "\x1b[90m[Unfroze "+player.name+"]"
	},
	crash(player){
		if(player=="*"){let a = [];for(let i in clientKeys)a.push(FUNCS.crash(i));return a.join("\n")}
		player = clientKeys[player]
		if(!player)return "\x1b[31mNo such player"
		player.x = NaN //Arithmetic crash
		send(Buffer.of(1), player.remote) //Early EOF crash
		player.rubber = Infinity //Force even if the client has packet loss issues
		return "\x1b[90m[Crashed " + player.name + "'s client]"
	},
	give(player, amount=0, a2=0){
		amount = +amount||0
		a2 = +a2||0
		if(player=="*"){let a = [];for(let i in clientKeys)a.push(FUNCS.give(i,amount,a2));return a.join("\n")}
		player = clientKeys[player]
		if(!player)return "\x1b[31mNo such player"
		player.give(amount, a2)
		player.rubber = 1
		return "\x1b[90m[Gave " + (amount ? "K$"+amount + (a2 ? " and R$"+a2 : "") : (a2 ? "R$" + a2 : "nothing")) + " to "+player.name+"]"
	},
	gem(player, amount=0){
		amount = +amount||0
		if(player=="*"){let a = [];for(let i in clientKeys)a.push(FUNCS.gem(i,amount));return a.join("\n")}
		player = clientKeys[player]
		if(!player)return "\x1b[31mNo such player"
		player.data.gems += amount
		player.rubber = 1
		return "\x1b[90m[Gave "+amount+" gems to "+player.name+"]"
	},
	clear(){setImmediate(console.clear);return ""}
}

function _(_){
	let __ = (_.match(/"[^"]*"|'[^']*'|\S+/g)||[]).map(a => a[0]=="'"||a[0]=='"'?a.slice(1,-1):a)
	if(__[0] && FUNCS[__[0]])return FUNCS[__[0]](...__.slice(1))
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
var ships = readfile('behaviour/ships')
var asteroids = readfile('behaviour/asteroids')
let itemMeta = readfile("behaviour/items")
let ITEMS = itemMeta.map(a => readfile("behaviour"+a.path))
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
					let resource = "name:100"
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
		//if(o.u && performance.nodeTiming.duration - o.u._idleStart > 500)continue
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
		let dat = null
		if(dict.resource)try{dat = JSON.parse(fs.readFileSync(this.filename))}catch(e){dat = null}
		this.resource = dict.resource
		this.data = dat
	}
	toBuf(buf, id, pid){
		if(!this.data)return
		let it = this.data.items
		buf.short(id)
		buf.int(this.data.last || (this.data.last = Date.now()/1000 - 6))
		buf.float(this.inbank || 0)
		buf.float(this.inbank2 || 0)
		buf.byte((this.data.name || "").length)
		buf.buffer(Buffer.from(this.data.name || ""))
		let k = Object.keys(it)
		if(k.length == 0)return buf.byte((this.data.owner ? 160 : 32) + ((!this.data.owner && !this.superhot) || this.data.owner == pid ? 64 : 0))
		buf.byte((this.data.owner ? 128 : 0) + ((!this.data.owner && !this.superhot) || this.data.owner == pid ? 64 : 0))
		buf.byte(k.length - 1)
		for(var i of k){
			if(it[i].finish * 1000 < Date.now()){
				this.collect()
				it[i].finish = undefined
				it[i].lvl++
			}
			buf.byte((it[i].finish ? 128 : 0) + it[i].id)
			buf.byte(it[i].lvl)
			buf.byte(it[i].cap)
			buf.byte(i)
			if(it[i].finish){
				buf.int(it[i].finish)
			}
		}
	}
	collect(){
		let earned = 0, cap = 0, earned2 = 0, cap2 = 0
		for(var i in this.data.items){
			let itm = this.data.items[i]
			if(itm.finish)continue
				switch(itm.id){
						case 0:
						earned += ITEMS[0][itm.lvl].persec || 0
						cap += ITEMS[0][itm.lvl].storage || 0
						break
						case 2:
						earned2 += ITEMS[2][itm.lvl].persec || 0
						cap2 += ITEMS[2][itm.lvl].storage || 0
						break
				}
		}
		this.data.last = this.data.last || Math.floor(Date.now()/1000 - 6)
		let diff = Math.floor(Date.now()/1000 - this.data.last)
		let shouldEarn = earned2 * diff
		diff -= (shouldEarn%1)/earned
		this.data.last += diff
		unsaveds[this.filename] = this.data
		this.data.inbank = Math.min(cap, (this.data.inbank || 0) + Math.round(diff * earned))
		this.data.inbank2 = Math.min(cap2, (this.data.inbank2 || 0) + Math.floor(shouldEarn))
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
		buf.short(Math.max(Math.min(32767, Math.round(this.dx * FPS)), -32768))
		buf.short(Math.max(Math.min(32767, Math.round(this.dy * FPS)), -32768))
		buf.byte(Math.round(this.z / PI256))
		buf.byte(Math.round(this.dz * 768))
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
let A = {toBuf(a){a.int(0);a.int(0);a.int(0);a.int(0)},updatep(){},update(){}}


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
		this.seq2 = 0
		this.last = 0
		this.data = {}
		this.crits = []
		clientKeys[this.i = clientI++] = this
	}
	give(amount=0, amount2=0){this.data.bal=(this.data.bal||0)+amount;this.data.bal2=(this.data.bal2||0)+amount2}
	take(amount=0,amount2=0){if(!(this.data.bal>=amount&&this.data.bal2>=amount2))return false;this.data.bal-=amount;this.data.bal2-=amount2;return true}
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
	ready(x, y, id, w){
		this.ix = sector.objects.indexOf(A)
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
		//let delay = -0.001 * FPS * (this.u - (this.u=Date.now()))
		let x = buffer.float()
		let y = buffer.float()
		let dx = buffer.short() / FPS
		let dy = buffer.short() / FPS
		let z = buffer.byte() * PI256
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
		
		let buf = Buffer.alloc(16)
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
		buf.short(Math.max(Math.min(32767, Math.round(this.dx * FPS)), -32768))
		buf.short(Math.max(Math.min(32767, Math.round(this.dy * FPS)), -32768))
		buf.byte(Math.round(this.z / PI256))
		buf.byte(Math.round(this.dz * 768))
		buf.short((this.thrust & 31) + (this.id << 5) + (!(this.thrust & 16) && this.shoots == ref ? 16 : 0))
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
		sector.objects[sector.objects.indexOf(this)]=A
		while(sector.objects[sector.objects.length-1]==A)sector.objects.pop()
		delete clientKeys[this.i]
		fs.writeFileSync("users/"+this.playerid, JSON.stringify(this.data))
	}
	save(){
		let buf = Buffer.from(JSON.stringify(this.data))
		let sig = sign(buf)
		buf = Buffer.concat([Buffer.of(sig.length, sig.length >> 8), sig, buf])
		sig = Number((BigInt("0x" + this.playerid) % SERVERCOUNT))
	}
}
const bundleId = "locus.tunnelvision"
function code_func(a){this.buf[0][0]=a;return this}
function code_crit(a){this.buf[0][0]=a+128;return this}
function snd(remote,c,buf=this){if(buf.toBuf)buf=buf.toBuf();c&&(c[buf[1]]=buf,c[(buf[1]-3)&255]=undefined);server.send(buf,remote.port,remote.address)}
server.on('message', async function(m, remote) {
	let send = a=>server.send(a,remote.port,remote.address)
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
	if(message.critical && ship && ship.crits && ship.crits[message.critical-256])return send(ship.crits[message.critical-256])
	if(code === CODE.HELLO && message.critical){if(ship === 0)return
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
			clients.set(address, 0)
			verify({publicKeyUrl, signature, salt, playerId, timestamp, bundleId}, async function(err){
				playerId = playerId.slice(3)
				if(err){
					if(timestamp > 1)return send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf("Invalid identity")])))
					playerId = playerId.toUpperCase()
				}else playerId = playerId.toLowerCase()
				//fetch DB stuff
				let cli = new ClientData(name, playerId, address)
				fetchdata(playerId).then(a => {
					Object.fallback(a, SHIP)
					cli.ready(0, 0, a.id || 1, w)
					cli.data = a
					clients.set(address, cli)
					let buf = Buffer.alloc(18)
					buf[0] = 129
					buf[1] = message.critical
					buf.writeDoubleLE(cli.data.bal || 0, 2)
					buf.writeFloatLE(cli.data.bal2 || 0, 10)
					buf.writeFloatLE(cli.data.gems || 0, 14)
					send(buf)
					cli.crits[message.critical-256] = buf
				})
			})
		}catch(e){
			console.log(e)
			send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf('Connection failed')])))
		}
		return
	}
	if(typeof ship != "object")return
	let res = new BufWriter()
	res.code = message.critical ? code_crit : code_func
	res.send = snd.bind(res, remote, message.critical ? ship.crits : null)
	res.byte(0)
	message.critical && res.byte(message.critical)
	Object.fallback(ship.data, SHIP)
	try{ship.ping();msgs[code]&&msgs[code].call(ship,message,res)}catch(e){console.log(e);send(Buffer.concat([Buffer.of(127), strbuf("Bad Packet")]))}
});



const CODE = {
	HELLO: 0,
	PING: 3,
	DISCONNECT: 127,
	PLANETBUY: 10,
	DATA: 5,
	CHANGEITEM: 14,
	COLLECT: 17,
	MAKEITEM: 20,
	SKIPBUILD: 23
}

const RESP = {
	PONG: 4,
	PLANETBUY: 11,
	DATA: 6,
	DATA2: 7,
	PLANETDATA: 12,
	CHANGEITEM: 15,
	COLLECT: 18,
	MAKEITEM: 22,
	SKIPBUILD: 24
}
const ERR = {
	PLANETBUY: 13,
	MAKEITEM: 21,
	COLLECT: 19,
	CHANGEITEM: 16,
	SKIPBUILD: 25
}
//res = response
//data = data input

function processData(data, res){
	let a = this.rubber > 0 ? (data.int(),data.int(),data.int(),data.int(),this.rubber--) : this.validate(data)
	let cc = data.ubyte()
	let hitc = cc & 7
	while(hitc--){
		let x = data.uint()
		let obj = sector.objects[x - (x <= this.ix)]
		if(!obj)continue
		if(obj instanceof ClientData && x <= sector.objects.indexOf(this))continue
		this.update(obj)
	}
	if(cc & 8){
		let x = data.uint()
		let obj = sector.objects[x - (x <= this.ix)]
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
			let obj = sector.objects[x - (x <= this.ix)]
			let name = (obj && obj.name) || ""
			buf.int(x)
			buf.buffer(strbuf(name))
		}
		res.send(buf.toBuf())
	}
	
	let energy = data.int()
	this.give(energy)
	res.code(a ? RESP.DATA2 : RESP.DATA)
	res.byte(this.seq)
	if(a){
		res.double(this.data.bal)
		res.float(this.data.bal2)
		this.toBuf(res, this)
	}
	for(var obj of sector.objects){
		if(obj == this)continue
		obj.toBuf(res, this)
	}
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
	}
}


let msgs = {
	[CODE.PING](data, res){
		res.code(RESP.PONG).send()
	},
	[CODE.DISCONNECT](data, res){
		this.wasDestroyed()
	},
	[CODE.PLANETBUY](data, res){
		const planet = sector.planets[data.int()]
		if(!planet || !planet.resource || (planet.data && planet.data.owner) || planet.superhot)return res.code(ERR.PLANETBUY).send()
		if(!this.take(10))return res.code(ERR.PLANETBUY).send()
		planet.data = {owner: this.playerid, name: this.name, items: {0: {id: 5, lvl: 1, cap: 0}}}
		unsaveds[planet.filename] = planet.data
		res.double(this.data.bal)
		res.float(this.data.bal2)
		res.code(RESP.PLANETBUY).send()
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
		let now = Date.now()
		this.last = Math.min(now + 300, Math.max(now, this.last + diff * 100))
		diff = this.last - now
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
		}else{
			//lvlup
			let item = planet.data.items[x]
			if(!item)return res.code(ERR.CHANGEITEM).send()
			let dat = ITEMS[item.id][item.lvl+1]
			if(!this.take(dat.price, dat.price2))return res.code(ERR.CHANGEITEM).send()
			planet.collect()
			item.finish = (Date.now() / 1000 + dat.time) >>> 0
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
		if((planet.data.items = planet.data.items || E)[x])return res.code(ERR.MAKEITEM).send()
		let dat = ITEMS[i][1]
		if(!this.take(dat.price, dat.price2))return res.code(ERR.MAKEITEM).send()
		planet.data.items[x] = {id: i, lvl: 0, cap: 0, finish: (Date.now() / 1000 + dat.time) >>> 0}
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
		if(!planet.data.items || !planet.data.items[x])return res.code(ERR.SKIPBUILD).send()
		let item = planet.data.items[x]
		if(!item)return res.code(ERR.SKIPBUILD).send()
		let price = Math.ceil((item.finish - Math.floor(Date.now() / 1000)) / 300)
		if(this.data.gems < price || price < 1)return res.code(ERR.SKIPBUILD).send()
		this.data.gems -= price
		planet.collect()
		item.finish = 1 //skip
		unsaveds[planet.filename] = planet.data
		res.float(this.data.gems)
		res.code(RESP.SKIPBUILD).send()
	}
}
