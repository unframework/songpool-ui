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
      currentPromise = null
      state = {
        isPending: false
        error: null
        invoke: (inputValue) ->
          state.isPending = true

          # mask validation error
          p = currentPromise = Promise.resolve(
            inputValue
          ).catch(->
            # report overall validation error
            throw 'validation_error'
          ).then((value) ->
            action.call(null, value)
          ).finally(->
            if p is currentPromise
              state.error = null
              state.isPending = false
          ).catch((e) ->
            if p is currentPromise
              state.error = e

            throw e
          )
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
          currentPromise = null
          paramState = {
            isPending: false
            error: null
            value: (valueGetter) ->
              valueGetterMap[name] = ->
                paramState.isPending = true

                p = currentPromise = Promise.resolve(
                  valueGetter()
                ).finally(->
                  if p is currentPromise
                    paramState.error = null
                    paramState.isPending = false
                ).catch((e) ->
                  if p is currentPromise
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

    @form = (tmpl) ->
      @element 'form[action=]', ->
        onSubmit = (event) =>
          event.preventDefault()

          if not @$action.isPending
            resultPromise = @$action.invoke().finally => @refresh()
            @refresh()

            resultPromise.then(((result) -> console.log 'done', result), ((error) -> console.log 'error', error))

        formElement = @$projectorHtmlCursor()
        formElement.addEventListener 'submit', onSubmit, false

        tmpl.apply(this)

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

          @form ->
            @parameter 'label', -> @meowText label: 'Label', validate: anyText

            @element 'button[type=submit]', ->
              @text 'Yep'
