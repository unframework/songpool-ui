define ['cs!projectorHtml', 'cs!projectorExpr'], (projectorHtml, projectorExpr) ->
  ->
    this.app = window.app;

    projectorExpr.install this
    projectorHtml.install this, (element) ->
      # immediately append
      # @todo this could be saved for later appending elsewhere, too
      document.getElementById('container').appendChild(element)
