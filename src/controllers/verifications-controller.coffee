class VerificationsController
  constructor: ({@verificationsService}) ->

  create: (request, response) =>
    @verificationsService.create { name: request.params.name, success: request.body.success }, (error) =>
      return response.sendError error if error?
      response.sendStatus(201)

module.exports = VerificationsController
