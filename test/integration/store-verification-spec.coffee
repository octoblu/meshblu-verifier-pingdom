{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'

redis   = require 'fakeredis'
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
    beforeEach (done) ->
      options =
        baseUrl: "http://localhost:#{@sut.address().port}"
        json:
          success: true

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
        }
        done()
