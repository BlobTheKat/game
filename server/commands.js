//9
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
        player.wasDestroyed()
        return "\x1b[90m[Kicked "+player.name+" with reason '"+reason+"']"
    },
    ban(player, reason="You have been banned"){
        player = clientKeys[player]
        if(!player)return "\x1b[31mNo such player"
        player.data.ban = reason
        send(Buffer.concat([Buffer.of(127), strbuf(reason)]), player.remote)
        player.wasDestroyed()
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
