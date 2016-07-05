{$, ScrollView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
querystring = require 'querystring'

RestClientResponse = require './rest-client-response'
RestClientEditor = require './rest-client-editor'
RestClientHttp = require './rest-client-http'
RestClientEvent = require './rest-client-event'
RestClientPersist = require './rest-client-persist'

PACKAGE_PATH = atom.packages.resolvePackagePath('rest-client')
ENTER_KEY = 13
DEFAULT_NORESPONSE = 'NO RESPONSE'
DEFAULT_REQUESTS_LIMIT = 10
DEFAULT_HEADERS = ['User-Agent', 'Content-Type']
RECENT_REQUESTS_FILE_LIMIT = 5
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
  save_btn: '.rest-client-save',
  result: '.rest-client-result',
  result_headers: '.rest-client-result-headers',
  result_link: '.rest-client-result-link',
  result_headers_link: '.rest-client-result-headers-link',
  status: '.rest-client-status',
  user_agent: '.rest-client-user-agent',
  strict_ssl: '.rest-client-strict-ssl',
  open_in_editor: '.rest-client-open-in-editor'
  loading: '.rest-client-loading-icon'
  request_link: '.rest-client-request-link'
  request_link_remove: '.rest-client-request-link-remove'

recent_requests =
  block: '#rest-client-recent'
  button: '#rest-client-recent-toggle'
  list: '#rest-client-recent-requests'

saved_requests =
  block: '#rest-client-saved'
  button: '#rest-client-saved-toggle'
  list: '#rest-client-saved-requests'

module.exports =
class RestClientView extends ScrollView
  @content: ->
    @div class: 'rest-client native-key-bindings padded pane-item', tabindex: -1, =>
      @div class: 'rest-client-url-container', =>
        # Clear / Send
        @div class: 'block rest-client-action-btns', =>
          @div class: 'block', =>
            @div class: 'btn-group btn-group-lg', =>
              @button class: "btn btn-lg #{rest_form.save_btn.split('.')[1]}", 'Save'
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

        # Saved requests
        @div id: "#{saved_requests.block.split('#')[1]}", =>
          @button id: "#{saved_requests.button.split('#')[1]}", class: "btn", 'Saved requests'
          @ul id: "#{saved_requests.list.split('#')[1]}", style: 'display: none;'

        # Headers
        @div class: 'rest-client-headers-container', =>
          @h5 'Headers'

          @div class: 'btn-group btn-group-lg', =>
            @button class: 'btn selected', 'Raw'

          @textarea class: "field #{rest_form.headers.split('.')[1]}", rows: 7
          @strong 'User-Agent'
          @input class: "field #{rest_form.user_agent.split('.')[1]}", value: 'atom-rest-client'
          @strong 'Strict SSL'
          @input type: 'checkbox', class: "field #{rest_form.strict_ssl.split('.')[1]}", checked: true

        # Payload
        @div class: 'rest-client-payload-container', =>
          @h5 'Payload'

          @div class: "text-info lnk float-right #{rest_form.decode_payload.split('.')[1]}", 'Decode payload '
          @div class: "buffer float-right", '|'
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
          @a class: "#{rest_form.result_link.split('.')[1]}", 'Result'
          @span ' | '
          @a class: "#{rest_form.result_headers_link.split('.')[1]}", 'Headers'
          @span ' | '
          @span class: "#{rest_form.status.split('.')[1]}"

          @span class: "#{rest_form.loading.split('.')[1]} loading loading-spinner-small inline-block", style: 'display: none;'
          @pre class: "#{rest_form.result_headers.split('.')[1]}", ""
          @pre class: "#{rest_form.result.split('.')[1]}", "#{RestClientResponse.DEFAULT_RESPONSE}"
          @div class: "text-info lnk #{rest_form.open_in_editor.split('.')[1]}", 'Open in separate editor'

  initialize: ->
    @COLLECTIONS_PATH = "#{PACKAGE_PATH}/collections.json"
    @RECENT_REQUESTS_PATH = "#{PACKAGE_PATH}/recent.json"

    @lastRequest = null

    @recentRequests = new RestClientPersist(@RECENT_REQUESTS_PATH)
    @recentRequests.setRequestFileLimit(RECENT_REQUESTS_FILE_LIMIT)
    @savedRequests = new RestClientPersist(@COLLECTIONS_PATH)

    @emitter = new Emitter
    @subscribeToEvents()

    @recentRequests.load(@loadRecentRequestsInView)
    @savedRequests.load(@loadSavedRequestsInView)

  subscribeToEvents: ->
    @emitter.on RestClientEvent.NEW_REQUEST, @recentRequests.save
    @emitter.on RestClientEvent.NEW_REQUEST, @addRecentRequestItem
    @emitter.on RestClientEvent.NEW_REQUEST, @showLoading
    @emitter.on RestClientEvent.NEW_REQUEST, @setLastRequest
    @emitter.on RestClientEvent.REQUEST_FINISHED, @hideLoading

    for method in RestClientHttp.METHODS
      @on 'click', "#{rest_form.method}-#{method}", ->
        $this = $(this)
        $this.siblings().removeClass('selected')
        $this.addClass('selected')
        current_method = $this.html()

    @on 'click', rest_form.clear_btn, => @clearForm()
    @on 'click', rest_form.send_btn,  => @sendRequest()
    @on 'click', rest_form.save_btn,  => @saveRequest()

    @on 'click', rest_form.encode_payload, => @encodePayload()
    @on 'click', rest_form.decode_payload, => @decodePayload()

    @on 'click', rest_form.open_in_editor, => @openInEditor()

    @on 'keypress', rest_form.url, ((_this) ->
      ->
        _this.sendRequest() if event.keyCode is ENTER_KEY
        return
    )(this)

    @on 'click', recent_requests.button, => @toggleRequests(recent_requests)
    @on 'click', saved_requests.button, => @toggleRequests(saved_requests)

    @on 'click', rest_form.result_link, => @toggleResult(rest_form.result)
    @on 'click', rest_form.result_headers_link, => @toggleResult(rest_form.result_headers)

    $('body').on 'click', rest_form.request_link, @loadRequest
    $('body').on 'click', rest_form.request_link_remove, @removeSavedRequest

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
    request_options = @getRequestOptions()

    if request_options.url
      @emitter.emit RestClientEvent.NEW_REQUEST, request_options
      RestClientHttp.send(request_options, @onResponse)

  saveRequest: ->
    if @lastRequest?
      @savedRequests.save(@lastRequest)
      @addRequestItem(saved_requests.list, @lastRequest)

  removeSavedRequest: (e) =>
    $target = $(e.currentTarget)
    request = $target
        .siblings(rest_form.request_link)
        .data('request')
    @savedRequests.remove(request)
    $target.parent().remove()

  getRequestOptions: ->
    options =
      url: $(rest_form.url).val()
      headers: this.getHeaders()
      method: current_method,
      strictSSL: $(rest_form.strict_ssl).is(':checked'),
      body: @getRequestBody()

  onResponse: (error, response, body) =>
    if !error
      statusMessage = response.statusCode + " " + response.statusMessage

      switch response.statusCode
        when 200, 201, 204
          @showSuccessfulResponse(statusMessage)
        else
          @showErrorResponse(statusMessage)

      headers = @formatHeaders response.headers
      response = new RestClientResponse(body).getFormatted()
      result = response
    else
      @showErrorResponse(DEFAULT_NORESPONSE)
      result = error

    $(rest_form.result).text(result)
    $(rest_form.result_headers).text(headers).hide()
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

  formatHeaders: (headers) =>
    formattedHeaders = ''

    for key, value of headers
      formattedHeaders += key + ': ' + value + '\n'

    formattedHeaders

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

  loadRequest: (e) =>
    request = $(e.currentTarget).data('request')
    @fillInRequest(request)

  loadRecentRequestsInView: (err, requests) =>
    if err
      console.log('Recent requests couldn\'t be loaded')
      return

    @recentRequests.update(JSON.parse(requests))
    @addRequestsInView(recent_requests.list, @recentRequests.get())

  loadSavedRequestsInView: (err, requests) =>
    if err
      console.log('Saved requests couldn\'t be loaded')
      return

    @savedRequests.update(JSON.parse(requests))
    @addRequestsInView(saved_requests.list, @savedRequests.get())

  toggleRequests: (target) ->
    $(target.list).toggle()
    $(target.button).toggleClass('selected')

  toggleResult: (target) ->
    $target = $(target)
    $target.siblings('pre').hide()
    $target.show()

  addRequestsInView: (target, requests) ->
    if not requests?
        return

    for request in requests
      @addRequestItem(target, request)

  addRequestItem: (target, data) =>
    $li = $('<li>')
    $li.append(
      $('<a>').text([data.method, data.url].join(' - '))
        .attr('href', '#request')
        .addClass(rest_form.request_link.split('.')[1])
        .attr('data-request', JSON.stringify(data))
    )

    if target == saved_requests.list
      $li.append(
        $('<a>').html($('<span>').addClass('icon icon-x'))
          .attr('href', '#remove')
          .addClass(rest_form.request_link_remove.split('.')[1])
      )

    $(target).prepend($li)
    $(target).children()
      .slice(DEFAULT_REQUESTS_LIMIT)
      .detach()

  fillInRequest: (request) ->
    $(rest_form.url).val(request.url)
    @setMethodAsSelected(request.method)
    $(rest_form.payload).val(request.payload)
    $(rest_form.headers).val(@getHeadersAsString(request.headers))
    $(rest_form.user_agent).val(request.headers['User-Agent'])
    $(rest_form.content_type).val(request.headers['Content-Type'])

  addRecentRequestItem: (data) =>
    @addRequestItem(recent_requests.list, data)

  setLastRequest: (request) =>
    @lastRequest = request

  getHeadersAsString: (headers)  ->
    output = ''

    for header, value of headers
        if not @isDefaultHeader(header)
          output = output.concat(header + ': ' + value + '\n')

    return output

  setMethodAsSelected: (method) ->
    $method = $(rest_form.method + '-' + method.toLowerCase())
    $method.click()

  isDefaultHeader: (header) ->
    return DEFAULT_HEADERS.indexOf(header) != -1


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
