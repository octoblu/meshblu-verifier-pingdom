{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'

redis   = require 'fakeredis'
moment  = require 'moment'
RedisNS = require '@octoblu/redis-ns'
request = require 'request'
uuid    = require 'uuid'

Server = require '../../src/server.coffee'

describe 'Get last Verification', ->
  beforeEach (done) ->
    clientId = uuid.v1()
    @client  = new RedisNS 'meshblu-verifier', redis.createClient(clientId)
    client   = new RedisNS 'meshblu-verifier', redis.createClient(clientId)

    octobluRaven = express: => handleErrors: => (req, res, next) => next()

    @sut     = new Server {client, octobluRaven, disableLogging: true}
    @sut.run done

  afterEach (done) ->
    @sut.stop done

  describe 'GET /verifications/foo/latest', ->
    describe 'when a verification is not expired and successful', ->
      beforeEach (done) ->
        @expiration = moment().add(2, 'minutes').valueOf()
        @client.lpush 'verifications:bob', JSON.stringify({name: 'bob', success: true, expires: @expiration}), done

      beforeEach (done) ->
        options = baseUrl: "http://localhost:#{@sut.address().port}", json: true
        request.get '/verifications/bob/latest', options, (error, @response, @body) =>
          done error

      it 'should respond with a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should respond with the verification', ->
        expect(@body).to.deep.equal {
          name: 'bob'
          success: true
          expires: @expiration
        }

    describe 'when a verification is not expired and unsuccessful', ->
      beforeEach (done) ->
        @expiration = moment().add(2, 'minutes').valueOf()
        @client.lpush 'verifications:bob', JSON.stringify({name: 'bob', success: false, expires: @expiration}), done

      beforeEach (done) ->
        options = baseUrl: "http://localhost:#{@sut.address().port}", json: true
        request.get '/verifications/bob/latest', options, (error, @response, @body) =>
          done error

      it 'should respond with a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should respond with the verification', ->
        expect(@body).to.deep.equal {
          name: 'bob'
          success: false
          expires: @expiration
        }

    describe 'when a verification is expired', ->
      beforeEach (done) ->
        @expiration = moment().subtract(2, 'years').valueOf()
        @client.lpush 'verifications:bob', JSON.stringify({name: 'bob', success: true, expires: @expiration}), done

      beforeEach (done) ->
        options = baseUrl: "http://localhost:#{@sut.address().port}", json: true
        request.get '/verifications/bob/latest', options, (error, @response, @body) =>
          done error

      it 'should respond with a 410', ->
        expect(@response.statusCode).to.equal 410

      it 'should respond with an error', ->
        expect(@body).to.deep.equal {
          error: 'Verification was found, but was expired'
        }

    describe 'when a verification does not exist', ->
      beforeEach (done) ->
        options = baseUrl: "http://localhost:#{@sut.address().port}", json: true
        request.get '/verifications/non-extant/latest', options, (error, @response, @body) =>
          done error

      it 'should respond with a 404', ->
        expect(@response.statusCode).to.equal 404

      it 'should respond with an error', ->
        expect(@body).to.deep.equal {
          error: 'Verification was not found'
        }
