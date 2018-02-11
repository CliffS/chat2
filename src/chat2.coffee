net = require 'net'
EventEmitter = require 'events'

CRLF = "\r\n"

eTimedOut = (msg) ->
  err = new Error msg
  err.code = 'ETIMEDOUT'
  err

class Chat2

  constructor: (@host, @port, @timeout) ->
    @port = 23 unless @port?
    throw new TypeError 'host must be a string' unless typeof @host is 'string'
    throw new TypeError 'port must be a number' unless typeof @port is 'number'
    if @timeout?
      throw new TypeError 'timeout (if defined) must be greater than zero' unless @timeout > 0
    @emitter = new EventEmitter()

  queue: []
  pending: ''

  connect: ->
    new Promise (resolve, reject) =>
      timer = setTimeout =>
        reject eTimedOut 'Connection timed out'
        @client?.destroy()
        delete @client
      , @timeout if @timeout
      @client = net.createConnection
        host: @host
        port: @port
      .setEncoding 'utf-8'
      .once 'connect', =>
        clearTimeout timer if timer
        resolve @client.setKeepAlive true
      .once 'error', (err) =>
        clearTimeout timer if timer
        reject err
      .once 'end', =>
        delete @client
      .on 'data', (data) =>
        data = @pending + data
        lines = data.split CRLF
        @pending = lines.pop()        # if it ends with a CRLF, @pending will be ""
        @queue = @queue.concat lines    # doesn't matter if we concat an empty array
        @emitter.emit 'newline', lines if lines.length # but only emit if we added a line

  expect: (pattern) ->
    new Promise (resolve, reject) =>
      return reject new Error 'No socket' unless @client?
      timer = setTimeout =>
        reject eTimedOut 'Expect timed out'
      , @timeout if @timeout
      getLine = =>
        while @queue.length > 0
          line = @queue.shift()
          if line.match pattern
            clearTimeout timer if timer
            @emitter.removeListener 'newline', getLine
            return resolve line
      getLine()     # Try it once and, if it fails, keep trying
      @emitter.on 'newline', getLine

  send: (string) ->
    new Promise (resolve, reject) =>
      return reject new Error 'No socket' unless @client?
      @client.write string + CRLF
      resolve string

  exec: (string, pattern) ->
    return Promise.reject new Error 'string and pattern required' unless string? and pattern?
    @send string
    .then =>
      @expect pattern

  close: ->
    @client.end()
    delete @client

module.exports = Chat2

