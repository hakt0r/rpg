class RPGApi
  rules : {}

  parse_section : (data, name, kind = '=====') ->
    begin = new RegExp kind+' '+name+' '+kind
    end   = new RegExp kind+'([^=]+)'+kind
    r = []
    data = data.split '\n' unless Array.isArray data
    for l in data
      if l.match begin
        read = true; continue
      break if read and l.match end
      r.push l if read
    return r

  progress : (state) ->
    ba = null; co = null
    if state is 'done'
      $(".barrier").replaceWith ''
    else
      co = $("body")
      debugger
      if (ba = $(".barrier")).length is 0
        co.append """<div class="barrier"></div>"""
        ba = co.find("> .barrier").last()
      ba.html "<h2>" + state + "</h2>"
    true

  dialog : (opts) ->
    Api.lastItemId = 0 unless Api.lastItemId?
    id = Api.lastItemId++
    co = $("body")
    ctx = {}
    co.append """<div class="barrier"></div>"""
    ctx.ba = co.find("> .barrier").last()
    co.append opts.src
    ctx.frame = co.find("> *").last()
    ctx.frame.attr("id",id)
    ctx.frame.addClass "wg"
    ctx.destroy = ->
      Api.progress('done')
      ctx.frame.replaceWith ""
      ctx.ba.replaceWith ""
    ctx.frame.find(".close").on "click", -> ctx.destroy()
    opts.init.call ctx

  notice : (text,time) ->
    Api.notice.time = if time? then time else 1
    notice = $("#notice")
    notice.css("display","block")
    notice.html(text)
    notice.effect("highlight", {color:"#0F0"}, 100)
    Api.notice.timeout = Date.now()/1000
    unless Api.notice.check?
      Api.notice.check = setInterval ->
          if Api.notice.timeout + Api.notice.time < Date.now() / 1000
            clearInterval Api.notice.check
            delete Api.notice['check']
            notice.fadeOut .2
        ,100

  log : (key, value, time)->
    Api.notice("<span>#{key}</span> <b>#{value}</b>",time) if time?
    log = $("#log")
    log.append """<li><span>#{key}</span> <b>#{value}</b></li>"""
    log.animate({ scrollTop: log.height() }, "fast");

  register : (opts={},p) =>
    p = @rules unless p?
    for k,v of opts
      rule = p[k]
      if not rule? then p[k] = v
      else
        if typeof rule is "function" then p[k] = [rule,v]
        else if rule.length? then rule.push v
        else @register v,rule

  route : (message,rule) =>
    rule = @rules unless rule?
    for k,v of message
      if rule[k]?
        if typeof rule[k] is "function"
          console.log "api:call", k
          rule[k].call(null,v)
        else if rule[k].length?
          for r in rule[k]
            console.log "api:call",k,v
            r.call(null,v)
        else
          console.log "+",k
          @route v,rule[k]
      else console.log "api:unbound", k

  login: (user,pass,callback) ->
    $.ajax
      type : 'POST'
      url : config.rpc
      headers : "Content-Type": "application/json"
      data :
        JSON.stringify
          jsonrpc: "2.0"
          id: "123"
          method:
            methodName: "dokuwiki.login"
          params : [
            {string : user},
            {string : pass}]
      success: (e)-> callback(e.result)
      error :  (e)-> callback(false)

  get : (path, callback) ->
    $.ajax
      type : 'POST'
      url : config.rpc
      headers : "Content-Type": "application/json"
      data :
        JSON.stringify
          jsonrpc: "2.0"
          id: "123"
          method:
            methodName: "wiki.getPage"
          params : [ string : config.root + ":" + path ]
      success: (e)-> callback(e.result)
      error :  (e)-> callback(false)

  list : (path, callback) ->
    $.ajax
      type : 'POST'
      url : config.rpc
      headers : "Content-Type": "application/json"
      data :
        JSON.stringify
          jsonrpc: "2.0"
          id: "123"
          method:
            methodName: "dokuwiki.getPagelist"
          params : [
            {string : config.root + ( if path? then ":" + path else '' )},
            {struct : [{depth : 1 }]}]
      success: (e)-> callback(e.result)
      error :  (e)-> callback(false)

  constructor : (@address,@service) ->
  send : (m) =>
    m.name = Api.name unless m.name?
    Api.socket.send JSON.stringify m
  connect: =>
    console.log "connecting to: " + @address
    @socket  = new WebSocket(@address,@service)    if WebSocket?
    @socket  = new MozWebSocket(@address,@service) if MozWebSocket?
    @socket.message   = (m) -> @send JSON.stringify m
    @socket.onerror   = (e) ->
      console.log "sock:error #{e}"
      setTimeout @connect, 1000
    @socket.onopen    = (s) ->
      console.log "sock:connected"
    @socket.onmessage = (m) =>
      try
        m = JSON.parse(m.data)
        @route.ctx = 
          name : if m.name? then m.name else "RPG"
          message : m
        delete m['name']
        @route(m)
      catch e
        return console.log {}, e, m

window.Api = new RPGApi()

$(document).ready ->
  Api.name = "rpg"
  Api.register
    msg  : (m) -> Api.log Api.route.ctx.name, m.text, 3
    dice : (m) -> Api.log Api.route.ctx.name + ' ' + m.eyes, m.result, 2
  $.ajax
    url : "etc/config.json"
    success : (d) ->
      console.log d
      Api.address = "ws://" + window.location.toString()
          .replace("https://","")
          .replace("http://","")
          .replace(/\/.*$/,'')
          .replace(/:[0-9]+$/,'') + ':' +
        (parseInt(d.port)+1)
      Api.connect()