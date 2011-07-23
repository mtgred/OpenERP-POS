(function() {
  $(function() {
    $('#steps').buttonset();
    $('#rightpane').width($(window).width() - 445);
    return $(window).resize(function() {
      return $('#rightpane').width($(window).width() - 445);
    });
  });
}).call(this);
