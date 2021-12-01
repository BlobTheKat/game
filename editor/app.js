let app = require("express")()
let fs = require("fs")
app.get("/parent/*", (req, res) => res.sendFile(__dirname.replace(/\/[^\/]+$/,"") + decodeURI(req.url.slice(7))))
app.get("/dirlist/*", (req, res) => res.end(fs.readdirSync(__dirname.replace(/\/[^\/]+$/,"") + decodeURI(req.url.slice(8))).join("\n")))
app.get("/save/:a", (req, res) => res.end(fs.writeFileSync(__dirname + "/planets/" + req.params.a, decodeURIComponent(req.query.data||""))))
app.get("/del/:a", (req, res) => res.end(fs.unlinkSync(__dirname + "/planets/" + req.params.a)))
app.get("/*", (req, res) => res.sendFile(__dirname + decodeURI(req.url)))
var server = require('http').createServer(app);
server.listen(process.argv[2]||80)