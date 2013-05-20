// Generated by CoffeeScript 1.4.0
var MicroWSS, WebSocketServer, app, config, express, path,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

path = require('path');

express = require('express');

WebSocketServer = require('ws').Server;

config = {
  port: 8080,
  root: path.dirname(__dirname)
};

console.log("RPGBoard 0.0.1 - " + config.port + " " + config.root);

app = express();

app.use(express.compress());

app.listen(config.port);

app.use("/", express["static"](config.root));

MicroWSS = (function(_super) {

  __extends(MicroWSS, _super);

  MicroWSS.connid = 0;

  MicroWSS.conns = {};

  MicroWSS.there = function(ws) {
    return MicroWSS.conns[ws.id] = ws;
  };

  MicroWSS.gone = function(id) {
    return delete MicroWSS.conns[id];
  };

  function MicroWSS(opts) {
    MicroWSS.__super__.constructor.call(this, opts);
    this.on("connection", function(ws) {
      ws.id = MicroWSS.connid++;
      ws.login = false;
      ws.message = function(m) {
        return ws.send(JSON.stringify(m));
      };
      ws.on("end", function() {
        return MicroWSS.gone(ws);
      });
      ws.on("error", function() {
        return MicroWSS.gone(ws);
      });
      ws.on("message", function(m) {
        var id, sock, _ref, _results;
        _ref = MicroWSS.conns;
        _results = [];
        for (id in _ref) {
          sock = _ref[id];
          try {
            _results.push(sock.send(m));
          } catch (e) {
            _results.push(MicroWSS.gone(id));
          }
        }
        return _results;
      });
      return MicroWSS.there(ws);
    });
  }

  return MicroWSS;

})(WebSocketServer);

new MicroWSS({
  port: config.port + 1
});
