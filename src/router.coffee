VerificationsController = require './controllers/verifications-controller'
VerificationsV2Controller = require './controllers/verifications-v2-controller'

class Router
  constructor: ({@verificationsService}) ->
    @verificationsController = new VerificationsController {@verificationsService}
    @verificationsV2Controller = new VerificationsV2Controller {@verificationsService}

  route: (app) =>
    app.post '/verifications/:name', @verificationsController.create
    app.get  '/verifications/:name/latest', @verificationsController.getLatest

    app.get '/v2/verifications/:name/latest', @verificationsV2Controller.getLatest

module.exports = Router
