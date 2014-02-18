# Flying Widgets v0.1.1
#
# To use, put this file in assets/javascripts/cycleDashboard.coffee.  Then find this line in
# application.coffee:
#
#         $('.gridster ul:first').gridster
#
# And change it to:
#
#         $('.gridster > ul').gridster
#
# Finally, put multiple gridster divs in your dashboard, and add a call to Dashing.cycleDashboards()
# to the javascript at the top of your dashboard:
#
#     <script type='text/javascript'>
#     $(function() {
#       Dashing.widget_base_dimensions = [370, 340]
#       Dashing.numColumns = 5
#       Dashing.cycleDashboards({timeInSeconds: 15, stagger: true});
#     });
#     </script>
#
#     <% content_for :title do %>Loop Dashboard<% end %>
#
#     <div class="gridster">
#       <ul>
#         <!-- Page 1 of widgets goes here. -->
#         <li data-row="1" data-col="1" data-sizex="1" data-sizey="1">
#           <div data-view="Image" data-image="/inverted-logo.png" style="background-color:#666766"></div>
#         </li>
#
#       </ul>
#     </div>
#
#     <div class="gridster">
#       <ul>
#         <!-- Page 2 of widgets goes here. -->
#       </ul>
#     </div>
#

# Some generic helper functions
sleep = (timeInSeconds, fn) -> setTimeout fn, timeInSeconds * 1000
isArray = (obj) -> Object.prototype.toString.call(obj) is '[object Array]'
isString = (obj) -> Object.prototype.toString.call(obj) is '[object String]';
isFunction = (obj) -> obj && obj.constructor && obj.call && obj.apply

# Move an element from one place to another using a CSS3 transition.
#
# * `elements` - One or more elements to move, in an array.
# * `transition` - The transition string to apply (e.g.: 'left 1s ease 0s')
# * `start` - This can be an object (e.g. `{left: 0px}`) or a `fn($el, index)`
#   which returns such an object.  This is the location the object will start at.
#   If start is omitted, then the current location of the object will be used
#   as the start.
# * `end` - As with `start`, this can be an object or a function.  `end` is required.
# * `timeInSeconds` - The time required to complete the transition.  This function will
#   wait this long before calling `done()`.
# * `offset` is an offset for the index passed into `start()` and `end()`.  Handy when
#   you want to split up an array of
# * `done()` - Async callback.
moveWithTransition = (elements, {transition, start, end, timeInSeconds, offset}, done) ->
    transition = transition or ''
    timeInSeconds = timeInSeconds or 0
    end = end or {}
    offset = offset or 0

    origTransitions = []
    moveToStart = () ->
        for el, index in elements
            $el = $(el)
            origTransitions[index + offset] = $el.css 'transition'
            $el.css transition: 'left 0s ease 0s'
            $el.css(if isFunction start then start($el, index + offset) else start)

    moveToEnd = () ->
        for el, index in elements
            $el = $(el)
            $el.css transition: transition
            $el.css(if isFunction end then end($el, index + offset) else end)
        sleep Math.max(0, timeInSeconds), ->
            $el.css transition: origTransitions[index + offset]
            done? null

    if start
        moveToStart()
        sleep 0, -> moveToEnd()
    else
        moveToEnd()

# Cycle the dashboard to the next dashboard.
#
# If a transition is already in progress, this function does nothing.
Dashing.cycleDashboardsNow = do () ->
    transitionInProgress = false
    visibleIndex = 0
    (options = {}) ->
        return if transitionInProgress
        transitionInProgress = true

        {stagger, fastTransition} = options
        stagger = !!stagger
        fastTransition = !!fastTransition

        $dashboards = $('.gridster')

        # Work out which dashboard to show
        oldVisibleIndex = visibleIndex
        visibleIndex++
        if visibleIndex >= $dashboards.length
            visibleIndex = 0

        if oldVisibleIndex == visibleIndex
            # Only one dashboard.  Disable fast transitions
            fastTransition = false

        doneCount = 0
        doneFn = () ->
            doneCount++
            # Only set transitionInProgress to false when both the show and the hide functions
            # are finished.
            if doneCount is 2
                transitionInProgress = false


        newDashboard = $($dashboards[visibleIndex])
        oldDashboard = $($dashboards[oldVisibleIndex])

        # moveWithTransition newDashboard, {
        #     transition: 'all 500ms',
        #     start: {
        #         transform: 'translateX(100%)',
        #         "-webkit-transform": 'translateX(100%)'
        #     },
        #     end: {
        #         transform: 'translateX(0)',
        #         "-webkit-transform": 'translateX(0)'
        #     },
        #     timeInSeconds: 0.5
        # }, ->
        #     doneFn()

        # moveWithTransition oldDashboard, {
        #     transition: 'all 500ms',
        #     end: {
        #         transform: 'translateX(-100%)',
        #         "-webkit-transform": 'translateX(-100%)'
        #     },
        #     timeInSeconds: 0.5
        # }, ->
        #     oldDashboard.hide()
        #     doneFn()

        # 100% works only with fullscreen

        newDashboard.css('left', '100%')
        newDashboard.show()
        newDashboard.animate {
            left: 0
        }, {
            complete: ->
                doneFn()
        }

        oldDashboard.animate {
            left: '-100%'
        }, {
            complete: ->
                oldDashboard.hide
                doneFn()
        }

        return null

