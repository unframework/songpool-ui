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
          state.error = null

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
          viewModel = this
          currentPromise = null
          paramState = {
            isPending: false
            error: null
            value: (valueGetter) ->
              valueGetterMap[name] = ->
                paramState.isPending = true
                paramState.error = null

                p = currentPromise = Promise.resolve(
                  valueGetter()
                ).finally(->
                  if p is currentPromise
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

    @transitionIn = ->
      dom = @html()
      dom.setAttribute 'transition', 'enter'
      setTimeout (-> dom.setAttribute 'transition', null), 0

    @meowHeader = () ->
      @element 'div.meow-header', ->
        @when (=> @$action.error), ->
          @element 'div.meow-header__error-text', ->
            @transitionIn()
            @text => @$action.error

    @meowFooter = (options) ->
      options = options or {}
      submitText = options.submit or 'Submit'

      @element 'div.meow-footer', ->
        @transitionIn()

        @element 'button[type=submit]', { disabled: => if @$action.isPending then 'disabled' else null }, ->
          @text submitText

    @meowText = (options) ->
      validator = options.validate or ((v) -> v)

      @element 'label.meow-field', { hasError: (=> !!@$parameter.error), isPending: (=> !!@$parameter.isPending) }, ->
        @transitionIn()

        @element 'span.meow-field__label-text', ->
          @text options.label
        @element 'input[type=text]', ->
          @$parameter.value => validator @value()
        @when (=> @$parameter.error), ->
          @element 'span.meow-field__error-text', ->
            @transitionIn()
            @text (=> @$parameter.error)

    @form = (tmpl) ->
      @element 'form[action=]', ->
        @on 'submit', { preventDefault: true }, =>
          if not @$action.isPending
            @$action.invoke().finally =>
              @refresh()
            .then(((result) -> console.log 'done', result), ((error) -> console.log 'error', error))

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
          @form ->
            @meowHeader()
            @parameter 'label', -> @meowText label: 'Label', validate: anyText
            @meowFooter()
