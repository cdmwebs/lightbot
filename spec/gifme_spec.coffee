require 'jasmine-node'

fs        = require('fs')
RedditGif = require('../scripts/redditGif')

describe 'gifme', ->
  beforeEach ->
    @redditGif = new RedditGif

  it "searches the reddits for non-nekkid gifs", ->
    @json = fs.readFileSync('spec/fixtures/reddit.json', 'utf8')
    expect(@redditGif.parseJSON(@json)).toMatch(/imgur/)

  it "doesn't show nekkid pictures", ->
    @json =
      data:
        children: [
          data:
            over_18: true
            url: "http://i.imgur.com/aVlRo.gif"
        ]
    expect(@redditGif.parseJSON(JSON.stringify(@json))).toBeUndefined()
