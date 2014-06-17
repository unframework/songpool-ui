(if define? then define else ((module) -> window.meow = module()))(->
  (viewModel) ->
    viewModel.meowHeader = () ->

    viewModel.meowFooter = (options) ->
      options = options or {}
      submitText = options.submit or 'Submit'

      @element 'div.meow-footer', ->
        @transitionIn()

        @element 'div.meow-footer__error-container', ->
          @when (=> @$action.error), ->
            @element 'div.meow-footer__error-text', ->
              @transitionIn()
              @text => @$action.error

        @element 'button[type=submit]', { disabled: => if @$action.isPending then 'disabled' else null }, ->
          @text submitText

    viewModel.meowText = (options) ->
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
)