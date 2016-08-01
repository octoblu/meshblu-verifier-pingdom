class VerificationsService
  constructor: ({@client}) ->
    throw new Error 'Missing required parameter: client' unless @client?

  create: ({name, success, expires}, callback) =>
    @client.lpush @_key({name}), JSON.stringify({name, success, expires}), (error) =>
      return callback error if error?
      @client.ltrim @_key({name}), 0, 999, callback

  getLatest: ({name}, callback) =>
    @client.lindex @_key({name}), 0, (error, verificationStr) =>
      return callback error if error?
      return callback null unless verificationStr?
      {name, success, expires} = JSON.parse(verificationStr)
      return callback null, {name, success, expires}

  _key: ({name}) => "verifications:#{name}"

module.exports = VerificationsService
