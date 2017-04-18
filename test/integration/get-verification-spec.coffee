{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'
sinon    = require 'sinon'

_       = require 'lodash'
moment  = require 'moment'
request = require 'request'

Server = require '../../src/server.coffee'

describe 'Get Verification', ->
  beforeEach (done) ->
    @elasticsearch = search: sinon.stub()
    @logFn = sinon.spy()
    @sut = new Server {
      @elasticsearch
      elasticsearchIndex: 'lily-huwnesu'
      disableLogging: true
      username: 'billy'
      password: 'goat'
      port: 0xd00d
      @logFn
    }
    @sut.run done

  afterEach (done) ->
    @sut.stop done

  beforeEach ->
    @requestDefaults =
      baseUrl: "http://localhost:#{@sut.address().port}"
      json: true
      auth: {username: 'billy', password: 'goat'}

  describe 'GET /verifications/foo/latest', ->
    describe 'when a verification is not expired and successful', ->
      beforeEach (done) ->
        @expiration = moment().add(2, 'minutes').utc().format()

        @elasticsearch.search.yields null, hits: hits: [{
          _index: 'lily-huwnesu-2016-08-08'
          _type: 'foo'
          _source:
            metadata:
              name: 'bob'
              success: true
              expires: @expiration
        }]

        request.get '/verifications/bob/latest', @requestDefaults, (error, @response, @body) =>
          done error

      it 'should respond with a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should respond with the verification', ->
        expect(@body).to.deep.equal {
          name: 'bob'
          success: true
          expires: @expiration
        }

      it 'should call elasticsearch.search', ->
        expect(@elasticsearch.search).to.have.been.calledOnce

        arg = _.first @elasticsearch.search.firstCall.args

        expect(arg).to.deep.equal {
          index: 'lily-huwnesu*'
          type: 'bob'
          body:
            sort: [{"metadata.expires": order: "desc"}]
        }

    describe 'when a verification is not expired and unsuccessful', ->
      beforeEach (done) ->
        @expiration = moment().add(2, 'minutes').utc().format()

        @elasticsearch.search.yields null, hits: hits: [{
          _index: 'lily-huwnesu-2016-08-08'
          _type: 'foo'
          _source:
            metadata:
              name: 'bob'
              success: false
              expires: @expiration
        }]

        request.get '/verifications/bob/latest', @requestDefaults, (error, @response, @body) =>
          done error

      it 'should respond with a 424', ->
        expect(@response.statusCode).to.equal 424

      it 'should respond with the verification', ->
        expect(@body.error).to.equal 'Verification was found, but failed'

    describe 'when a verification is expired', ->
      beforeEach (done) ->
        @expiration = moment().subtract(2, 'years').utc().format()

        @elasticsearch.search.yields null, hits: hits: [{
          _index: 'lily-huwnesu-2016-08-08'
          _type: 'foo'
          _source:
            metadata:
              name: 'bob'
              success: false
              expires: @expiration
        }]

        request.get '/verifications/bob/latest', @requestDefaults, (error, @response, @body) =>
          done error

      it 'should respond with a 410', ->
        expect(@response.statusCode).to.equal 410

      it 'should respond with an error', ->
        expect(@body).to.deep.equal {
          error: 'Verification was found, but was expired'
        }

    describe 'when a verification does not exist', ->
      beforeEach (done) ->
        @elasticsearch.search.yields null, hits: hits: []

        request.get '/verifications/non-extant/latest', @requestDefaults, (error, @response, @body) =>
          done error

      it 'should respond with a 404', ->
        expect(@response.statusCode).to.equal 404

      it 'should respond with an error', ->
        expect(@body).to.deep.equal {
          error: 'Verification was not found'
        }

  describe 'GET /v2/verifications/foo/latest', ->
    describe 'when a verification is not expired and successful', ->
      beforeEach (done) ->
        @expiration = moment().add(2, 'minutes').utc().format()

        @elasticsearch.search.yields null, hits: hits: [{
          _index: 'lily-huwnesu-2016-08-08'
          _type: 'foo'
          _source:
            metadata:
              name: 'bob'
              success: true
              expires: @expiration
        }]

        request.get '/v2/verifications/bob/latest', @requestDefaults, (error, @response, @body) =>
          done error

      it 'should respond with a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should respond with the verification', ->
        expect(@response.body).to.deep.equal {
          name: 'bob'
          success: true
          expires: @expiration
        }

      it 'should call elasticsearch.search', ->
        expect(@elasticsearch.search).to.have.been.calledOnce

        arg = _.first @elasticsearch.search.firstCall.args

        expect(arg).to.deep.equal {
          index: 'lily-huwnesu*'
          type: 'bob'
          body:
            sort: [{"metadata.expires": order: "desc"}]
        }

    describe 'when a verification is not expired and unsuccessful', ->
      beforeEach (done) ->
        @expiration = moment().add(2, 'minutes').utc().format()

        @elasticsearch.search.yields null, hits: hits: [{
          _index: 'lily-huwnesu-2016-08-08'
          _type: 'foo'
          _source:
            metadata:
              name: 'bob'
              success: false
              expires: @expiration
            data:
              error:
                message:'uh oh'
                step: 'register'
        }]

        request.get '/v2/verifications/bob/latest', @requestDefaults, (error, @response, @body) =>
          done error

      it 'should respond with a 424', ->
        expect(@response.statusCode).to.equal 424

      it 'should respond with verification result', ->
        expect(@body.metadata.error).to.equal("Verification was found, but failed")

      it 'should respond with additional error details', ->
        expect(@body.data).to.deep.equal {
          name: 'bob'
          success: false
          expires: @expiration
          data:
            error:
              message:'uh oh'
              step: 'register'
        }

    describe 'when a verification is expired', ->
      beforeEach (done) ->
        @expiration = moment().subtract(2, 'years').utc().format()

        @elasticsearch.search.yields null, hits: hits: [{
          _index: 'lily-huwnesu-2016-08-08'
          _type: 'foo'
          _source:
            metadata:
              name: 'bob'
              success: false
              expires: @expiration
        }]

        request.get '/v2/verifications/bob/latest', @requestDefaults, (error, @response, @body) =>
          done error

      it 'should respond with a 410', ->
        expect(@response.statusCode).to.equal 410

      it 'should respond with an error', ->
        expect(@body.metadata.error).to.equal ('Verification was found, but was expired')

    describe 'when a verification does not exist', ->
      beforeEach (done) ->
        @elasticsearch.search.yields null, hits: hits: []

        request.get '/v2/verifications/non-extant/latest', @requestDefaults, (error, @response, @body) =>
          done error

      it 'should respond with a 404', ->
        expect(@response.statusCode).to.equal 404

      it 'should respond with an error', ->
        expect(@body.metadata.error).to.equal ('Verification was not found')
