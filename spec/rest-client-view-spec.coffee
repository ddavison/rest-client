RestClientView = require '../lib/rest-client-view'

describe "RestClientView test", ->
  [restClient] = []

  beforeEach ->
    restClient = new RestClientView()

  describe "View", ->
    it "the view is loaded", ->
      expect(restClient.find('.rest-client-send')).toExist()

  describe "constructFileName", ->
    it "contains the url, the method and an extension inferred from the response content-type", ->
      restClient.setLastRequest { url: "http://example.com", method: "GET" }
      restClient.setLastResponse { headers: { "content-type": "application/json" } }
      expect(restClient.constructFileName()).toEqual "GET http://example.com.json"
