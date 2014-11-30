util        = require "util"
fs          = require "fs"
debug       = require("debug")("Huemidoro:Huemidoro")
packageJson = require "../package.json"
# hue         = require "node-hue-api"
hue         = require "node-hue-api"
HueApi      = require("node-hue-api").HueApi
Ratestate   = require "ratestate"
lightState = hue.lightState

class Huemidoro
  _config:
    fileConfig: "#{__dirname}/../data/config.json"

  constructor: (config) ->
    if config?
      for key, val of config
        @_config[key] = val

  version: (file, cb) ->
    stdout  = ""
    stderr  = ""
    stderr += "v#{packageJson.version}"
    cb null, stdout, stderr

  help: (file, cb) ->
    stdout  = ""
    stderr  = ""
    stderr += "#{packageJson.name} v#{packageJson.version}\n"
    stderr += " \n"
    stderr += " Usage:\n"
    stderr += " \n"
    stderr += "   #{packageJson.name} action [args]\n"
    stderr += " \n"
    stderr += " Actions:\n"
    stderr += " \n"
    stderr += "   register         Register this app with your bridge\n"
    stderr += "      start         Run indefinitely\n"
    stderr += "    version         Reports version\n"
    stderr += "       help         This page\n"
    stderr += "\n"
    stderr += " More info: https://github.com/kvz/huemidoro\n"

    cb null, stdout, stderr

  _loadConfig: (cb) ->
    debug util.inspect @_config

    fs.readFile @_config.fileConfig, "utf-8", (err, buf) =>
      if err
        return cb "Unable to load file #{@_config.fileConfig}. #{err}"

      try
        config = JSON.parse(buf)
      catch e
        return cb "Unable to decode JSON #{e}"

      if !config?.user?
        return cb "Invalid configuration"

      cb null, config

  register: (file, cb) ->
    config = {}
    hue.locateBridges (err, bridges) =>
      if err
        return cb err

      debug "Hue Bridges Found: "
      debug util.inspect bridges
      config.bridges = bridges

      api = new HueApi
      api.registerUser bridges[0].ipaddress, "huemidoro", "Change lights for pomodoro breaks", (err, user) =>
        if err
          return cb err

        debug "User: "
        debug util.inspect user
        config.user = user

        fs.writeFileSync @_config.fileConfig, JSON.stringify(config)
        stdout = "Written #{@_config.fileConfig}"

        cb null, stdout

  start: (file, cb) ->
    @_loadConfig (err, config) =>
      if err
        return cb "No valid config present. First press Link Button on device and run `register`. #{err}"

      @api = new HueApi config.bridges[0].ipaddress, config.user
      @api.getFullState (err, fullState) =>
        if err
          return cb err

        ratestate = new Ratestate
          interval: 30
          worker  : (id, state, cb) =>
            debug "Setting lamp #{id} state"
            @api.setLightState id, state, (err, okay) =>
              if err
                throw err

              debug util.inspect
                okay: okay
              cb null

        ratestate.start()
        for id, light of fullState.lights
          if !light?.state?.reachable
            continue

          state = lightState.create().on().white(500, 100)
          state = lightState.create().off()
          ratestate.setState id, state

          # https://www.npmjs.org/package/node-hue-api
          # 

          # debug "Full State: "
          # debug util.inspect fullState.lights


module.exports = Huemidoro
