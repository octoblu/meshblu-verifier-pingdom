class VerificationsService
  constructor: ({@client}) ->
    throw new Error 'Missing required parameter: client' unless @client?

  create: (verification, callback) =>
    @client.lpush 'verifications:foo', JSON.stringify(verification), callback


module.exports = VerificationsService
