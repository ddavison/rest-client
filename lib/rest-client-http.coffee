request = require 'request'

module.exports =
class RestClientHttp
  @METHODS: [
    'get',
    'post',
    'put',
    'patch',
    'delete',
    'head',
    'options'
  ]

  @encodePayload: (payload) ->
    encodeURIComponent(payload)

  @decodePayload: (payload) ->
    decodeURIComponent(payload)

  @send: (request_options, callback) ->
    request(request_options, callback)
