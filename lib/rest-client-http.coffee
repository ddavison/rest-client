request = require 'request'

module.exports =
class RestClientHttp
  @encodePayload: (payload) ->
    encodeURIComponent(payload)

  @decodePayload: (payload) ->
    decodeURIComponent(payload)

  @send: (request_options, callback) ->
    request(request_options, callback)
