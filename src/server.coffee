path = require 'path'
express = require 'express'
WebSocketServer = require('ws').Server

config=
  port:8080
  root:path.dirname(__dirname)

console.log "RPGBoard 0.0.1 - #{config.port} #{config.root}"

app = express()
app.use express.compress()
app.listen config.port
app.use "/", express.static(config.root)

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