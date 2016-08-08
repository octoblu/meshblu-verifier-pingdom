_      = require 'lodash'
moment = require 'moment'

class VerificationsService
  constructor: ({@elasticsearch, @elasticsearchIndex}) ->
    throw new Error 'Missing required parameter: elasticsearch' unless @elasticsearch?
    throw new Error 'Missing required parameter: elasticsearchIndex' unless @elasticsearchIndex?

  create: ({name, success, expires}, callback) =>
    record = @_buildRecord({name, success, expires})

    @elasticsearch.create record, (error) =>
      callback error


  getLatest: ({name}, callback) =>
    query = {
      index: "#{@elasticsearchIndex}*"
      type: name
      body:
        sort: [{"metadata.expires": order: "desc"}]
    }

    @elasticsearch.search query, (error, response) =>
      return callback error if error?
      return callback() if _.isEmpty response.hits?.hits

      {name, success, expires} = response.hits.hits[0]._source.metadata
      callback null, {name, success, expires}

  _buildRecord: ({name, success, expires}) =>
    dateStr = moment().format("YYYY-MM-DD")
    return {
      index: "#{@elasticsearchIndex}-#{dateStr}"
      type: name
      date: moment().valueOf()
      body:
        metadata: {name, success, expires}
    }

module.exports = VerificationsService
