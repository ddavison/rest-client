fs = require 'fs'

module.exports =
class RestClientPersist
  constructor: (path, data = {}) ->
    @path = path
    @data = data

  load: ->
    fs.readFile(@path, @processRead)

  save: ->
    fs.writeFile("#{@path}", JSON.stringify(@data), @showErrorOnPersist)

  processRead: (readError, data) =>
    if readError
      return @showErrorOnPersist(readError)

    try
      @data = JSON.parse(data)
    catch jsonError
      return @showErrorOnPersist(jsonError)

  showErrorOnPersist: (err) ->
    atom.confirm(
      message: 'Cannot save file: ' + @path,
      detailedMessage: JSON.stringify(err)
    )
