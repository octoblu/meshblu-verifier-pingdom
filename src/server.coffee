cors                 = require 'cors'
morgan               = require 'morgan'
express              = require 'express'
bodyParser           = require 'body-parser'
OctobluRaven         = require 'octoblu-raven'
enableDestroy        = require 'server-destroy'
sendError            = require 'express-send-error'
packageVersion       = require 'express-package-version'
meshbluHealthcheck   = require 'express-meshblu-healthcheck'
Router               = require './router'
VerificationsService = require './services/verifications-service'

class Server
  constructor: ({@client, @disableLogging, @port, @octobluRaven})->
    @octobluRaven ?= new OctobluRaven()
    throw new Error 'Missing required parameter: client' unless @client?
    @verificationsService = new VerificationsService {@client}

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
    app.use bodyParser.urlencoded limit: '1mb', extended : true
    app.use bodyParser.json limit : '1mb'

    app.options '*', cors()

    router = new Router {@verificationsService}
    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
