(if define? then define else ((defs, module) -> window.projectorAction = module(window.bluebird)))(['bluebird'], (Promise) ->
  (viewModel) ->
    validationError = {}

    createStateTracker = (viewModel, state, valueGetter) ->
      currentPromise = null
      ->
        state.isPending = true
        state.error = null

        p = currentPromise = Promise.resolve(
          valueGetter()
        ).catch((e) ->
          if p is currentPromise
            state.error = e
          throw e
        ).finally(->
          if p is currentPromise
            state.isPending = false
            viewModel.refresh()
        )

    viewModel.action = (action, tmpl) ->
      viewModel = this
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
          ).catch((e) ->
            if p is currentPromise
              state.error = e

            throw e
          ).finally(->
            if p is currentPromise
              state.isPending = false
              viewModel.refresh()
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
          viewModel = this
          paramState = {
            isPending: false
            error: null
          }

          @fork ->
            @$parameter = paramState
            @commit = (valueGetter) ->
              valueGetterMap[name] = createStateTracker viewModel, paramState, valueGetter
              undefined

            paramTmpl.apply(this)

        tmpl.apply(this)

    viewModel.parameterSet = (tmpl) ->
      itemStatusList = []
      valueGetterList = []
      addItem = null

      @commit ->
        Promise.all(valueGetterList[i]() for i in [0...itemStatusList.length] by 1 when itemStatusList[i])

      @fork ->
        @$parameterSet = {
          add: -> addItem()
        }

        @parameter = (paramTmpl) ->
          viewModel = this
          addItem = =>
            index = itemStatusList.length

            paramState = {
              isPending: false
              error: null

              isRemoved: ->
                !itemStatusList[index]

              remove: ->
                itemStatusList[index] = false
            }

            itemStatusList.push true

            @fork ->
              @$parameter = paramState
              @commit = (valueGetter) ->
                valueGetterList[index] = createStateTracker viewModel, paramState, valueGetter
                undefined

              paramTmpl.call(this)

        tmpl.call(this)
)