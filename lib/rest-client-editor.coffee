fs = require 'fs'

RestClientResponse = require './rest-client-response'

module.exports =
class RestClientEditor
  TMP_DIR_ERROR_MESSAGE: 'Cannot save to tmp directory..'

  constructor: (text, file_name) ->
    @text = text
    @file_name = @getFilename(file_name)
    @path = "/tmp/#{@file_name}"

  open: ->
    if [RestClientResponse.DEFAULT_RESULT, ""].indexOf(@text) == -1
      # ideally, i want to open it without saving a file, but i don't think that'll work due to atom limitations
      fs.writeFile(@path, @text, @processOpen)

  processOpen: (err) =>
    if err
      @showErrorOnOpen(err)
    else
      @openOnWorkspace(@path)

  getFilename: (file_name) ->
    file_name = file_name
        .replace(/https?:\/\//, '')
        .replace(/\//g, '')

    file_name

  showErrorOnOpen: (err) ->
    atom.confirm(
      message: @TMP_DIR_ERROR_MESSAGE,
      detailedMessage: JSON.stringify(err)
    )

  openOnWorkspace: (path) ->
    atom.workspace.open(path)
