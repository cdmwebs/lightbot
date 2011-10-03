nodeio = require 'node.io'

getRandomInt = (min, max) ->
  Math.floor(Math.random() * (max - min + 1)) + min

class RedditGif extends nodeio.JobClass
  input: false
  run: (num) ->
    @getHtml 'http://www.reddit.com/r/gifs', (err, $) ->
      gifs = $('a.title')
      gif = gifs[getRandomInt(1, gifs.length)]
      console.log gif
      console.log "#{gif.children[0].data} #{gif.attribs.href}"

@class = RedditGif
@job = new RedditGif
