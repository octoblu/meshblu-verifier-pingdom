class VerificationsController
  constructor: ({@verificationsService}) ->

  create: (request, response) =>
    verification = {
      name:    request.params.name
      success: request.body.success
      expires: request.body.expires
    }

    @verificationsService.create verification, (error) =>
      return response.sendError error if error?
      response.sendStatus(201)

module.exports = VerificationsController
