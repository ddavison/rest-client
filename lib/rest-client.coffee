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
    atom.workspace.registerOpener (filePath) ->
      createRestClientView(uri: restClientUri) if filePath is restClientUri

    atom.workspaceView.command 'rest-client:show', ->
      atom.workspaceView.open(restClientUri)
