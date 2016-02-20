fs = require 'fs'

module.exports =
class RestClientPersist
  constructor: (path, data) ->
    @path = path
    @data = data

  load: (callback) ->
    fs.readFile(@path, callback)

  save: ->
    fs.writeFile("#{@path}", JSON.stringify(@data), @showErrorOnPersist)

  showErrorOnPersist: (err) =>
    if err
      atom.confirm(
        message: 'Cannot save file: ' + @path,
        detailedMessage: JSON.stringify(err)
      )
