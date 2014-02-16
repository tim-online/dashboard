class Dashing.Zendesk extends Dashing.Widget

  ready: ->
    @currentIndex = -1
    @commentElem = $(@node).find('.comment-container')
    @nextComment()
    @startCarousel()

  onData: (data) ->
    @currentIndex = -1

  startCarousel: ->
    setInterval(@nextComment, 8000)

  nextComment: =>
    items = @get('items')
    if items
      limit = $(@node).attr('data-limit')
      limit = "5" if not limit
      pagesCount = Math.ceil(items.length/limit)

      @commentElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % pagesCount
        tickets = items.slice(@currentIndex*limit, (@currentIndex+1)*limit)

        for k,v of tickets
          label = v.label.substring(0, 100)
          if label != v.label
            v.label = label + '...'

        @set 'tickets', tickets
        @commentElem.fadeIn()
