RestClientView = null
restClientUri = 'atom://rest-client'

createRestClientView = (state) ->
  RestClientView ?= require './rest-client-view'
  new RestClientView(state)

deserializer =
  name: 'RestClientView'
  deserialize: (state) -> createRestClientView(state)
atom.deserializers.add(deserializer)

module.exports =
  activate: ->
    atom.workspace.addOpener (filePath) ->
      createRestClientView(uri: restClientUri) if filePath is restClientUri

    atom.commands.add 'atom-workspace', 'rest-client:show', ->
      atom.workspace.open(restClientUri)
