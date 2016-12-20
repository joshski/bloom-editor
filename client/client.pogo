attachFastClick = require 'fastclick'
attachFastClick (document.body)

document.body.addEventListener "ontouchstart" @(event)
  event.preventDefault()
  event.stopPropagation()

hyperdom = require 'hyperdom'
app = (require './app')()

hyperdom.append (document.body, app.render, app.model)
