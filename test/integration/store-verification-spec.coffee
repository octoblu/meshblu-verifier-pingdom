{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'
sinon    = require 'sinon'

_       = require 'lodash'
moment  = require 'moment'
request = require 'request'

Server = require '../../src/server.coffee'

describe 'Store Verification', ->
  beforeEach (done) ->
    @elasticsearch = create: sinon.stub()
    @logFn = sinon.spy()

    @sut = new Server {
      @elasticsearch
      @logFn,
      disableLogging: true
      elasticsearchIndex: 'verification:meshblu-protocol'
      username: 'bobby'
      password: 'drop tables'
    }
    @sut.run done

  afterEach (done) ->
    @sut.destroy done

  describe 'POST /verifications/foo/', ->
    describe 'when called', ->
      beforeEach (done) ->
        @elasticsearch.create.yields null
        @expiration = moment().add(2, 'minutes').utc().format()

        options =
          baseUrl: "http://localhost:#{@sut.address().port}"
          auth: {username: 'bobby', password: 'drop tables'}
          json:
            success: true
            expires: @expiration
            error:
              message: 'uh oh'
              step: 'register'

        request.post '/verifications/foo', options, (error, @response) => done error

      it 'should respond with a 201', ->
        expect(@response.statusCode).to.equal 201

      it 'should store the verification in elasticsearch', ->
        dateStr = moment().format "YYYY-MM-DD"

        expect(@elasticsearch.create).to.have.been.called

        arg = _.first @elasticsearch.create.firstCall.args
        now = moment().valueOf()

        expect(arg).to.containSubset {
          index: "verification:meshblu-protocol-#{dateStr}"
          type: 'foo'
          body: {
            index: "verification:meshblu-protocol-#{dateStr}"
            type: 'foo'
            metadata:
              name: 'foo'
              success: true
              expires: @expiration
            data:
              error:
                message: 'uh oh'
                step: 'register'
          }
        }
        expect(arg.body.date).to.be.closeTo now, 100
