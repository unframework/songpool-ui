(if define? then define else ((defs, module) -> window.projectorAction = module(window.bluebird)))(['bluebird'], (Promise) ->
  (viewModel) ->
    validationError = {}

    createStateTracker = (state, valueGetter) ->
      currentPromise = null
      ->
        state.isPending = true
        state.error = null

        p = currentPromise = Promise.resolve(
          valueGetter()
        ).finally(->
          if p is currentPromise
            state.isPending = false
        ).catch((e) ->
          if p is currentPromise
            state.error = e
          throw e
        )

    viewModel.action = (action, tmpl) ->
      currentPromise = null
      currentValueGetter = (->)

      state = {
        isPending: false
        error: null

        invoke: ->
          state.isPending = true
          state.error = null

          p = currentPromise = Promise.resolve(
            currentValueGetter()
          ).catch(->
            # report overall validation error
            throw validationError
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
        @commit = (valueGetter) ->
          currentValueGetter = valueGetter
          undefined

        tmpl.apply(this)

    viewModel.action.isValidationError = (e) ->
      e is validationError

    viewModel.parameterMap = (tmpl) ->
      valueGetterMap = Object.create(null)

      @commit ->
        valueMap = Object.create(null)
        valueMap[k] = getter() for own k, getter of valueGetterMap

        Promise.props(valueMap)

      @fork ->
        @parameter = (name, paramTmpl) ->
          paramState = {
            isPending: false
            error: null
          }

          @fork ->
            @$parameter = paramState
            @commit = (valueGetter) ->
              valueGetterMap[name] = createStateTracker paramState, valueGetter
              undefined

            paramTmpl.apply(this)

        tmpl.apply(this)
)