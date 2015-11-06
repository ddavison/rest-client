RestClientView = require '../lib/rest-client-view'

describe "RestClientView test", ->
  [restClient] = []

  beforeEach ->
    restClient = new RestClientView()

  describe "View", ->
    it "the view is loaded", ->
      expect(restClient.find('.rest-client-send')).toExist()
