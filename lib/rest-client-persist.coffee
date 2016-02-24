fs = require 'fs'

module.exports =
class RestClientPersist
  REQUESTS_LIMIT: 5
  requests: []

  constructor: (path) ->
    @path = path
    @initPath()

  load: (callback) ->
    fs.readFile(@path, callback)

  save: (request) =>
    @requests.unshift(request)
    @requests = @requests.slice(0, @REQUESTS_LIMIT)
    @saveFile()

  initPath: ->
    try
      stat = fs.lstatSync(@path)
      if !stat.isFile()
        @saveFile()
    catch statErr
        @saveFile()

  saveFile: ->
    fs.writeFile("#{@path}", JSON.stringify(@requests), @showErrorOnPersist)

  update: (requests) ->
    @requests = requests

  get: ->
    @requests

  showErrorOnPersist: (err) =>
    if err
      atom.confirm(
        message: 'Cannot save file: ' + @path,
        detailedMessage: JSON.stringify(err)
      )
