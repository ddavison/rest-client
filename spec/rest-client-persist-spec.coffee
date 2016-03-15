fs = require 'fs'

RestClientPersist = require '../lib/rest-client-persist'
-
describe "RestClientPersist test", ->
  beforeEach ->
    PACKAGE_PATH = atom.packages.resolvePackagePath('rest-client')
    @testPath = "#{PACKAGE_PATH}test_path.json"
    @defaultRequest = {
      method: 'GET',
      url: 'http://example.com',
      payload: '',
      headers: {
       'User-Agent': 'atom-rest-client',
       'Content-Type': 'text/html'
      }
    }

  afterEach ->
    fs.unlinkSync(@testPath)

  describe "Persist", ->
    it "path is created", ->
      persist = false

      runs ->
        persist = new RestClientPersist(@testPath)

      waitsFor ->
        persist

      runs ->
        stats = fs.statSync(@testPath)

        expect(stats.isFile()).toBe(true)

    it "requests are saved", ->
      persist = new RestClientPersist(@testPath)

      persist.save(@defaultRequest)
      persist.save(@defaultRequest)

      expect(persist.get().length).toBe(2)

    it "requests are stored", ->
      persist = new RestClientPersist(@testPath)
      requestsLoaded = 0

      persist.clear()
      persist.save(@defaultRequest)
      persist.save(@defaultRequest)
      persist.load (err, requests) =>
        requestsLoaded = JSON.parse(requests).length
      waitsFor ->
        requestsLoaded > 0

      runs ->
        expect(requestsLoaded).toBe(2)

    it "requests list can be limited", ->
      persist = new RestClientPersist(@testPath)
      requestsLoaded = 0

      persist.save(@defaultRequest)
      persist.save(@defaultRequest)

      expect(persist.get(1).length).toBe(1)
      expect(persist.get(2).length).toBe(2)

    it "requests get removed", ->
      persist = new RestClientPersist(@testPath)
      requestsLoaded = 0

      persist.clear()
      persist.save(@defaultRequest)
      persist.remove(@defaultRequest)

      expect(persist.get().length).toBe(0)
