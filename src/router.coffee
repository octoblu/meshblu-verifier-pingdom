VerificationsController = require './controllers/verifications-controller'

class Router
  constructor: ({@verificationsService}) ->
    @verificationsController = new VerificationsController {@verificationsService}

  route: (app) =>
    app.post '/verifications/:name', @verificationsController.create

module.exports = Router
