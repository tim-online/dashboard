class Dashing.Table extends Dashing.Widget

  ready: ->
    @limit = parseInt($(@node).attr('data-limit'))
    el = $(@node)
    el.append('<div class="holder" />')
    @initPagination()

  onData: (data) ->
    @initPagination()

  initPagination: ->
    el = $(@node)
    $(el.find('.holder')).jPages({
        container: $(el.find('tbody')),
        perPage: @limit,
        pause: 10000,
        clickStop: true,
        previous: false,
        next: false,
        animation: false
    })
