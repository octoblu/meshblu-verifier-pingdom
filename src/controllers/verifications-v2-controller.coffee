moment = require 'moment'
_      = require 'lodash'

class VerificationsV2Controller
  constructor: ({@verificationsService}) ->

  create: (request, response) =>
    verification = {
      name:    request.params.name
      success: request.body.success
      expires: request.body.expires
      error:   request.body.error
    }

    @verificationsService.create verification, (error) =>
      return response.sendError error if error?
      response.sendStatus(201)

  getLatest: (request, response) =>
    @verificationsService.getLatest name: request.params.name, (error, verification) =>
      return response.sendError error if error?
      
      unless verification?
        return response.status(404).send metadata: {error: 'Verification was not found' }, data:null

      if moment().utc().isAfter(verification.expires)
        return response.status(410).send metadata: {error: 'Verification was found, but was expired'}, data: verification

      unless verification.success
        return response.status(424).send metadata: {error: 'Verification was found, but failed'}, data: verification

      return response.status(200).send verification

module.exports = VerificationsV2Controller
