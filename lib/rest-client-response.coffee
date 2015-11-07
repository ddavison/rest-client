TAB_JSON_SPACES = 4

module.exports =
class RestClientResponse
  @DEFAULT_RESPONSE = 'No data yet...'

  constructor: (body) ->
    @body = body

  isJson: ->
    try
      JSON.parse(@body)
      true
    catch error
      false

  getFormatted: ->
    if @isJson(@body)
      JSON.stringify(JSON.parse(@body), undefined, TAB_JSON_SPACES)
    else
      @body
