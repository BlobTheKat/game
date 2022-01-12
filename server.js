global.fs = require('fs');
global.require = require
//1. For all files in the 'server' folder
process._ = fs.readdirSync("server").map(function(filename){
	//2. read them
	return "//\x00"+filename+"\n"+fs.readFileSync('server/' + filename).toString()
}).sort((b, a) => b.match(/^.*\n\/\/(\d+)|/)[1] - a.match(/^.*\n\/\/(\d)|/)[1]).join("\n") //3. and combine them together

let _ = new Function(process._) //4. Create a function
process._=process._.split("\n")
process._f = []
for(let i in process._){
	let a = process._[i]
	if(a = a.match(/\/\/\x00(.*)/)){
		process._f.push([a[1], i])
	}
}
//5. Disable eval
Function.prototype.constructor = function(){throw new EvalError("eval is disabled in this context")}
//eval = Function.prototype.constructor
Function.prototype.constructor.prototype = Function.prototype
Function = Function.prototype.constructor
//Clear terminal
process.stdout.write('\x1bc')

//6. Now that eval is disabled, run that function
_()
