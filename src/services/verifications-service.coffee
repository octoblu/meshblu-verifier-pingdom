class VerificationsService
  constructor: ({@client}) ->
    throw new Error 'Missing required parameter: client' unless @client?

  create: ({name, success, expires}, callback) =>
    @client.lpush "verifications:#{name}", JSON.stringify({name, success, expires}), callback

  getLatest: ({name}, callback) =>
    @client.lindex "verifications:#{name}", 0, (error, verificationStr) =>
      return callback error if error?
      return callback null unless verificationStr?
      {name, success, expires} = JSON.parse(verificationStr)
      return callback null, {name, success, expires}

module.exports = VerificationsService
