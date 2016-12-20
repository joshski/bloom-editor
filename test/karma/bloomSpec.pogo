createApp = require '../../client/app'

$ = require 'jquery'
chai = require 'chai'
retry = require 'trytryagain'
require 'jquery-sendkeys'
hyperdom = require 'hyperdom'

expect = chai.expect

describe 'bloom'
  div = nil
  app = nil

  beforeEach
    $('.test').remove()
    div := $('<div class="test"/>').appendTo(document.body)
    app := createApp ()
    hyperdom.append(div.0, app.render, app.model)

  find (selector) =
    $(div).find(selector)

  click (selector) =
    retry!
      expect(find(selector).length).to.eql(1, "could not find '#(selector) in... #(div.html())'")

    find(selector).click()!

  describe 'program'
    it 'is rendered'
      expect(find(".program").length).to.equal 1

    it 'is selectable via the crumb trail'
      click(find(".crumb .text"))!
      retry
        expect(find(".program.selected").length).to.equal 1

    it 'adds undefined statements'
      click '.crumb .text:first' !
      click '.delete-all' !
      click '.add-statement' !
      retry!
        expect(find(".program").text()).to.equal 'undefined'
