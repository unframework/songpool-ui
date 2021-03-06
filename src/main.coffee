define [
  'bluebird',
  'cs!projectorHtml',
  'cs!projectorExpr',
  'cs!projectorAction',
  'cs!unwidgets/layout',
  'cs!unwidgets/form'
], (
  Promise,
  projectorHtml,
  projectorExpr,
  projectorAction,
  useLayout,
  useForm
) ->
  eventualValue = (v) ->
    new Promise((resolve, reject) -> setTimeout (-> resolve(v)), 500)

  eventualError = (v) ->
    new Promise((resolve, reject) -> setTimeout (-> reject(v)), 500)

  anyText = (v) ->
    if v then eventualValue v else eventualError 'Please enter a value'

  ->
    this.app = window.app;

    @form = (tmpl) ->
      @element 'form[action=]', ->
        @on 'submit', { preventDefault: true }, =>
          if not @$action.isPending
            @$action.invoke()
            .then(((result) -> console.log 'done', result), ((error) -> console.log 'error', error))

        tmpl.apply(this)

    projectorExpr this
    projectorAction this
    projectorHtml this, (element) ->
      # immediately append
      # @todo this could be saved for later appending elsewhere, too
      document.getElementById('container').appendChild(element)

    useLayout(this)
    useForm(this)

    slideIsActive = false

    @slideMenu
      width: '200px'
      isActive: (-> slideIsActive)
      menu: ->
        @text 'Menu'

      main: ->
        @element 'button[type=button][style=width:100%]', ->
          @on 'click', => slideIsActive = !slideIsActive
          @text 'Toggle Menu'

        @action (data) ->
          eventualError 'action_result:' + JSON.stringify(data)
        , ->
          @parameterMap ->
            @form ->
              @formHeader()
              @parameter 'label', -> @formText label: 'Label', validate: anyText

              @parameter 'tagList', ->
                @parameterSet -> @formList {}, ->
                  @formText label: 'Tag Name', validate: anyText

              @parameter 'stopwatch', ->
                isRunning = false
                stopwatchSeconds = 0;
                pad = (v) -> (if v < 10 then '0' else '') + v

                # @todo cleanup on destroy
                setInterval (=> if isRunning then stopwatchSeconds += 0.053; @refresh()), 53

                @commit -> stopwatchSeconds

                @element 'div.stopwatch', ->
                  @element 'span.stopwatch__time', ->
                    @text -> pad(Math.floor stopwatchSeconds / 60) + ':' + pad(Math.floor(stopwatchSeconds) % 60) + '.' + pad(Math.round(stopwatchSeconds * 100) % 100)

                  @element 'button[type=button].stopwatch__toggle', ->
                    @text (-> if isRunning then 'Stop' else 'Start')
                    @on 'click', -> isRunning = !isRunning

                  @element 'button[type=button].stopwatch__reset', ->
                    @text 'Reset'
                    @on 'click', -> stopwatchSeconds = 0; isRunning = false

              @formFooter()
