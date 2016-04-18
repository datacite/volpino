/*global d3 */

// construct query string
var params = d3.select("#api_key"),
    colors = d3.scale.ordinal().range(["#1abc9c","#ecf0f1","#95a5a6"]);

if (!params.empty()) {
  var contributor_id = params.attr('data-contributor-id').substring(17);
  var query = encodeURI("https://impactstory.org/api/person/" + contributor_id);
}

// load the data from the ImpactStory API
if (query) {
  d3.json(query)
    .get(function(error, json) {
      if (error) { return console.warn(error); }
      var data = json.badges;
      console.log(badges)
  });
}
