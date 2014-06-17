(if define? then define else ((module) -> window.meow = module()))(->
  (viewModel) ->
    viewModel.meowHeader = () ->

    viewModel.meowFooter = (options) ->
      options = options or {}
      submitText = options.submit or 'Submit'
      validationErrorText = options.validationError or 'Some fields were entered incorrectly'

      @element 'div.meow-footer', ->
        @transitionIn()

        @element 'div.meow-footer__error-container', ->
          @when (=> @$action.error), ->
            @element 'div.meow-footer__error-text', ->
              @transitionIn()
              @text =>
                if @action.isValidationError(@$action.error)
                then validationErrorText
                else @$action.error

        @element 'button[type=submit]', { disabled: => if @$action.isPending then 'disabled' else null }, ->
          @text submitText

    viewModel.meowText = (options) ->
      validator = options.validate or ((v) -> v)

      @element 'label.meow-field', { hasError: (=> !!@$parameter.error), isPending: (=> !!@$parameter.isPending) }, ->
        @transitionIn()

        @element 'span.meow-field__label-text', ->
          @text options.label
        @element 'input[type=text]', ->
          @commit => validator @value()
        @when (=> @$parameter.error), ->
          @element 'span.meow-field__error-text', ->
            @transitionIn()
            @text (=> @$parameter.error)

    viewModel.meowList = (options, itemTmpl) ->
      validator = options.validate or ((v) -> v)
      addText = options.add or 'Add Item'
      removeText = options.remove or 'Remove'

      @element 'div.meow-list', ->
        @element 'ul', ->
          @region (->), ->
            @parameter ->
              @region @$parameter.isRemoved, (isRemoved) ->
                if !isRemoved
                  @element 'li', ->
                    @transitionIn()

                    @element 'div', ->
                      itemTmpl.call(this)
                    @element 'div', ->
                      @element 'button[type=button]', ->
                        @on 'click', => @$parameter.remove()
                        @text removeText

        @element 'footer', ->
          @element 'button[type=button]', ->
            @on 'click', => @$parameterSet.add()
            @text addText
)
