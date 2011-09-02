_        = require('underscore')
url      = require('url')
http     = require('https')
qs       = require('querystring')
campfire = require('ranger').createClient(process.env.CAMPFIRE_ROOM
                                          process.env.CAMPFIRE_TOKEN)

class Bot
  messages: []
  on: (re, callback) ->
    @messages.push
      re: re
      callback: callback
  tricks: ->
    return "no tricks" if @messages.length == 0
    _.map(@messages, (msg) -> msg.re).join("\n")

lightbot = new Bot

room = campfire.room 420976, (room) ->
  room.join ->
    room.listen (message) ->
      return unless message.type == "TextMessage"
      return if message.userId == 990800
      body = message.body
      for action in lightbot.messages
        if position = body.match(action.re)
          words = body.substr(position.index).split(" ")
          command = words.shift()
          action.callback room, words.join(" ")

lightbot.on /tricks/i, (room, message) -> room.speak lightbot.tricks()
lightbot.on /soccer/i, (room, message) -> room.play 'vuvuzela'
lightbot.on /standup:/,(room, message) -> room.speak "i hear ya, man"

lightbot.on /imageme/i, (room, searchString) ->
  room.speak "I'm on it... #{searchString}"
  googleImage searchString, (image) -> room.speak image

googleImage = (searchString, callback) ->
  query = qs.escape(searchString)
  # This seems lame. https://github.com/joyent/node/issues/1390
  options =
    host: 'ajax.googleapis.com'
    path: "/ajax/services/search/images?v=1.0&rsz=1&q=#{query}"
    port: 443
  http.get options, (res) ->
    body = ''
    res.on 'data', (chunk) ->
      body += chunk
      try
        json = JSON.parse(body)
        return unless json.responseData.results.length > 0
        image = json.responseData.results[0].unescapedUrl
        callback image
      catch ex
        console.log 'waiting... ' + ex
