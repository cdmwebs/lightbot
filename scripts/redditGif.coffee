_    = require('underscore')
http = require("http")

class RedditGif
  go: (callback) ->
    options =
      host: 'reddit.com'
      path: '/r/gifs.json'
      port: 80
    http.get options, (res) ->
      body = ''
      res.on 'data', (chunk) ->
        body += chunk
        try
          callback parseJson(body)
        catch ex
          console.log 'waiting... ' + ex

  parseJSON: (body) ->
    json = JSON.parse(body)
    children = json.data.children
    return unless children.length > 0
    images = _.reject(children, (i) -> i.data.over_18)
    image = (images.sort -> (0.5 - Math.random()))[0]
    image.data.url if image

module.exports = RedditGif
