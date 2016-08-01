_             = require 'lodash'
OctobluRaven  = require 'octoblu-raven'
Redis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'
Server        = require './src/server'

class Command
  constructor: ->
    @octobluRaven = new OctobluRaven()

  handleErrors: =>
    @octobluRaven.patchGlobal()

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    # Use this to require env
    @panic new Error('Missing required environment variable: REDIS_URI') if _.isEmpty process.env.REDIS_URI
    @panic new Error('Missing required environment variable: REDIS_NAMESPACE') if _.isEmpty process.env.REDIS_NAMESPACE
    @panic new Error('Missing required environment variable: USERNAME')  if _.isEmpty process.env.USERNAME
    @panic new Error('Missing required environment variable: PASSWORD')  if _.isEmpty process.env.PASSWORD

    server = new Server
      octobluRaven:   @octobluRaven
      client:         @_getClient process.env.REDIS_URI, process.env.REDIS_NAMESPACE
      port:           process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"
      username:       process.env.USERNAME
      password:       process.env.PASSWORD

    server.run (error) =>
      return @panic error if error?

      {port} = server.address()
      console.log "MeshbluVerifierPingdomService listening on port: #{port}"

    process.on 'SIGTERM', =>
      console.log 'SIGTERM caught, exiting'
      server.stop =>
        process.exit 0

  _getClient: (uri, namespace) =>
    new RedisNS namespace, new Redis(uri, dropBufferSupport: true)

command = new Command()
command.handleErrors()
command.run()
