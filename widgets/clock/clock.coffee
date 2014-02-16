class Dashing.Clock extends Dashing.Widget

  ready: ->
    setInterval(@startTime, 500)

  startTime: =>
    today = new Date()

    h = today.getHours()
    m = today.getMinutes()
    s = today.getSeconds()
    m = @formatTime(m)
    s = @formatTime(s)
    options = {
      weekday: "long",
      year: "numeric",
      month: "short",
      day: "numeric"
    }
    @set('time', h + ":" + m + ":" + s)
    @set('date', today.toLocaleDateString('nl-NL', options))

  formatTime: (i) ->
    if i < 10 then "0" + i else i
