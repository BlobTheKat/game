//2

//Fetch user data
//usage: fetchdata(id: string): Promise<Object>
//example: let userdata = await fetchdata(playerId)
function fetchdata(id){
  return new Promise(r => {
    //for now we only get user data from local files
    //this is faster and more convenient than, for example, SQL or some 3rd party hosted database
    fs.readFile("users/" + id, {}, function(err, dat){
      if(err)return r({}) //If no file, then send empty object
      try{
        r(JSON.parse(dat)) //send data
      }catch(_){ //we dont care about error
        r({}) //send empty object
      }
    })
  })
}
//Read GameData file
//example: let ships = readfile("behaviour/ships")
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
      let p = suffixify(t[1])
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


//usage: suffixify(str: string): number
//example: suffixify("30m") == 1800
function suffixify(str){
  let m = str.match(/^(-?(?:\d+\.\d*|\.?\d+)(?:e[+-]?\d+)?)([a-zA-Z%]*)$/)
  if(!m)return NaN
  return m[1] * (suffixes[m[2]] || 1)
}
