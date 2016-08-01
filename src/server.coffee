cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
OctobluRaven       = require 'octoblu-raven'
enableDestroy      = require 'server-destroy'
sendError          = require 'express-send-error'
MeshbluAuth        = require 'express-meshblu-auth'
packageVersion     = require 'express-package-version'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
Router             = require './router'
MeshbluVerifierPingdomService = require './services/meshblu-verifier-pingdom-service'
debug              = require('debug')('meshblu-verifier-pingdom:server')

class Server
  constructor: ({@disableLogging, @port, @meshbluConfig, @octobluRaven})->
    @octobluRaven ?= new OctobluRaven()

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use @octobluRaven.express().handleErrors()
    app.use sendError()
    app.use meshbluHealthcheck()
    app.use packageVersion()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use bodyParser.urlencoded limit: '1mb', extended : true
    app.use bodyParser.json limit : '1mb'

    meshbluAuth = new MeshbluAuth @meshbluConfig
    app.use meshbluAuth.auth()
    app.use meshbluAuth.gateway()

    app.options '*', cors()

    meshbluVerifierPingdomService = new MeshbluVerifierPingdomService
    router = new Router {@meshbluConfig, meshbluVerifierPingdomService}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