# Adapted from http://stackoverflow.com/questions/1403888/get-url-parameter-with-javascript-or-jquery
getURLParameter = (name) ->
    encodedParameter = (RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[null,null])[1]
    return if encodedParameter? then decodeURI(encodedParameter) else null

# Cause dashing to cycle from one dashboard to the next.
#
# Dashboard cycling can be bypassed by passing a "page" parameter in the url.  For example,
# going to http://dashboardserver/mydashboard?page=2 will show the second dashboard in the list
# and will not cycle.
#
# Options:
# * `timeInSeconds` - The time to display each dashboard, in seconds.  If 0, then dashboards will
#   not automatically cycle, but can be cycled manually by calling `cycleDashboardsNow()`.
# * `stagger` - If this is true, each widget will be transitioned individually at slightly
#   randomized times.  This gives a more random look.  If false, then all wigets will be moved
#   at the same time.  Note if `timeInSeconds` is 0, then this option is ignored (but can, instead,
#   be passed to `cycleDashboardsNow()`.)
# * `fastTransition` - If true, then we will run the show and hide transitions simultaneously.
#   This gets your new dashboard up onto the screen faster.
# * `onTransition($newDashboard)` - A function to call before a dashboard is displayed.
#
Dashing.cycleDashboards = (options) ->
    timeInSeconds = if options.timeInSeconds? then options.timeInSeconds else 20

    $dashboards = $('.gridster')

    startDashboardParam = getURLParameter('page')
    startDashboard = parseInt(startDashboardParam) or 1
    startDashboard = Math.max startDashboard, 1
    startDashboard = Math.min startDashboard, $dashboards.length

    $dashboards.each (dashboardIndex, dashboard) ->
        # Hide all but the first dashboard.
        $(dashboard).toggle(dashboardIndex is (startDashboard - 1))

        # Set all dashboards to position: absolute so they stack one on top of the other
        $(dashboard).css "position": "absolute"

    # If the user specified a dashboard, then don't cycle from one dashboard to the next.
    if !startDashboardParam? and (timeInSeconds > 0)
        cycleFn = () -> Dashing.cycleDashboardsNow(options)
        setInterval cycleFn, timeInSeconds * 1000

    $(document).keypress (event) ->
        # Cycle to next dashboard on space
        if event.keyCode is 32 then Dashing.cycleDashboardsNow(options)
        return true

# Customized version of `Dashing.gridsterLayout()` which supports multiple dashboards.
Dashing.cycleGridsterLayout = (positions) ->
    #positions = positions.replace(/^"|"$/g, '') # ??
    positions = JSON.parse(positions)
    $dashboards = $(".gridster > ul")
    if isArray(positions) and ($dashboards.length == positions.length)
        Dashing.customGridsterLayout = true
        for position, index in positions
            $dashboard = $($dashboards[index])
            widgets = $dashboard.children("[data-row^=]")
            for widget, index in widgets
                $(widget).attr('data-row', position[index].row)
                $(widget).attr('data-col', position[index].col)
    else
        console.log "Warning: Could not apply custom layout!"

# Redefine functions for saving layout
sleep 0.1, () ->
    Dashing.getWidgetPositions = ->
        dashboardPositions = []
        for dashboard in $(".gridster > ul")
            dashboardPositions.push $(dashboard).gridster().data('gridster').serialize()
        return dashboardPositions

    Dashing.showGridsterInstructions = ->
        newWidgetPositions = Dashing.getWidgetPositions()

        if !isArray(newWidgetPositions[0])
            $('#save-gridster').slideDown()
            $('#gridster-code').text("
                Something went wrong - reload the page and try again.
            ")
        else
            unless JSON.stringify(newWidgetPositions) == JSON.stringify(Dashing.currentWidgetPositions)
                Dashing.currentWidgetPositions = newWidgetPositions
                $('#save-gridster').slideDown()
                $('#gridster-code').text("
                  <script type='text/javascript'>\n
                  $(function() {\n\n
                  \ \ Dashing.cycleGridsterLayout('#{JSON.stringify(Dashing.currentWidgetPositions)}')\n
                  });\n
                  </script>
                ")
