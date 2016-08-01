class MeshbluVerifierPingdomController
  constructor: ({@meshbluVerifierPingdomService}) ->

  hello: (request, response) =>
    {hasError} = request.query
    @meshbluVerifierPingdomService.doHello {hasError}, (error) =>
      return response.sendError(error) if error?
      response.sendStatus(200)

module.exports = MeshbluVerifierPingdomController
