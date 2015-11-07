RestClientEditor = require '../lib/rest-client-editor'
RestClientResponse = require '../lib/rest-client-response'

describe 'RestClientEditor', ->
  DEFAULT_TEXT = 'body content'
  DEFAULT_FILENAME = 'GET - http://example.com'

  it 'Process filename', ->
    editor = new RestClientEditor(DEFAULT_TEXT, DEFAULT_FILENAME)

    expect(editor.processFilename(DEFAULT_FILENAME)).toEqual('GET - example.com')

  it 'Process filename url with a path', ->
    file_name = DEFAULT_FILENAME + '/path/'
    editor = new RestClientEditor(DEFAULT_TEXT, file_name)
    expect(editor.processFilename(file_name)).toEqual('GET - example.compath')

  it 'Open file', ->
    editor = new RestClientEditor(DEFAULT_TEXT, DEFAULT_FILENAME)
    expect(editor.open()).toEqual(true)

  it 'Not open file, no body content', ->
    text = ""
    editor = new RestClientEditor(text, DEFAULT_FILENAME)

    expect(editor.open()).toEqual(false)

  it 'Not open file, default body', ->
    text = RestClientResponse.DEFAULT_RESULT
    editor = new RestClientEditor(text, DEFAULT_FILENAME)

    expect(editor.open()).toEqual(false)
