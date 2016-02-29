fs = require 'fs'

module.exports =
class RestClientPersist
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

  remove: (removed_request) ->
    for request, index in @requests
      if @requestEquals(removed_request, request)
        @requests.splice(index, 1)
        @saveFile()
        break

  requestEquals: (request1, request2) ->
      return (request1.url == request2.url and
              request1.method == request2.method)
          

  showErrorOnPersist: (err) =>
    if err
      atom.confirm(
        message: 'Cannot save file: ' + @path,
        detailedMessage: JSON.stringify(err)
      )
