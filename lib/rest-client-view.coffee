{$, ScrollView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
querystring = require 'querystring'

RestClientResponse = require './rest-client-response'
RestClientEditor = require './rest-client-editor'
RestClientHttp = require './rest-client-http'
RestClientEvent = require './rest-client-event'
RestClientRecentRequest = require './rest-client-recent-request'

ENTER_KEY = 13
current_method = 'GET'
DEFAULT_NORESPONSE = 'NO RESPONSE'

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
  loading: '.rest-client-loading-icon'

recent_requests =
  block: '#rest-client-recent'
  button: '#rest-client-recent-toggle'
  list: '#rest-client-recent-requests'

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

        @input type: 'text', class: "field #{rest_form.url.split('.')[1]}", autofocus: 'true'

        # methods
        @div class: 'btn-group btn-group-sm', =>
          for method in RestClientHttp.METHODS
            if method is 'get'
              @button class: "btn selected #{rest_form.method.split('.')[1]}-#{method}", method.toUpperCase()
            else
              @button class: "btn #{rest_form.method.split('.')[1]}-#{method}", method.toUpperCase()

        # Recent requests
        @div id: "#{recent_requests.block.split('#')[1]}", =>
          @button id: "#{recent_requests.button.split('#')[1]}", class: "btn", 'Recent requests'
          @ul id: "#{recent_requests.list.split('#')[1]}", style: 'display: none;'

        # Headers
        @div class: 'rest-client-headers-container', =>
          @h5 'Headers'

          @div class: 'btn-group btn-group-lg', =>
            @button class: 'btn selected', 'Raw'

          @textarea class: "field #{rest_form.headers.split('.')[1]}", rows: 7
          @strong 'User-Agent'
          @input class: "field #{rest_form.user_agent.split('.')[1]}", value: 'atom-rest-client'

        # Payload
        @div class: 'rest-client-payload-container', =>
          @h5 'Payload'

          @div class: "text-info lnk float-right #{rest_form.decode_payload.split('.')[1]}", 'Decode payload '
          @div class: "text-info lnk float-right #{rest_form.encode_payload.split('.')[1]}", 'Encode payload'
          @div class: 'btn-group btn-group-lg', =>
            @button class: 'btn selected', 'Raw'

          @textarea class: "field #{rest_form.payload.split('.')[1]}", rows: 7

        # Content-Type
        @select class: "list-group #{rest_form.content_type.split('.')[1]}", =>
          @option class: 'selected', 'application/x-www-form-urlencoded', 'application/x-www-form-urlencoded'
          @option value: 'application/atom+xml', 'application/atom+xml'
          @option value: 'application/json', 'application/json'
          @option value:'application/xml', 'application/xml'
          @option value: 'application/multipart-formdata', 'application/multipart-formdata'
          @option value: 'text/html', 'text/html'
          @option value: 'text/plain', 'text/plain'

        # Result
        @div class: 'tool-panel panel-bottom padded', =>
          @strong 'Result | '
          @span class: "#{rest_form.status.split('.')[1]}"

          @span class: "#{rest_form.loading.split('.')[1]} loading loading-spinner-small inline-block", style: 'display: none;'
          @pre class: "#{rest_form.result.split('.')[1]}", "#{RestClientResponse.DEFAULT_RESPONSE}"
          @div class: "text-info lnk #{rest_form.open_in_editor.split('.')[1]}", 'Open in separate editor'

  initialize: ->
    @RECENT_REQUESTS_PATH = "#{atom.packages.resolvePackagePath('rest-client')}/recent.json"

    @recentRequests = new RestClientRecentRequest(@RECENT_REQUESTS_PATH)
    @recentRequests.initPath()

    @emitter = new Emitter
    @subscribeToEvents()

    @recentRequests.load(@loadRecentRequestsInView)

  subscribeToEvents: ->
    @emitter.on RestClientEvent.NEW_REQUEST, @recentRequests.save
    @emitter.on RestClientEvent.NEW_REQUEST, @addRecentRequestInView
    @emitter.on RestClientEvent.NEW_REQUEST, @showLoading
    @emitter.on RestClientEvent.REQUEST_FINISHED, @hideLoading

    for method in RestClientHttp.METHODS
      @on 'click', "#{rest_form.method}-#{method}", ->
        $this = $(this)
        $this.siblings().removeClass('selected')
        $this.addClass('selected')
        current_method = $this.html()

    @on 'click', rest_form.clear_btn, => @clearForm()
    @on 'click', rest_form.send_btn,  => @sendRequest()

    @on 'click', rest_form.encode_payload, => @encodePayload()
    @on 'click', rest_form.decode_payload, => @decodePayload()

    @on 'click', rest_form.open_in_editor, => @openInEditor()

    @on 'keypress', rest_form.url, ((_this) ->
      ->
        _this.sendRequest() if event.keyCode is ENTER_KEY
        return
    )(this)

    @on 'click', recent_requests.button, => @toggleRecentRequests()

  openInEditor: ->
    textResult = $(rest_form.result).text()
    file_name = "#{current_method} - #{$(rest_form.url).val()}"
    editor = new RestClientEditor(textResult, file_name)
    editor.open()

  encodePayload: ->
    $(rest_form.payload).val(
      RestClientHttp.encodePayload($(rest_form.payload).val())
    )

  decodePayload: ->
    $(rest_form.payload).val(
      RestClientHttp.decodePayload($(rest_form.payload).val())
    )

  clearForm: ->
    @hideLoading()
    @setDefaultValues()
    $(rest_form.result).show()

  setDefaultValues: ->
    $(rest_form.url).val('')
    $(rest_form.headers).val('')
    $(rest_form.payload).val('')
    $(rest_form.status).val('')
    $(rest_form.result).text(RestClientResponse.DEFAULT_RESPONSE)

  getHeaders: ->
    headers = {
      'User-Agent': $(rest_form.user_agent).val(),
      'Content-Type': $(rest_form.content_type).val() + ';charset=utf-8'
    }
    headers = @getCustomHeaders(headers)

    return headers

  getCustomHeaders: (headers) ->
    custom_headers = $(rest_form.headers).val().split('\n')

    for custom_header in custom_headers
      current_header = custom_header.split(':')
      if current_header.length > 1
        headers[current_header[0]] = current_header[1].trim()

    headers

  sendRequest: ->
    request_options =
      url: $(rest_form.url).val()
      headers: this.getHeaders()
      method: current_method,
      body: @getRequestBody()

    @emitter.emit RestClientEvent.NEW_REQUEST, request_options

    RestClientHttp.send(request_options, @onResponse)

  onResponse: (error, response, body) =>
    if !error
      switch response.statusCode
        when 200, 201, 204
          @showSuccessfulResponse(response.statusCode + " " + response.statusMessage)
        else
          @showErrorResponse(response.statusCode + " " + response.statusMessage)

      response = new RestClientResponse(body).getFormatted()
      $(rest_form.result).text(response)
    else
      @showErrorResponse(DEFAULT_NORESPONSE)
      $(rest_form.result).text(error)

    @emitter.emit RestClientEvent.REQUEST_FINISHED, response

  getRequestBody: ->
    payload = $(rest_form.payload).val()
    body = ""

    if payload
      switch $(rest_form.content_type).val()
        when "application/json"
          json_obj = JSON.parse(payload)
          body = JSON.stringify(json_obj)
        else
          body = payload

    body

  showSuccessfulResponse: (text) =>
    $(rest_form.status)
      .removeClass('text-error')
      .addClass('text-success')
      .text(text)

  showErrorResponse: (text) =>
    $(rest_form.status)
      .removeClass('text-success')
      .addClass('text-error')
      .text(text)

  loadRecentRequestsInView: (err, requests) =>
    if err
      console.log('Recent requests couldn\'t be loaded')
      return

    @recentRequests.update(JSON.parse(requests))
    @addRecentRequestsInView(@recentRequests.get())

  toggleRecentRequests: ->
    $(recent_requests.list).toggle()
    $(recent_requests.button).toggleClass('selected')

  addRecentRequestsInView: (requests) ->
    if not requests?
        return

    for request in requests
      @addRecentRequestInView(request)

  addRecentRequestInView: (data) =>
    $li = $('<li>')
    $li.text([data.method, data.url].join(' - '))
    $(recent_requests.list).prepend($li)
    $(recent_requests.list).children()
      .slice(@recentRequests.RECENT_REQUESTS_LIMIT)
      .detach()

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    deserializer: @constructor.name
    uri: @getUri()

  getUri: -> @uri

  getTitle: -> "REST Client"

  getModel: ->

  # loading bar
  showLoading: ->
    $(rest_form.result).hide()
    $(rest_form.loading).show()

  hideLoading: ->
    $(rest_form.loading).fadeOut()
    $(rest_form.result).show()
