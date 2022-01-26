//4

//Like Object.assign but already-existing properties aren't overwritten
//Usage: Object.fallback(a: {...}, ...b: ...{...}) -> {...}
//Example: Object.fallback({a:1, x: 99}, {a:1,b:2,c:3}, {c: 4}) == {a: 1, b: 2, c: 4, x: 99}
Object.fallback = function(a, ...b){for(let o of b)for(let i in o){
    if(o[i] && typeof o[i] == "object"){
      if(!(i in a))a[i] = Array.isArray(o[i]) ? [] : {}
      Object.fallback(a[i], o[i])
      continue
    }
    if(!(i in a))a[i]=o[i]
};return a}
function strbuf(str){
  //Buffer of 4 empty bytes + the string
  let b = Buffer.from("    "+str)
  //Write length onto first 4 bytes
  b.writeUint32LE(b.length-4)
  return b
}
function send(buffer, ip){
  ip = ip.split(/[: ]/g)
  server.send(buffer, +ip[1], ip[0])
}
const load = () => { //calculate server load
  let usage = performance.eventLoopUtilization()
  let ac = (lactive - (lactive = usage.active))
  return ac / (lidle - (lidle = usage.idle) + ac)
}
function sign(doc){ //RSA-sign document
  const signer = crypto.createSign('RSA-SHA256')
  signer.write(doc)
  signer.end()
  return signer.sign(PRIVATE_KEY, 'binary')
}

//Works well, don't touch
BufWriter.prototype.code = function(a){this.buf[0][0]=a+(this.critical?128:0);return this}
BufWriter.prototype.send = function snd(buf=this){let c=buf.critical?buf.ship:null;if(buf.toBuf)buf=buf.toBuf();c&&(c.crits[buf[1]]=buf,c.crits[(buf[1]-3)&255]=undefined);server.send(buf,this.remote.port,this.remote.address)}
