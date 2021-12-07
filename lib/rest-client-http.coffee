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
    try
      decodeURIComponent(payload)
    catch error
      alert("Cannot decode payload. Ensure that the payload is encoded before it is decoded.\n    #{error}")
      false

  @send: (request_options, callback) ->
    request(request_options, callback)
