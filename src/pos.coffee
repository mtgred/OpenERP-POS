$ ->
  # jQuery UI
  $('#steps').buttonset()

  # Rightpane resize
  $('#rightpane').width($(window).width() - 445)
  $(window).resize -> $('#rightpane').width($(window).width() - 445)
