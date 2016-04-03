$(document).ready(function(){
  $("#drinkup_listing").hide();
});

function getUserLocationforDrinkups() {
  if (navigator.geolocation) {
    var options={timeout:30000};
    navigator.geolocation.getCurrentPosition(initializeMarkers,getManualLocation,options);
  } 
}

function initAutocompleteforDrinkups() {
  // Create the autocomplete object, restricting the search to geographical
  // location types.
  autocomplete = new google.maps.places.Autocomplete(
      /** @type {!HTMLInputElement} */(document.getElementById('autocomplete')),
      {types: ['geocode']});

  // When the user selects an address from the dropdown, populate the address
  // fields in the form.
  autocomplete.addListener('place_changed', storePositionforDrinkups);
}

function storePositionforDrinkups(){
  var place = autocomplete.getPlace();
  var position= {
    coords: {latitude:place.geometry.location.lat(),longitude:place.geometry.location.lng()}
  };

  initializeMarkers(position);
}

function initializeMarkers(position) {
  var crd = position.coords;

  var geoCookie = crd.latitude + "|" + crd.longitude;
  document.cookie = "lat_lng=" + escape(geoCookie);

  $.getJSON("/events/getEvents", function (data) {

    var drinkups = data.events;
    var drinkups_attending = data.events_attending;
    deleteMarkers();
    //createBounds();
    for(i = 0; i < drinkups.length; i++) {
      var isAttending = false;
      if ($.inArray(drinkups[i].id, drinkups_attending) !== -1) {
        isAttending = true;
      }
      createMarkerForEventsAroundYou(drinkups[i], i+1, isAttending);
    }
  });
}