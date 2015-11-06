RestClientResponse = require '../lib/rest-client-response'

describe "RestClientResponse", ->

  describe "Json", ->
    it "body is not json", ->
      body = "<html></html>"
      response = new RestClientResponse(body)
      expect(response.isJson()).toBe(false)

    it "body is json", ->
      body = '{"hello": "world"}'
      response = new RestClientResponse(body)
      expect(response.isJson()).toBe(true)

    it "process result is not json", ->
      body = "<html></html>"
      response = new RestClientResponse(body)
      expect(response.getFormatted()).toEqual('<html></html>')

    it "process result is json", ->
      body = '{"hello": "world"}'
      response = new RestClientResponse(body)
      expect(response.getFormatted()).toEqual('{\n    "hello": "world"\n}')
