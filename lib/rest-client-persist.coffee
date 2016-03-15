fs = require 'fs'

module.exports =
class RestClientPersist
  REQUEST_FILE_LIMIT: 100
  requests: []
  requestFileLimit: @REQUEST_FILE_LIMIT

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
    requestsToBeSaved = @get(@requestFileLimit)
    fs.writeFile(
      "#{@path}",
      JSON.stringify(requestsToBeSaved),
      @showErrorOnPersist
    )

  update: (requests) ->
    @requests = requests

  get: (limit = false) ->
    if limit
      return @requests.slice(0, limit)

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

  getRequestFileLimit: () ->
    return @requestFileLimit

  setRequestFileLimit: (limit) ->
    @requestFileLimit = limit

  clear: ->
    @requests = []
    @saveFile()
