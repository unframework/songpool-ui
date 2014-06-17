(if define? then define else ((defs, module) -> window.projectorAction = module(window.bluebird)))(['bluebird'], (Promise) ->
  (viewModel) ->
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
        @commit = (valueGetter) ->
          currentValueGetter = valueGetter
          undefined

        tmpl.apply(this)

    viewModel.parameterMap = (tmpl) ->
      valueGetterMap = Object.create(null)

      @commit ->
        valueMap = Object.create(null)
        valueMap[k] = getter() for own k, getter of valueGetterMap

        Promise.props(valueMap)

      @fork ->
        @parameter = (name, paramTmpl) ->
          viewModel = this
          currentPromise = null
          paramState = {
            isPending: false
            error: null
          }

          @fork ->
            @$parameter = paramState
            @commit = (valueGetter) ->
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

            paramTmpl.apply(this)

        tmpl.apply(this)
)