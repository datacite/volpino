/*global d3, barViz, donutViz */

var endDate = new Date(),
    startDate = new Date(2012, 10, 16); // the ORCID registry launch date
    colors = d3.scale.ordinal().range(["#2582d5","#145996","#e2e6e7"]);

// construct query string
var params = d3.select("#api");
if (!params.empty()) {
  var jwt = getCookieValue('_datacite_jwt');
  var user_id = params.attr('data-user-id');
  var query = encodeURI("/api/claims?user_id=" + user_id);
}

// load the data from the API
if (query) {
  d3.json(query)
    .header("Accept", "application/json")
    .header("Authorization", "Bearer " + jwt)
    .get(function(error, json) {
      if (error) { return console.warn(error); }
      var data = json.data;

      // aggregate claims by month
      var by_month = d3.nest()
        .key(function(d) { return (!d.attributes["claimed-at"]) ? null : d.attributes["claimed-at"].substr(0,7); }).sortKeys(d3.ascending)
        .rollup(function(leaves) { return { "claims_count": leaves.length }; })
        .entries(data);

      barViz(by_month, "#chart_claims", "claims_count", "months");
  });
}
