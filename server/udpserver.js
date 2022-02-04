//8
server.on('listening', function() {
    console.log('\x1b[32mUDP Server listening on port '+(server.address().port)+'\x1b[m');
})

server.on('message', async function(m, remote) {
    let message = new Buf(m.buffer)
    let send = data => server.send(data,remote.port,remote.address)
    let address = remote.address + ':' + remote.port
    let code = message.ubyte()
    //Get ship from map
    let ship = clients.get(address)
    message.critical = 0
    if(code > 127){
        code -= 128
        message.critical = message.ubyte() + 256 //when its encoded again it will be put in the 0-255 range again
        //With this you can now reliably check if its critical without having to use a comparing operator
    }
    //If it's a critical and we already recieved it
    if(message.critical && ship && ship.crits && ship.crits[message.critical-256])return send(ship.crits[message.critical-256])
    if(code === CODE.HELLO && message.critical){if(ship === 0)return
        //Auth packet
        try{
            let version = message.ushort()
            if(version < VERSION)return send(Buffer.concat([Buffer.of(127), strbuf('Please Update')]))
            //sig, salt, url, id, ...
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
            //w = width of their screen
            let w = Math.min(4000, message.ushort())
            clients.set(address, 0)
            let err = await new Promise(r => verify({publicKeyUrl, signature, salt, playerId, timestamp, bundleId}, r))
            if(err){
                //if(notGuest)
                if(timestamp > 1)return send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf("Invalid identity")])))
                //is guest, uppercase
                playerId = "1" + playerId.toLowerCase()
            }else playerId = playerId.slice(3).toLowerCase() //not guest, lowercase
            //fetch DB stuff
            let cli = new ClientData(name, playerId, address)
            fetchdata(playerId).then(a => {
                Object.fallback(a, PLAYERDATA)
                cli.ready(0, 0, 0, w)
                cli.data = a
                clients.set(address, cli)
                let buf = Buffer.alloc(22 + Math.ceil(sector.planets.length / 8))
                buf[0] = 129
                buf[1] = message.critical
                buf.writeDoubleLE(cli.data.bal || 0, 2)
                buf.writeFloatLE(cli.data.bal2 || 0, 10)
                buf.writeFloatLE(cli.data.gems || 0, 14)
                buf.writeFloatLE(cli.data.adcd - NOW, 18)
                let b = 1, i = 22
                for(let p of sector.planets){
                    b <<= 1
                    if(p.data && p.data.owner == cli.playerid)b ^= 1
                    if(b > 255){
                        buf[i++] = b
                        b = 1
                    }
                }
                while(b < 255)b <<= 1
                buf[i++] = b
                send(buf)
                cli.crits[message.critical-256] = buf
            })
        }catch(e){
            console.log(e)
            send(Buffer.from(Buffer.concat([Buffer.of(127), strbuf('Connection failed')])))
        }
        return
    }
    if(typeof ship != "object")return
    let res = new BufWriter()
    res.remote = remote
    res.ship = ship
    res.critical = message.critical
    res.byte(0)
    message.critical && res.byte(message.critical)
    Object.fallback(ship.data, PLAYERDATA)
    try{ship.ping();msgs[code]&&msgs[code].call(ship,message,res)}catch(e){
			let msg = "\x1b[31m"+e.name+": "+e.message
			let m = ""
			e.stack.replace(/<anonymous>:(\d+):(\d+)/g,(_,line,pos)=>{
				msg += m
				line -= 2
				m = process.linesOfCode[line-1]
				m = "\x1b[;37m"+m.slice(0,pos-1).trim() + "\x1b[33;4m" + m.slice(pos-1).match(/(\w*)(.*)/).slice(1).join("\x1b[m\x1b[37m")
				let name = "", l = 0
				for(let i of process.fileIndex){
					if(i[1] > line)break
					name = i[0]
                    l = i[1]
				}
				m = "\n\x1b[34;4m" + name + ":" + (line-l) + ":" + pos + "\n" + m
			});
			console.log(msg)
			send(Buffer.concat([Buffer.of(127), strbuf("Bad Packet")]))}
});


//Codes
const CODE = {
    HELLO: 0,
    PING: 3,
    DISCONNECT: 127,
    PLANETBUY: 10,
    DATA: 5,
    CHANGEITEM: 14,
    COLLECT: 17,
    MAKEITEM: 20,
    SKIPBUILD: 23,
    REPAIR: 26,
    RESTORE: 29,
    ADWATCHED: 125
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
    SKIPBUILD: 24,
    REPAIR: 27,
    RESTORE: 30,
    ADWATCHED: 126
}
const ERR = {
    PLANETBUY: 13,
    MAKEITEM: 21,
    COLLECT: 19,
    CHANGEITEM: 16,
    SKIPBUILD: 25,
    REPAIR: 28,
    RESTORE: 31,
}

