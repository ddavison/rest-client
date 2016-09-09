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
    tab_key_behavior:
      title: 'Tab Key Behavior'
      type: 'object'
      properties:
        insert_tab:
          title: 'Insert Tab'
          description: 'Pressing the tab key will insert a tab character.'
          type: 'boolean'
          default: true
          order: 1
        soft_tabs:
          title: 'Soft Tabs'
          description: 'Use spaces to represent tabs.'
          type: 'boolean'
          default: true
          order: 2
        soft_tab_length:
          title: 'Soft Tab Length'
          description: 'The number of spaces used to represent a tab.'
          type: 'integer'
          minimum: 1
          default: 2
          order: 3


  activate: ->
    # TODO Config not accessible in view due to addOpener
    atom.workspace.addOpener (filePath) ->
      createRestClientView(uri: restClientUri) if filePath is restClientUri

    atom.commands.add 'atom-workspace', 'rest-client:show', ->
      atom.workspace.open(restClientUri, split: atom.config.get('rest-client.split'), searchAllPanes: true)

    atom.commands.add '.rest-client-headers, .rest-client-payload', 'rest-client.insertTab': => @insertTab()

    atom.config.observe 'rest-client.tab_key_behavior.insert_tab', (value) ->
      command = if value then 'rest-client.insertTab' else 'unset!'
      atom.keymaps.add 'REST Client', '.rest-client-headers, .rest-client-payload': 'tab': command

  insertTab: ->
    soft_tabs = atom.config.get('rest-client.tab_key_behavior.soft_tabs')
    soft_tab_length = atom.config.get('rest-client.tab_key_behavior.soft_tab_length')
    tab = if soft_tabs then ' '.repeat(soft_tab_length) else '\t'
    text = event.target.value
    start = event.target.selectionStart
    end = event.target.selectionEnd
    endText = if start is end then text.slice(start) else text.slice(end, text.length)

    event.target.value = text.slice(0, start) + tab + endText
    event.target.selectionStart = event.target.selectionEnd = start + tab.length
