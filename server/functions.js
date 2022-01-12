//4
Object.fallback = function(a, ...b){for(let o of b)for(let i in o)if(!(i in a))a[i]=o[i]}
function strbuf(str){
  let b = Buffer.from("    "+str)
  b.writeUint32LE(b.length-4)
  return b
}
function send(buffer, ip){
  ip = ip.split(/[: ]/g)
  server.send(buffer, ip[1], ip[0])
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
BufWriter.prototype.send = function snd(remote,c,buf=this){if(buf.toBuf)buf=buf.toBuf();buf.critical&&(ship.crits[buf[1]]=buf,ship.crits[(buf[1]-3)&255]=undefined);server.send(buf,this.remote.port,this.remote.address)}
