RestClientView = require '../lib/rest-client-view'

describe "RestClientView test", ->
  [restClient] = []

  beforeEach ->
    restClient = new RestClientView()

  describe "View", ->
    it "the view is loaded", ->
      expect(restClient.find('.rest-client-send')).toExist()

  describe "Json", ->
    it "body is not json", ->
      expect(restClient.isJson("<html></html>")).toBe(false)

    it "body is json", ->
      expect(restClient.isJson('{"hello": "world"}')).toBe(true)

    it "process result is not json", ->
      expect(restClient.processResult('<html></html>')).toEqual('<html></html>')

    it "process result is json", ->
      expect(restClient.processResult('{"hello": "world"}')).toEqual('{\n    "hello": "world"\n}')
