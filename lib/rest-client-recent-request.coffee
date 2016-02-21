fs = require 'fs'
RestClientPersist = require './rest-client-persist'

module.exports =
class RestClientRecentRequest

  RECENT_REQUESTS_LIMIT: 5
  requests: []

  constructor: (path) ->
    @path = path

  initPath: ->
    try
      stat = fs.lstatSync(@path)
      if !stat.isFile()
        @saveFile()
    catch statErr
        @saveFile()

  load: (callback) ->
    persist = new RestClientPersist(@path)
    persist.load(callback)

  save: (request) =>
    @requests.unshift(request)
    @requests = @requests.slice(0, @RECENT_REQUESTS_LIMIT)
    @saveFile()

  saveFile: () ->
    persist = new RestClientPersist(@path, @requests)
    persist.save()

  update: (requests) ->
    @requests = requests

  get: ->
    @requests

