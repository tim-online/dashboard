class Dashing.Table extends Dashing.Widget

  ready: ->
    @currentIndex = 0
    @container = $(@node).find('table')
    @limit = $(@node).attr('data-limit')

    if @limit
      @set 'all_rows', @get('rows')
      @set 'rows', @dataSet(@get('all_rows'), @currentIndex, @limit)
      @startCarousel()

  onData: (data) ->
    @currentIndex = 0

  startCarousel: ->
    setInterval(@nextPane, 8000)

  pagesCount: ->
    allRows = @get('all_rows')
    limit = @limit
    return Math.ceil(allRows.length/limit)

  nextPane: =>
    allRows = @get('all_rows')
    pagesCount = @pagesCount()
    rows = @dataSet(allRows, @currentIndex, @limit)

    @container.fadeOut =>
      @currentIndex = (@currentIndex + 1) % pagesCount
      @set 'rows', rows
      @container.fadeIn()

  dataSet: (items, index, limit) ->
    return items.slice(index*limit, (index+1)*limit)
