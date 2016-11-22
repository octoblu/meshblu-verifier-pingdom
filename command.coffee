_              = require 'lodash'
elasticsearch  = require 'elasticsearch'
SigtermHandler = require 'sigterm-handler'
OctobluRaven   = require 'octoblu-raven'
Server         = require './src/server'

MISSING_ENV = 'Missing required environment variable:'

class Command
  constructor: ->
    @octobluRaven = new OctobluRaven()

  handleErrors: =>
    @octobluRaven.patchGlobal()

  panic: (error) =>
    @octobluRaven.reportError(error)
    console.error error.stack
    process.exit 1

  run: =>
    # Use this to require env
    @panic new Error("#{MISSING_ENV} ELASTICSEARCH_URI")   if _.isEmpty process.env.ELASTICSEARCH_URI
    @panic new Error("#{MISSING_ENV} ELASTICSEARCH_INDEX") if _.isEmpty process.env.ELASTICSEARCH_INDEX
    @panic new Error("#{MISSING_ENV} HTTP_USERNAME")       if _.isEmpty process.env.HTTP_USERNAME
    @panic new Error("#{MISSING_ENV} HTTP_PASSWORD")       if _.isEmpty process.env.HTTP_PASSWORD

    server = new Server
      octobluRaven:       @octobluRaven
      elasticsearch:      elasticsearch.Client host: process.env.ELASTICSEARCH_URI
      elasticsearchIndex: process.env.ELASTICSEARCH_INDEX
      port:               process.env.PORT || 80
      disableLogging:     process.env.DISABLE_LOGGING == "true"
      username:           process.env.HTTP_USERNAME
      password:           process.env.HTTP_PASSWORD

    server.run (error) =>
      return @panic error if error?
      {port} = server.address()
      console.log "MeshbluVerifierPingdomService listening on port: #{port}"

    sigtermHandler = new SigtermHandler { events: ['SIGTERM', 'SIGINT'] }
    sigtermHandler.register server.stop

command = new Command()
command.handleErrors()
command.run()
