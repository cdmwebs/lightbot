client = require('ranger').createClient("26webs", "cdf23f8aa8dfeda95d2ad7b27a985057c1bdce6e")

client.room 417855, (room) ->
  room.join ->
    room.listen (message) ->
      if message.type == "TextMessage" and message.body.match(/soccer/i)
        room.play "vuvuzela"
        client.user message.userId, (user) ->
          room.speak "#{user.name} said 'soccer', so I played a vuvuzela."
