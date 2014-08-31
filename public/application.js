$(document).ready(function() {

  $.ajaxPrefilter(function(options, originalOptions, jqXHR) {
    var token;
    if (!options.crossDomain) {
      token = $('meta[name="_csrf"]').attr('content');
      if (token) {
        return jqXHR.setRequestHeader('X_CSRF_TOKEN', token);
      }
    }
  });
  
  player_hit();
  player_stand();
  dealer_hit();
});

function player_hit() {
  $(document).on("click", "#player_hit_button", function() {
    $.ajax({
      type: "POST",
      url: "/game/player/hit"
    }).done(function(msg) {
      $("#game").replaceWith(msg);
    });

    return false;
  });
}

function player_stand() {
  $(document).on("click", "#player_stand_button", function() {
    $.ajax({
      type: "POST",
      url: "/game/player/stand"
    }).done(function(msg) {
      $("#game").replaceWith(msg);
    });

    return false;
  });
}

function dealer_hit() {
  $(document).on("click", "#dealer_hit_button", function() {
    $.ajax({
      type: "POST",
      url: "/game/dealer/hit"
    }).done(function(msg) {
      $("#game").replaceWith(msg);
    });

    return false;
  });
}
