###
js!requires:
  - vendor/jquery-1.6.4.js
  - jQuery.ajaxJSON
###

# AJAX Backoff poller
#
# Repeatedly do a given AJAX call until a condition is met or the max number
# of attempts has been reached. Each subsequent call will back off further and
# further.
#
# stop/continue/restart behavior is controlled by the return value of the
# handler function (just return the appropriate string).

define [
  'jquery'
  'jquery.ajaxJSON'
], (jQuery) ->

  class BackoffPoller
    constructor: (@url, @handler, opts={}) ->
      @baseInterval = opts.baseInterval ? 1000
      @backoffFactor = opts.backoffFactor ? 1.5
      @maxAttempts = opts.maxAttempts ? 8

    start: ->
      if @running
        @reset()
      else
        @nextPoll(true)
      this

    'then': (callback) ->
      @callbacks ?= []
      @callbacks.push callback

    reset: ->
      @nextInterval = @baseInterval
      @attempts = 0

    stop: (success=false) ->
      clearTimeout(@running) if @running
      delete @running
      callback() for callback in @callbacks if success and @callbacks
      delete @callbacks

    poll: ->
      @running = true
      @attempts++
      jQuery.ajaxJSON @url, 'GET', {}, (data) =>
        switch @handler(data)
          when 'continue'
            @nextPoll()
          when 'reset'
            @nextPoll(true)
          when 'stop'
            @stop(true)
          else
            @stop()
      , (data) =>
        @stop()

    nextPoll: (reset=false) ->
      if reset
        @reset()
      else
        @nextInterval = parseInt(@nextInterval * @backoffFactor)
      return @stop() if @attempts > @maxAttempts

      @running = setTimeout jQuery.proxy(@poll, this), @nextInterval

