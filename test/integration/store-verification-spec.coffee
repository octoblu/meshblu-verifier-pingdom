{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'

redis   = require 'fakeredis'
_       = require 'lodash'
moment  = require 'moment'
RedisNS = require '@octoblu/redis-ns'
request = require 'request'
uuid    = require 'uuid'

Server = require '../../src/server.coffee'

describe 'Store Verification', ->
  beforeEach (done) ->
    clientId = uuid.v1()
    @client  = new RedisNS 'meshblu-verifier', redis.createClient(clientId)
    client   = new RedisNS 'meshblu-verifier', redis.createClient(clientId)

    octobluRaven = express: => handleErrors: => (req, res, next) => next()

    @sut     = new Server {client, octobluRaven, disableLogging: true}
    @sut.run done

  afterEach (done) ->
    @sut.stop done

  describe 'POST /verifications/foo/', ->
    describe 'whith no existing verifications', ->
      beforeEach (done) ->
        @expiration = moment().add(2, 'minutes').valueOf()

        options =
          baseUrl: "http://localhost:#{@sut.address().port}"
          json:
            success: true
            expires: @expiration

        request.post '/verifications/foo', options, (error, @response) => done error

      it 'should respond with a 201', ->
        expect(@response.statusCode).to.equal 201

      it 'should store the verification in redis', (done) ->
        @client.lindex 'verifications:foo', 0, (error, verificationStr) =>
          return done error if error?
          verification = JSON.parse verificationStr
          expect(verification).to.deep.equal {
            name: 'foo'
            success: true
            expires: @expiration
          }
          done()

    describe 'with 1000 existing verifications', ->
      beforeEach (done) ->
        verification  = {name: 'bar', success: true, expires: moment().subtract(1, 'day').valueOf()}
        verifications = _.times 1000, => JSON.stringify(verification)
        @client.lpush 'verifications:bar', verifications..., done

      beforeEach (done) ->
        @expiration = moment().add(2, 'minutes').valueOf()

        options =
          baseUrl: "http://localhost:#{@sut.address().port}"
          json:
            success: true
            expires: @expiration

        request.post '/verifications/bar', options, (error, @response) => done error

      it 'should respond with a 201', ->
        expect(@response.statusCode).to.equal 201

      it 'should store the verification in redis', (done) ->
        @client.lindex 'verifications:bar', 0, (error, verificationStr) =>
          return done error if error?
          verification = JSON.parse verificationStr
          expect(verification).to.deep.equal {
            name: 'bar'
            success: true
            expires: @expiration
          }
          done()

      it 'should remove the 1001th element', (done) ->
        @client.llen 'verifications:bar', (error, count) =>
          return done error if error?
          expect(count).to.equal 1000
          done()
