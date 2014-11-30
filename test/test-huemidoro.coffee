should      = require("chai").should()
debug       = require("debug")("Huemidoro:test-huemidoro")
util        = require "util"
fs          = require "fs"
expect      = require("chai").expect
fixture_dir = "#{__dirname}/fixtures"
Huemidoro   = require "../src/Huemidoro"

describe "Huemidoro", ->
  @timeout 10000 # <-- This is the Mocha timeout, allowing tests to run longer

  describe "setState", ->
    it "should set last item", (done) ->
      huemidoro = new Huemidoro

      huemidoro.setState 1, color: "red"

      huemidoro.setState 1, color: "green"

      huemidoro.setState 1, color: "purple"

      state = huemidoro.getState 1

      expect(state).to.deep.equal
        color: "purple"

      done()

  describe "start", ->
    it "should start interval", (done) ->
      stopAfter   = 1000 # 1 sec
      errorMargin = .20  # Allow timing to be 20 % off
      calls       = {}
      colored     = {}
      config      =
        interval: 30
        worker  : (id, state, cb) ->
          colored[id]  = state.color
          calls[id] ?= 0
          calls[id]++
          debug "Setting lamp #{id} to #{state.color}"
          cb null

      expectedCalls = Math.floor(stopAfter / config.interval)
      maxDifference = Math.floor(expectedCalls * errorMargin)

      huemidoro = new Huemidoro config
      huemidoro.setState 1, color: "purple"

      huemidoro.setState 2, color: "green"

      setState = (id, state, delay) ->
        setTimeout ->
          debug "setState #{state.color} in #{delay}ms"
          huemidoro.setState 2, state
        , delay

      for color, indx in [ "orange", "pink", "blue", "navy", "navy", "maroon", "yellow" ]
        setState 2, color: color, Math.floor(stopAfter * .20) + (10 * (indx + 1))

      huemidoro.start()

      setTimeout ->
        huemidoro.stop()
        expect(calls[1]).to.equal 1
        expect(colored[1]).to.equal "purple"

        expect(calls[2]).to.be.within 3, 5
        expect(colored[2]).to.equal "yellow"
        done()
      , stopAfter

