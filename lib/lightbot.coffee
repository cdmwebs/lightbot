unless process.env.CAMPFIRE_SUBDOMAIN && process.env.CAMPFIRE_TOKEN
  console.log 'missing CAMPFIRE_TOKEN or CAMPFIRE_SUBDOMAIN'
  process.exit(1)

http     = require("http")
_        = require('underscore')
url      = require('url')
https    = require('https')
qs       = require('querystring')
campfire = require('ranger').createClient(process.env.CAMPFIRE_SUBDOMAIN,
                                          process.env.CAMPFIRE_TOKEN)

# Setup the bot
# ------------------------------------------
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

joinRoom = (roomId) ->
  campfire.room roomId, (room) ->
    setInterval ->
      if room.isListening()
        console.log "listening in #{room.name}"
      else
        console.log "re-joining... #{room.name}"
        joinRoom(room)
    , 1000000
    room.join ->
      room.listen (message) ->
        return if message.type != "TextMessage" or message.userId == 990800
        body = message.body
        for action in lightbot.messages
          if position = body.match(action.re)
            console.log "performing #{action.re}"
            words = body.substr(position.index).split(" ")
            command = words.shift()
            action.callback room, words.join(" "), message

rooms = process.env.CAMPFIRE_ROOM.split(",")
_.each rooms, (roomId) ->
  console.info "joining #{roomId}"
  joinRoom(roomId)

messageUser = (message) ->
  campfire.user message.userId, (user) ->
    user.name

# end of bot setup. tricks are defined below
# ------------------------------------------
lightbot.on /tricks/i, (room, message) -> room.paste lightbot.tricks()
lightbot.on /soccer/i, (room, message) -> room.play 'vuvuzela'
lightbot.on /standup:/,(room, messageText, message) ->
  campfire.user message.userId, (user) ->
    room.speak "i hear ya, #{user.name}. Someday we'll record this stuff."

lightbot.on /imageme/i, (room, searchString) ->
  room.speak "I'm on it... #{searchString}"
  googleImage searchString, (image) ->
    room.speak image
    room.speak "How do you like those apples?" if searchString.match(/apple/)

lightbot.on /qotd/i, (room) ->
  util = require('util')
  exec = require('child_process').exec
  exec 'fortune', (error, stdout, stderr) ->
    room.speak error if error?
    room.speak stdout

lightbot.on /office address/i, (room, messageText, message) ->
  campfire.user message.userId, (user) ->
    room.speak "Hey #{user.name}, it's:"
    room.paste "11126 KENWOOD RD STE C\nBLUE ASH OH 45242-1897"

lightbot.on /bacon/i, (room, messageText, message) ->
  googleImage 'bacon', (image) ->
    room.speak image

lightbot.on /youtubeme/i, (room, searchString) ->
  room.speak "Visualizing #{searchString} ..."
  youtubeVideo searchString, (url) ->
    room.speak url

lightbot.on /gifme/i, (room) ->
  redditGif (image) ->
    room.speak image

googleImage = (searchString, callback) ->
  query = qs.escape(searchString)
  # This seems lame. https://github.com/joyent/node/issues/1390
  options =
    host: 'ajax.googleapis.com'
    path: "/ajax/services/search/images?v=1.0&rsz=8&q=#{query}&safe=moderate"
    port: 443
  https.get options, (res) ->
    body = ''
    res.on 'data', (chunk) ->
      body += chunk
      try
        json = JSON.parse(body)
        return unless json.responseData.results.length > 0
        images = json.responseData.results
        image = (images.sort -> (0.5 - Math.random()))[0]
        imageUrl = image.unescapedUrl
        callback imageUrl
      catch ex
        console.log 'waiting... ' + ex

youtubeVideo = (searchString, callback) ->
  query = qs.escape(searchString)
  options =
    host: 'gdata.youtube.com'
    path: "/feeds/api/videos?q=#{query}&orderby=published&start-index=11&max-results=10&v=2&alt=json"
    port: 443
  https.get options, (res) ->
    body = ''
    res.on 'data', (chunk) ->
      body += chunk
      try
        json = JSON.parse(body)
        return unless json.feed.entry.length > 0
        # data['feed']['entry'][random_nuber]['link'][0]['href']
        videos = json.feed.entry
        video = (videos.sort -> (0.5 - Math.random()))[0]
        videoUrl = video.link[0].href
        callback videoUrl
      catch ex
        console.log 'waiting... ' + ex

redditGif = (callback) ->
  options =
    host: 'reddit.com'
    path: '/r/gifs.json'
    port: 80
  http.get options, (res) ->
    body = ''
    res.on 'data', (chunk) ->
      body += chunk
      try
        json = JSON.parse(body)
        return unless json.feed.entry.length > 0
        images = _.reject(json.data.children, (i) -> !i.data.over_18)
        image = (images.sort -> (0.5 - Math.random()))[0]
        imageUrl = image.data.url
        callback imageUrl
      catch ex
        console.log 'waiting... ' + ex

