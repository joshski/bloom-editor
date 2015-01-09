express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
session = require 'express-session'

env = require './env'
app = express ()

app.use (cookieParser ())
app.use (bodyParser.urlencoded (extended: false))
app.use (session {
  secret = 'very unusual walking style'
  resave = false
  saveUninitialized = true
})

app.use (express.static 'public')

app.listen (process.env.PORT || 3001)
