define ['bluebird', 'cs!projectorHtml', 'cs!projectorExpr'], (Promise, projectorHtml, projectorExpr) ->
  eventualValue = (v) ->
    new Promise((resolve, reject) -> setTimeout (-> resolve(v)), 500)

  eventualError = (v) ->
    new Promise((resolve, reject) -> setTimeout (-> reject(v)), 500)

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
          @fork ->
            @parameterValue = (valueGetter) ->
              valueGetterMap[name] = valueGetter
              undefined

            paramTmpl.apply(this)

        tmpl.apply(this)

    @meowText = (options, tmpl) ->
      @element 'label.meow-field', ->
        @element 'span', ->
          @text options.label
        @element 'input[type=text]', ->
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

          @element 'form[action=]', ->
            onSubmit = (event) =>
              event.preventDefault()

              resultPromise = @$action.invoke()
              @refresh()

              resultPromise.then(((result) -> console.log 'done', result), ((error) -> console.log 'error', error))
              resultPromise.finally => @refresh()

            formElement = @$projectorHtmlCursor()
            formElement.addEventListener 'submit', onSubmit, false

            @parameter 'label', ->
              @meowText label: 'Label', ->
                @parameterValue => v = @value(); if v then eventualValue v else eventualError 'NOPE'

            @element 'button[type=submit]', ->
              @text 'Yep'
