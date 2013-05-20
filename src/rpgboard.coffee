config =
  root : "rpg:kampagnen"
  wiki : "http://wiki.ulzq.de/lib/plugins/jsonrpc/jsonrpc.php"
  default : "Space_2013"

class Die
  constructor : (@eyes) ->
    $("#dice ul").append("""
      <li><button title="Roll a D#{@eyes}" class="d#{@eyes}"></button><input type="number" value="1" min="1" max="5" /><span></span></li>
    """)
    @me = $('#dice > ul > li').last()
    @btn = @me.find("button")
    @amt = @me.find("input")
    @res = @me.find("span")
    @btn.on 'click', =>
      amt = @amt.val()
      a = []
      r = 0
      for i in [0 ... amt ]
        b = Math.ceil Math.random() * @eyes
        a.push b
        r += b
      mx = amt*@eyes
      ai = a.join(", ")
      if amt > 2 then ai += " =#{r}/#{amt*@eyes}"
      ai += ' = ' + (Math.round r / mx * 100) + "%"
      @res.html ai
      $("#dice li span").removeClass("rolled")
      @res.addClass("rolled")
      dc = if amt < 2 then 'D'+@eyes else amt+"D"+@eyes
      unless Api.send { dice : { eyes : dc, vals : a, result : ai } }
        Api.log dc, result, 5

class ToolButton
  constructor : (opts) ->
    {@name,@image,@title,@tooltip,@click} = opts
    @image = @name unless @image?
    @title = @name unless @title?
    @tooltip = @name unless @tooltip?
    $("#toolbar").append("""
      <button title="#{@title}"><img src="img/#{@image}.svg" />#{@title}</button>
    """)
    $('#toolbar > button').last().click @click

$(document).ready ->
  new Die(i) for i in [4,6,8,10,12,20,100]

  new ToolButton
    name : "map"
    click : -> alert "please dont press this button again"

  new ToolButton
    name  : "login"
    image : "key"
    click : ->
      Api.list "", (campaigns)->
        camps = ( "<option>#{c}</option>" for c in campaigns )
        Api.dialog
          src : """
            <div class="dialog" id="#{@id}">
              <h2>login</h2>
              <button class="close">X</button>
              <label>Campaign</label><select>#{camps}</select>
              <label>User</label><input  type="text" class="name" />
              <label>Password</label><input  type="password" class="password" />
            </div>"""
          init : ->
            @name = @frame.find(".name")
            @pass = @frame.find(".password")
            @name.focus()
            @name.on "keydown", (e)=> if e.keyCode is 13 then @pass.focus()
            @pass.on "keydown", (e)=>
              if e.keyCode is 13
                user = @name.val(); pass = @pass.val();
                Api.login user, pass, (result) =>
                  if result
                    Api.log "login as", user, 2
                    Api.name = user 
                    @destroy()
                  else
                    @name.focus()
                    @name.effect("highlight",{},250)
                    @pass.effect("highlight",{},250)

  new ToolButton
    name  : "settings"
    image : "prefs"
    click : -> alert "please dont press this button again, 4 real"

  new ToolButton
    name  : "log"
    click : ->
      log = $("#wgl")
      log.css("display",if log.css("display") is "none" then "block" else "none")
  
  $("button").each (i,b) ->
    b = $(b)
    b.on "mouseover", -> Api.notice b.attr("title")
  
  chat = $("#chatinput")
  chat.on "keydown", (e) ->
    if e.keyCode is 13
      Api.send msg :
        text : chat.val()
      chat.val ''