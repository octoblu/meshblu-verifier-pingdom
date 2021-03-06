_      = require 'lodash'
moment = require 'moment'
UUID = require 'uuid'
debug = require('debug')('meshblu-verifier-pingdom:verifications-service')

class VerificationsService
  constructor: ({@elasticsearch, @elasticsearchIndex}) ->
    throw new Error 'Missing required parameter: elasticsearch' unless @elasticsearch?
    throw new Error 'Missing required parameter: elasticsearchIndex' unless @elasticsearchIndex?

  create: ({name, success, expires, error}, callback) =>
    record = @_buildRecord({name, success, expires, error})
    debug {record}

    @elasticsearch.create record, (err) =>
      callback err

  getLatest: ({name}, callback) =>
    query = {
      index: "#{@elasticsearchIndex}*"
      type: name
      body:
        sort: [{"metadata.expires": order: "desc"}]
    }

    @elasticsearch.search query, (err, response) =>
      return callback err if err?
      return callback() unless _.has response, 'hits.hits.0._source.metadata'
      return callback() if _.isEmpty response.hits?.hits

      {name, success, expires} = response.hits.hits[0]._source.metadata
      data = response.hits.hits[0]._source.data
      callback null, {name, success, expires, data}

  _buildRecord: ({name, success, expires, error}) =>
    error   = @_sanitizeError error
    dateStr = moment().format("YYYY-MM-DD")
    index   = "#{@elasticsearchIndex}-#{dateStr}"

    return {
      id: UUID.v4()
      index: index
      type: name
      body:
        index: index
        type: name
        date: moment().valueOf()
        metadata: {name, success, expires}
        data: {error}
    }

  _sanitizeError: (error) =>
    return unless error?
    return error if _.isInteger error.code
    return _.omit error, 'code'

module.exports = VerificationsService
