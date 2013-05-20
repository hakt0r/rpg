path = require 'path'
fs = require 'fs'
express = require 'express'
WebSocketServer = require('ws').Server

config = http : on, port : 33451

cfgpath = path.dirname(__dirname)+'/etc/config.json'
if fs.existsSync cfgpath
  console.log "RPGBoard 0.0.1 - CONF - " + cfgpath
  config = JSON.parse fs.readFileSync cfgpath

config.root = path.dirname(__dirname)

if config.http
  console.log "RPGBoard 0.0.1 - HTTP - #{config.port} #{config.root}"
  app = express()
  app.use express.compress()
  app.listen config.port
  app.use "/", express.static(config.root)

console.log "RPGBoard 0.0.1 - WEBS - #{config.port+1}"
class MicroWSS extends WebSocketServer
  @connid : 0
  @conns : {}
  @there : (ws) -> MicroWSS.conns[ws.id] = ws
  @gone  : (id) -> delete MicroWSS.conns[id]
  constructor : (opts) ->
    super opts
    @on "connection", (ws) ->
      ws.id = MicroWSS.connid++
      ws.login = false
      ws.message = (m) -> ws.send JSON.stringify(m)
      ws.on "end",   -> MicroWSS.gone ws
      ws.on "error", -> MicroWSS.gone ws
      ws.on "message", (m) ->
        for id, sock of MicroWSS.conns
          try
            sock.send m
          catch e
            MicroWSS.gone id
      MicroWSS.there ws

new MicroWSS port : config.port + 1