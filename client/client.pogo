attachFastClick = require 'fastclick'
attachFastClick (document.body)

document.body.addEventListener "ontouchstart" @(event)
  event.preventDefault()
  event.stopPropagation()

plastiq = require 'plastiq'
app = (require './app')()

plastiq.attach (document.body, app.render, app.model)
