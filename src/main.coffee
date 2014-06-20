define ['bluebird', 'cs!projectorHtml', 'cs!projectorExpr', 'cs!projectorAction', 'cs!meow'], (Promise, projectorHtml, projectorExpr, projectorAction, meow) ->
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

    meow(this)

    @element 'div', ->
      @action (data) ->
        eventualError 'action_result:' + JSON.stringify(data)
      , ->
        @parameterMap ->
          @form ->
            @meowHeader()
            @parameter 'label', -> @meowText label: 'Label', validate: anyText

            @parameter 'tagList', ->
              @parameterSet -> @meowList {}, ->
                @meowText label: 'Tag Name', validate: anyText

            @meowFooter()
