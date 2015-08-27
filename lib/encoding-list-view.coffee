fs = require 'fs'
require('buffertools').extend();
{SelectListView} = require 'atom-space-pen-views'

# View to display a list of encodings to use in the current editor.
module.exports =
class EncodingListView extends SelectListView
  initialize: (@encodings) ->
    super

    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @addClass('encoding-selector')
    @list.addClass('mark-active')

  getFilterKey: ->
    'name'

  viewForItem: (encoding) ->
    element = document.createElement('li')
    element.classList.add('active') if encoding.id is @currentEncoding
    element.textContent = encoding.name
    element.dataset.encoding = encoding.id
    element

  detectEncoding: ->
    filePath = @editor.getPath()
    return unless fs.existsSync(filePath)

    jschardet = require 'jschardet'
    iconv = require 'iconv-lite'
    fs.readFile filePath, (error, buffer) =>
      return if error?

      return detectXmlEncoding(buffer) if isXml(buffer)

      {encoding} =  jschardet.detect(buffer) ? {}
      encoding = 'utf8' if encoding is 'ascii'
      return unless iconv.encodingExists(encoding)

      encoding = encoding.toLowerCase().replace(/[^0-9a-z]|:\d{4}$/g, '')
      @editor.setEncoding(encoding)

  isXml: (buffer) ->
    buffer.toString("ascii", 0, 5) == '<?xml'

  detectXmlEncoding: (buffer) ->
    declaration = buffer.toString(0, buffer.indexOf('?>'))
    regex = /^encoding\s*=\s*['"](\w+)['"]$/i
    result = declaration.match(regex)
    encoding = result[0]
    return unless iconv.encodingExists(encoding)

  toggle: ->
    if @panel.isVisible()
      @cancel()
    else if @editor = atom.workspace.getActiveTextEditor()
      @attach()

  destroy: ->
    @panel.destroy()

  cancelled: ->
    @panel.hide()

  confirmed: (encoding) ->
    @cancel()

    if encoding.id is 'detect'
      @detectEncoding()
    else
      @editor.setEncoding(encoding.id)

  addEncodings: ->
    @currentEncoding = @editor.getEncoding()
    encodingItems = []

    if fs.existsSync(@editor.getPath())
      encodingItems.push({id: 'detect', name: 'Auto Detect'})

    for id, names of @encodings
      encodingItems.push({id, name: names.list})
    @setItems(encodingItems)

  attach: ->
    @storeFocusedElement()
    @addEncodings()
    @panel.show()
    @focusFilterEditor()
