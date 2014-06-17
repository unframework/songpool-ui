(if define? then define else ((defs, module) -> window.projectorDo = module(window.bluebird)))(['bluebird'], (Promise) ->
  (viewModel) ->
    viewModel.do = (action, tmpl) ->
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

    viewModel.withParameterMap = (tmpl) ->
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
)