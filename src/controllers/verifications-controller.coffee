moment = require 'moment'

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

  getLatest: (request, response) =>
    @verificationsService.getLatest name: request.params.name, (error, verification) =>
      return response.sendError error if error?
      return response.sendError @_verificationNotFound() unless verification?
      return response.sendError @_verificationExpired() if verification.expires < moment().valueOf()
      return response.send verification

  _verificationExpired: =>
    error = new Error("Verification was found, but was expired")
    error.code = 410
    return error

  _verificationNotFound: =>
    error = new Error("Verification was not found")
    error.code = 404
    return error

module.exports = VerificationsController
