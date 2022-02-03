//1

//Game version
const VERSION = 2
//Number of servers
const SERVERCOUNT = 1n
//App bundle ID
const bundleId = "locus.tunnelvision"
//Helpful modules
const crypto = require("crypto")
const dgram = require('dgram')
//UDP server
const server = dgram.createSocket('udp4')

//Private key for signing userdata requests
const PRIVATE_KEY = fs.readFileSync(".i", "utf-8")

let suffixes = { //multipliers
  ms: 0.001, //millisecond
  s: 1, //second
  m: 60, //minute
  h: 3600, //hour
  d: 86400, //day
  K: 1000, //thousand
  k: 1000, //also thousand
  M: 1000000, //million
  "%": 0.01 //percent
}

const missionStats = {
  travel: readfile("behaviour/missions/travel"),
  planets: readfile("behaviour/missions/planets"),
  destroy: readfile("behaviour/missions/destroy"), //destroy asteroids
  steal: readfile("behaviour/missions/steal"), //steal (destroy) planets
  build: readfile("behaviour/missions/build"), //coloItems
  drill: readfile("behaviour/missions/drill"), //upgrade to lvl
  canon: readfile("behaviour/missions/canon"), //upgrade to lvl
  kills: readfile("behaviour/missions/kills"),
  energy: readfile("behaviour/missions/energy"),
  research: readfile("behaviour/missions/research"),
  gems: readfile("behaviour/missions/gems"),
  flybys: readfile("behaviour/missions/flybys"),
  visit: readfile("behaviour/missions/visit"),
}
let missions = Object.keys(missionStats)


const PLAYERDATA = { //Default player data
  bal: 10e6, bal2: 5000, gems: 10e3, lvl: 1, xp: 0,
  stats: {travel: 0, planets: 0},
  missions: null,
  missionlvls: {},
  adcd: 0
}

const PI256 = Math.PI / 128

//Fast trigs
const sin = Array.from({length: 256}, (_, i) => Math.sin(i * PI256))
//usage: sin[angle * PI256 & 255]
//or cos: sin[angle * PI256 + 64 & 255]

//updates every frame
let NOW = Math.floor(Date.now() / 1000)
//[string remote: ClientData]
const clients = new Map()
//[int: ClientData]
const clientKeys = []
//increment counter for clientKeys
let clientI = 0
const FPS = 60
//Gravitational constant
const G = 0.0001
//size of a REGION
const REGIONSIZE = 500000
//Object representing an object that doesn't exist (a bit like null)
const EMPTY = {toBuf(a){a.int(0);a.int(0);a.int(0);a.int(0)},updatep(thing){},update(){}}
//Sector
let sector = {objects:[],planets:[],time:0,w:0,h:0}

//behaviour files
const ships = readfile('behaviour/ships')
const asteroids = readfile('behaviour/asteroids')
const itemMeta = readfile("behaviour/items")
const ITEMS = itemMeta.map(a => readfile("behaviour"+a.path))

const damages = ships.map(ship => (ship.shootdmgs+"").split(",").map(a => +a.trim()).reduce((a, b) => a + b))

//performance variables
const {performance} = require('perf_hooks')
let lidle = performance.eventLoopUtilization().idle
let lactive = performance.eventLoopUtilization().active



//Modules that might need downloading
let fetch, verify, Buf, BufWriter, TYPES

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

try{RESPONSE = null;require('basic-repl')('$',v=>([RESPONSE,RESPONSE=null][0]||_)(v))}catch(e){
  console.log("\x1b[33m[Warning]\x1b[37m If you would like to manage this server from the console, you need to install basic-repl. Type this in the bash shell: \x1b[m\x1b[34mnpm i basic-repl\x1b[m")
}




//Unsaved planet data
const unsaveds = {}
setInterval(function(){
  for(a in unsaveds){
    fs.writeFileSync(a, JSON.stringify(unsaveds[a]))
    delete unsaveds[a]
  }
}, 3e5)
