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
  config:
    request_collections_path:
      title: 'Request Collections path'
      description: 'Path for the file storing request collections'
      type: 'string'
      default: "#{atom.packages.resolvePackagePath('rest-client')}/collections.json"
    recent_requests_path:
      title: 'Recent requests path'
      description: 'Path for the file storing recent requests'
      type: 'string'
      default: "#{atom.packages.resolvePackagePath('rest-client')}/recent.json"
    recent_requests_limit:
      title: 'Recent Requests limit'
      description: 'number of recent requests to save'
      type: 'integer'
      default: 5
    split:
      title: 'Split setting'
      description: 'Open in "left" or "right" pane'
      type: 'string'
      default: 'left'

  activate: ->
    # TODO Config not accessible in view due to addOpener
    atom.workspace.addOpener (filePath) ->
      createRestClientView(uri: restClientUri) if filePath is restClientUri

    atom.commands.add 'atom-workspace', 'rest-client:show', ->
      atom.workspace.open(restClientUri, split: atom.config.get('rest-client.split'), searchAllPanes: true)
