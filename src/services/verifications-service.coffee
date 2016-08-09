_      = require 'lodash'
moment = require 'moment'

class VerificationsService
  constructor: ({@elasticsearch, @elasticsearchIndex}) ->
    throw new Error 'Missing required parameter: elasticsearch' unless @elasticsearch?
    throw new Error 'Missing required parameter: elasticsearchIndex' unless @elasticsearchIndex?

  create: ({name, success, expires, error}, callback) =>
    record = @_buildRecord({name, success, expires, error})

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
      return callback() if _.isEmpty response.hits?.hits

      {name, success, expires} = response.hits.hits[0]._source.metadata
      callback null, {name, success, expires}

  _buildRecord: ({name, success, expires, error}) =>
    dateStr = moment().format("YYYY-MM-DD")
    index   = "#{@elasticsearchIndex}-#{dateStr}"

    return {
      index: index
      type: name
      body:
        index: index
        type: name
        date: moment().valueOf()
        metadata: {name, success, expires}
        data: {error}
    }

module.exports = VerificationsService
