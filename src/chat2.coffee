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
    .setMaxListeners Infinity

  queue: []
  pending: ''

  connect: ->
    new Promise (resolve, reject) =>
      timer = setTimeout =>
        reject eTimedOut "Connection timed out #{@host}:#{@port}"
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
        lines = data.split CRLF         # lines may have a "" as the last element
        @pending = lines.pop()            # null unless partial line
        if lines.length
          @queue = @queue.concat lines    # add any lines to the queue
          @emitter.emit 'newline', lines  # and emit for the next waiting expect

  expect: (pattern) ->
    new Promise (resolve, reject) =>
      return reject new Error 'Expect error: No socket' unless @client?
      timer = setTimeout =>
        reject eTimedOut "Expect timed out: #{pattern}"
      , @timeout if @timeout
      getLine = =>
        while @queue.length > 0
          line = @queue.shift()
          if line.match pattern
            clearTimeout timer if timer
            @emitter.removeListener 'newline', getLine
            resolve line
            return true         # Return true if you've resolved
                                # being careful to leave the rest of the queue
      unless getLine()     # Try it once and, if it fails, wait for the event
        @emitter.on 'newline', getLine

  send: (string) ->
    new Promise (resolve, reject) =>
      return reject new Error 'Send error: No socket' unless @client?
      @client.write string + CRLF
      resolve string

  exec: (string, pattern) ->
    return Promise.reject new Error 'string and pattern required' unless string? and pattern?
    @send string
    .then =>
      @expect pattern

  close: ->
    @client?.end()
    @emitter?.removeAllListeners()
    # client will be deleted by the 'end' event

module.exports = Chat2

