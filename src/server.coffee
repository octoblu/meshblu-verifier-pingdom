basicAuth            = require 'basic-auth-connect'
expressOctoblu       = require 'express-octoblu'
enableDestroy        = require 'server-destroy'
VerificationsService = require './services/verifications-service'
Router               = require './router'

class Server
  constructor: (options) ->
    {
      @disableLogging,
      @elasticsearch,
      @elasticsearchIndex,
      @port,
      @username,
      @password,
      @logFn,
    } = options

    throw new Error 'Missing required parameter: elasticsearch' unless @elasticsearch?
    throw new Error 'Missing required parameter: elasticsearchIndex' unless @elasticsearchIndex?
    throw new Error 'Missing required parameter: username' unless @username?
    throw new Error 'Missing required parameter: password' unless @password?

    @verificationsService = new VerificationsService {@elasticsearch, @elasticsearchIndex}

  address: =>
    @server.address()

  run: (callback) =>
    app = expressOctoblu({@disableLogging, @logFn})
    app.use basicAuth @username, @password

    router = new Router {@verificationsService}
    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: (callback) =>
    @server.destroy callback

module.exports = Server
