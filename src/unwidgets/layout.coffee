(if define? then define else ((module) -> window.useLayout = module()))(->
  (viewModel) ->
    viewModel.slideMenu = (options) ->
      width = options.width || '300px'
      menuBody = options.menu
      mainBody = options.main
      activeExpr = options.isActive

      @element 'div.unwidgets-slide-menu', {
        active: (-> if activeExpr() then '' else null)
      }, ->
        @element 'div.unwidgets-slide-menu__menu', { style: 'width:' + width }, menuBody
        @element 'div.unwidgets-slide-menu__overlay'
        @element 'div.unwidgets-slide-menu__main', mainBody
)