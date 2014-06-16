define ['bluebird', 'cs!projectorHtml', 'cs!projectorExpr'], (Promise, projectorHtml, projectorExpr) ->
  eventualValue = (v) ->
    new Promise((resolve, reject) -> setTimeout (-> resolve(v)), 500)

  eventualError = (v) ->
    new Promise((resolve, reject) -> setTimeout (-> reject(v)), 500)

  anyText = (v) ->
    if v then eventualValue v else eventualError 'NOPE'

  ->
    this.app = window.app;

    @do = (action, tmpl) ->
      state = {
        isPending: false
        error: null
        invoke: (inputValue) ->
          state.isPending = true

          # mask validation error
          validationResult = Promise.resolve(inputValue).catch(-> state.error = null; throw 'validation_error')

          overallResult = validationResult.then (value) ->
            # mask the error
            Promise.resolve(action.call(null, value)).catch((e) -> state.error = e; throw 'action_error')

          overallResult.finally(-> state.isPending = false)
      }

      @fork ->
        @$action = state
        tmpl.apply(this)

    @withParameterMap = (tmpl) ->
      valueGetterMap = Object.create(null)

      # intercept action invoker
      parentInvoke = @$action.invoke

      state = Object.create(@$action)

      state.invoke = () ->
        valueMap = Object.create(null)
        valueMap[k] = getter() for own k, getter of valueGetterMap

        parentInvoke.call(null, Promise.props(valueMap))

      @fork ->
        @$action = state

        @parameter = (name, paramTmpl) ->
          paramState = {
            isPending: false
            error: null
            value: (valueGetter) ->
              valueGetterMap[name] = ->
                paramState.isPending = true

                Promise.resolve(
                  valueGetter()
                ).finally(->
                  paramState.error = null
                  paramState.isPending = false
                ).catch((e) ->
                  paramState.error = e
                  throw e
                )
              undefined
          }

          @fork ->
            @$parameter = paramState
            paramTmpl.apply(this)

        tmpl.apply(this)

    @meowText = (options) ->
      validator = options.validate or ((v) -> v)

      @element 'label.meow-field', { hasError: (=> !!@$parameter.error) }, ->
        @element 'span.meow-field__label-text', ->
          @text options.label
        @element 'input[type=text]', ->
          @$parameter.value => validator @value()
        @when (=> @$parameter.error), ->
          @element 'span.meow-field__error-text', ->
            @text (=> @$parameter.error)

    projectorExpr.install this
    projectorHtml.install this, (element) ->
      # immediately append
      # @todo this could be saved for later appending elsewhere, too
      document.getElementById('container').appendChild(element)

    @element 'div', ->
      @do (data) ->
        eventualError 'action_result:' + JSON.stringify(data)
      , ->
        @withParameterMap ->
          @element 'div', ->
            @text => if @$action.isPending then 'Submitting...' else 'Ready'

          @when (=> @$action.error), ->
            @element 'div', ->
              @text => @$action.error

          @element 'form[action=]', ->
            onSubmit = (event) =>
              event.preventDefault()

              resultPromise = @$action.invoke()
              @refresh()

              resultPromise.then(((result) -> console.log 'done', result), ((error) -> console.log 'error', error))
              resultPromise.finally => @refresh()

            formElement = @$projectorHtmlCursor()
            formElement.addEventListener 'submit', onSubmit, false

            @parameter 'label', -> @meowText label: 'Label', validate: anyText

            @element 'button[type=submit]', ->
              @text 'Yep'
