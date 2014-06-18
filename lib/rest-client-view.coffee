{$, ScrollView} = require 'atom'
querystring = require 'querystring'
request = require 'request'
fs = require 'fs'

methods = [
  'get',
  'post',
  'put',
  'patch',
  'delete',
  'head',
  'options'
]

current_method = 'GET'

response = '' # global object for the response.

rest_form =
  url: '.rest-client-url',
  method: '.rest-client-method',
  method_other_field: '.rest-client-method-other-field',
  headers: '.rest-client-headers',
  payload: '.rest-client-payload',
  encode_payload: '.rest-client-encodepayload',
  decode_payload: '.rest-client-decodepayload',
  content_type: '.rest-client-content-type',
  clear_btn: '.rest-client-clear',
  send_btn: '.rest-client-send',
  result: '.rest-client-result',
  status: '.rest-client-status',
  user_agent: '.rest-client-user-agent',
  open_in_editor: '.rest-client-open-in-editor'


module.exports =
class RestClientView extends ScrollView
  @content: ->
    @div class: 'rest-client native-key-bindings padded pane-item', tabindex: -1, =>
      @div class: 'rest-client-url-container', =>
        # Clear / Send
        @div class: 'block rest-client-action-btns', =>
          @div class: 'block', =>
            @div class: 'btn-group btn-group-lg', =>
              @button class: "btn btn-lg #{rest_form.clear_btn.split('.')[1]}", 'Clear'
              @button class: "btn btn-lg #{rest_form.send_btn.split('.')[1]}", 'Send'

        @input type: 'text', class: "editor native-key-bindings #{rest_form.url.split('.')[1]}"

        # methods
        ## GET
        @div class: 'btn-group btn-group-sm', =>
          for method in methods
            if method is 'get'
              @button class: "btn selected #{rest_form.method.split('.')[1]}-#{method}", method.toUpperCase()
            else
              @button class: "btn #{rest_form.method.split('.')[1]}-#{method}", method.toUpperCase()

        # Headers
        @div class: 'rest-client-headers-container', =>
          @h5 'Headers'

          @div class: 'btn-group btn-group-lg', =>
            @button class: 'btn selected', 'Raw'

          @textarea class: "editor native-key-bindings #{rest_form.headers.split('.')[1]}", rows: 7
          @strong 'User-Agent'
          @input class: "editor #{rest_form.user_agent.split('.')[1]}", value: 'atom-rest-client'

        # Payload
        @div class: 'rest-client-payload-container', =>
          @h5 'Payload'

          @div class: 'btn-group btn-group-lg', =>
            @button class: 'btn selected', 'Raw'

          @div class: "text-info lnk #{rest_form.encode_payload.split('.')[1]}", 'Encode payload'
          @div class: "text-info lnk #{rest_form.decode_payload.split('.')[1]}", 'Decode payload'
          @textarea class: "editor native-key-bindings #{rest_form.payload.split('.')[1]}", rows: 7

        # Content-Type
        @select class: "list-group #{rest_form.content_type.split('.')[1]}", =>
          @option class: 'selected', 'application/x-www-form-urlencoded', 'application/x-www-form-urlencoded'
          @option value: 'application/atom+xml', 'application/atom+xml'
          @option value: 'application/json', 'application/json'
          @option value:'application/xml', 'application/xml'
          @option value: 'application/multipart-formdata', 'application/multipart-formdata'
          @option value: 'text/html', 'text/html'
          @option value: 'text/plain', 'text/plain'

        @div class: 'tool-panel panel-bottom padded', =>
          @strong 'Result | '
          @span class: "#{rest_form.status.split('.')[1]}"

          @pre class: "#{rest_form.result.split('.')[1]}", 'No data yet..'
          @div class: "text-info lnk #{rest_form.open_in_editor.split('.')[1]}", 'Open in seperate editor'

  initialize: ->
    for method in methods
      @on 'click', "#{rest_form.method}-#{method}", ->
        for m in methods
          $("#{rest_form.method}-#{m}").removeClass('selected')
        $(this).addClass('selected')
        current_method = $(this).html()

    @on 'click', rest_form.clear_btn, => @clearForm()
    @on 'click', rest_form.send_btn,  => @sendRequest()

    @on 'click', rest_form.encode_payload, => @encodePayload()
    @on 'click', rest_form.decode_payload, => @decodePayload()

    @on 'click', rest_form.open_in_editor, => @openInEditor()

  openInEditor: ->
    if $(rest_form.result).text() != 'No data yet..'
      file_name = "#{current_method} - #{$(rest_form.url).val()}"
      file_name = file_name.replace(/https?:\/\//, '')
      file_name = file_name.replace(/\//g, '')

      # ideally, i want to open it without saving a file, but i don't think that'll work due to atom limitations
      fs.writeFile("/tmp/#{file_name}", @response, (err) ->
        if err
          atom.confirm(
            message: 'Cannot save to tmp directory..',
            detailedMessage: JSON.stringify(err)
          )
        else
          atom.workspaceView.open("/tmp/#{file_name}")
      )

  encodePayload: ->
    encoded_payload = encodeURIComponent($(rest_form.payload).val())
    $(rest_form.payload).val(encoded_payload)

  decodePayload: ->
    decoded_payload = decodeURIComponent($(rest_form.payload).val())
    $(rest_form.payload).val(decoded_payload)

  clearForm: ->
    $(rest_form.url).val("")
    $(rest_form.headers).val("")
    $(rest_form.payload).val("")
    $(rest_form.result).text('No data yet..')
    $(rest_form.status).text("")

  sendRequest: ->
    request_options =
      url: $(rest_form.url).val()
      headers:
        'User-Agent': $(rest_form.user_agent).val(),
        'Content-Type': $(rest_form.content_type).val() + ';charset=utf-8'
      method: current_method,
      body: ""


    payload = $(rest_form.payload).val()
    console.log payload
    if payload
      switch $(rest_form.content_type).val()
        when "application/json"
          json_obj = JSON.parse(payload)
          request_options.body = JSON.stringify(json_obj)
        else
          request_options.body = payload

    request(request_options, (error, response, body) =>
      @response = body
      if !error
        switch response.statusCode
          when 200,201
            $(rest_form.status).removeClass('text-error')
            $(rest_form.status).addClass('text-success')
            $(rest_form.status).text(response.statusCode + " " +response.statusMessage)
          else
            $(rest_form.status).removeClass('text-success')
            $(rest_form.status).addClass('text-error')
            $(rest_form.status).text(response.statusCode + " " +response.statusMessage)
        $(rest_form.result).text(body)
      else
        $(rest_form.status).removeClass('text-success')
        $(rest_form.status).addClass('text-error')
        $(rest_form.status).text('NO RESPONSE')
        $(rest_form.result).text(error)
    )

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    deserializer: @constructor.name
    uri: @getUri()

  getUri: -> @uri

  getTitle: -> "REST Client"

  getModel: ->
