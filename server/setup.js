//3
//It aint broke so dont fix it
function _(_){
    let __ = (_.match(/"[^"]*"|'[^']*'|\S+/g)||[]).map(a => a[0]=="'"||a[0]=='"'?a.slice(1,-1):a)
    if(__[0] && FUNCS[__[0]])return FUNCS[__[0]](...__.slice(1))
    return eval(_)
}
let meta = (readfile('meta')||[]).find(a=>(a.port||a.ip.split(":")[1])==process.argv[2]) || null
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
        let rx = Math.floor(x / REGIONSIZE)
        let ry = Math.floor(y / REGIONSIZE)
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
            sector.time = 0
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
                server.bind(p)
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
        sector.time = 0
        let data = readfile(meta.path.replace(/^\//,""))
        data.forEach(function(item){
            if(item.id)sector.objects.push(new Asteroid(item))
            else sector.planets.push(new Planet(item))
        })
        setInterval(tick.bind(undefined, sector), 1000 / FPS)
        server.bind(meta.port || meta.ip.split(":")[1])
    })
}
