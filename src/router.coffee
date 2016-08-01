MeshbluVerifierPingdomController = require './controllers/meshblu-verifier-pingdom-controller'

class Router
  constructor: ({@meshbluVerifierPingdomService}) ->

  route: (app) =>
    meshbluVerifierPingdomController = new MeshbluVerifierPingdomController {@meshbluVerifierPingdomService}

    app.get '/hello', meshbluVerifierPingdomController.hello
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
