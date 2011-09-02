url = require('url')
http = require('https')
qs = require('querystring')
campfire = require('ranger').createClient("gaslightsoftware", "5bd2a8c8be4463d46c7729e2823bdd000e60a615")

class Bot
  messages: []
  on: (re, callback) ->
    console.log re
    @messages.push
      re: re
      callback: callback
  tricks: ->
    @messages
lightbot = new Bot

lightbot.on /tricks/i, (room, message) -> room.speak lightbot.tricks()
lightbot.on /soccer/i, (room, message) -> room.play 'vuvuzela'
lightbot.on /imageme/i, (room, searchString) ->
  room.speak "I'm on it... #{searchString}"
  googleImage searchString, (image) -> room.speak image

room = campfire.room 420976, (room) ->
  room.join ->
    room.listen (message) ->
      return unless message.type == "TextMessage"
      body = message.body
      for action in lightbot.messages
        if position = body.match(action.re)
          words = body.substr(position.index).split(" ")
          command = words.shift()
          action.callback room, words.join(" ")

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
        console.log json.responseData.results[0]
        return unless json.responseData.results.length > 0
        image = json.responseData.results[0].unescapedUrl
        callback image
      catch ex
        console.log 'waiting... ' + ex
