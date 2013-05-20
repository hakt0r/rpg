// Generated by CoffeeScript 1.4.0
var RPGApi,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

RPGApi = (function() {

  RPGApi.prototype.rules = {};

  RPGApi.prototype.dialog = function(opts) {
    var co, ctx, id;
    if (Api.lastItemId == null) {
      Api.lastItemId = 0;
    }
    id = Api.lastItemId++;
    co = $("body");
    ctx = {};
    co.append("<div class=\"barrier\"></div>");
    ctx.ba = co.find("> .barrier").last();
    co.append(opts.src);
    ctx.frame = co.find("> *").last();
    ctx.frame.attr("id", id);
    ctx.frame.addClass("wg");
    ctx.destroy = function() {
      ctx.frame.replaceWith("");
      return ctx.ba.replaceWith("");
    };
    ctx.frame.find(".close").on("click", function() {
      return ctx.destroy();
    });
    return opts.init.call(ctx);
  };

  RPGApi.prototype.notice = function(text, time) {
    var notice;
    Api.notice.time = time != null ? time : 1;
    notice = $("#notice");
    notice.css("display", "block");
    notice.html(text);
    notice.effect("highlight", {
      color: "#0F0"
    }, 100);
    Api.notice.timeout = Date.now() / 1000;
    if (Api.notice.check == null) {
      return Api.notice.check = setInterval(function() {
        if (Api.notice.timeout + Api.notice.time < Date.now() / 1000) {
          clearInterval(Api.notice.check);
          delete Api.notice['check'];
          return notice.fadeOut(.2);
        }
      }, 100);
    }
  };

  RPGApi.prototype.log = function(key, value, time) {
    var log;
    if (time != null) {
      Api.notice("<span>" + key + "</span> <b>" + value + "</b>", time);
    }
    log = $("#log");
    log.append("<li><span>" + key + "</span> <b>" + value + "</b></li>");
    return log.animate({
      scrollTop: log.height()
    }, "fast");
  };

  RPGApi.prototype.register = function(opts, p) {
    var k, rule, v, _results;
    if (opts == null) {
      opts = {};
    }
    if (p == null) {
      p = this.rules;
    }
    _results = [];
    for (k in opts) {
      v = opts[k];
      rule = p[k];
      if (!(rule != null)) {
        _results.push(p[k] = v);
      } else {
        if (typeof rule === "function") {
          _results.push(p[k] = [rule, v]);
        } else if (rule.length != null) {
          _results.push(rule.push(v));
        } else {
          _results.push(this.register(v, rule));
        }
      }
    }
    return _results;
  };

  RPGApi.prototype.route = function(message, rule) {
    var k, r, v, _results;
    if (rule == null) {
      rule = this.rules;
    }
    _results = [];
    for (k in message) {
      v = message[k];
      if (rule[k] != null) {
        if (typeof rule[k] === "function") {
          console.log("api:call", k);
          _results.push(rule[k].call(null, v));
        } else if (rule[k].length != null) {
          _results.push((function() {
            var _i, _len, _ref, _results1;
            _ref = rule[k];
            _results1 = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              r = _ref[_i];
              console.log("api:call", k, v);
              _results1.push(r.call(null, v));
            }
            return _results1;
          })());
        } else {
          console.log("+", k);
          _results.push(this.route(v, rule[k]));
        }
      } else {
        _results.push(console.log("api:unbound", k));
      }
    }
    return _results;
  };

  RPGApi.prototype.login = function(user, pass, callback) {
    return $.ajax({
      type: 'POST',
      url: config.wiki,
      headers: {
        "Content-Type": "application/json"
      },
      data: JSON.stringify({
        jsonrpc: "2.0",
        id: "123",
        method: {
          methodName: "dokuwiki.login"
        },
        params: [
          {
            string: user
          }, {
            string: pass
          }
        ]
      }),
      success: function(e) {
        return callback(e.result);
      },
      error: function(e) {
        return callback(false);
      }
    });
  };

  RPGApi.prototype.get = function(path, callback) {
    return $.ajax({
      type: 'POST',
      url: config.wiki,
      headers: {
        "Content-Type": "application/json"
      },
      data: JSON.stringify({
        jsonrpc: "2.0",
        id: "123",
        method: {
          methodName: "wiki.getPage"
        },
        params: [
          {
            string: config.root + ":" + path
          }
        ]
      }),
      success: function(e) {
        return callback(e.result);
      },
      error: function(e) {
        return callback(false);
      }
    });
  };

  RPGApi.prototype.list = function(path, callback) {
    return $.ajax({
      type: 'POST',
      url: config.wiki,
      headers: {
        "Content-Type": "application/json"
      },
      data: JSON.stringify({
        jsonrpc: "2.0",
        id: "123",
        method: {
          methodName: "dokuwiki.getPagelist"
        },
        params: [
          {
            string: config.root + (path != null ? ":" + path : '')
          }, {
            struct: [
              {
                depth: 1
              }
            ]
          }
        ]
      }),
      success: function(e) {
        return callback(e.result);
      },
      error: function(e) {
        return callback(false);
      }
    });
  };

  function RPGApi(address, service) {
    this.address = address;
    this.service = service;
    this.connect = __bind(this.connect, this);

    this.send = __bind(this.send, this);

    this.route = __bind(this.route, this);

    this.register = __bind(this.register, this);

  }

  RPGApi.prototype.send = function(m) {
    if (m.name == null) {
      m.name = Api.name;
    }
    return this.socket.send(JSON.stringify(m));
  };

  RPGApi.prototype.connect = function() {
    var _this = this;
    if (typeof WebSocket !== "undefined" && WebSocket !== null) {
      this.socket = new WebSocket(this.address, this.service);
    }
    if (typeof MozWebSocket !== "undefined" && MozWebSocket !== null) {
      this.socket = new MozWebSocket(this.address, this.service);
    }
    this.socket.message = function(m) {
      return this.send(JSON.stringify(m));
    };
    this.socket.onerror = function(e) {
      console.log("sock:error " + e);
      return setTimeout(this.connect, 1000);
    };
    this.socket.onopen = function(s) {
      return console.log("sock:connected");
    };
    return this.socket.onmessage = function(m) {
      try {
        m = JSON.parse(m.data);
        _this.route.ctx = {
          name: m.name != null ? m.name : "RPG",
          message: m
        };
        delete m['name'];
        return _this.route(m);
      } catch (e) {
        return console.log({}, e, m);
      }
    };
  };

  return RPGApi;

})();

window.Api = new RPGApi();

$(document).ready(function() {
  Api.name = "rpg";
  return Api.register({
    msg: function(m) {
      return Api.log(Api.route.ctx.name, m.text, 3);
    },
    dice: function(m) {
      return Api.log(Api.route.ctx.name + ' ' + m.eyes, m.result, 2);
    }
  }, $.ajax({
    url: "etc/config.json",
    success: function(d) {
      console.log(d);
      Api.address = window.location.origin.replace("https://", "ws://").replace("http://", "ws://").replace(/:[0-9]+$/, ':') + (parseInt(d.port) + 1);
      return Api.connect();
    }
  }));
});
