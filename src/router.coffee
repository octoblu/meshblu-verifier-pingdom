VerificationsController = require './controllers/verifications-controller'

class Router
  constructor: ({@verificationsService}) ->
    @verificationsController = new VerificationsController {@verificationsService}

  route: (app) =>
    app.post '/verifications/:name', @verificationsController.create
    app.get  '/verifications/:name/latest', @verificationsController.getLatest

module.exports = Router
