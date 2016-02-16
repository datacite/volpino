/*global d3, barViz, donutViz */

var endDate = new Date(),
    startDate = d3.time.day.offset(endDate, -29),
    endTime = endDate.setHours(23),
    startTime = d3.time.hour.offset(endTime, -23),
    colors = d3.scale.ordinal().range(["#1abc9c","#2ecc71","#3498db","#9b59b6","#34495e","#95a6a6"]);

// construct query string
var params = d3.select("#api_key");
if (!params.empty()) {
  var api_key = params.attr('data-api-key');
  var query = encodeURI("/api/status");
}

// load the data from the Lagotto API
if (query) {
  d3.json(query)
    .header("Accept", "application/json; version=1")
    .header("Authorization", "Token token=" + api_key)
    .get(function(error, json) {
      if (error) { return console.warn(error); }
      var data = json.data;

      // aggregate status by day
      var day_data = data.filter(function(status) {
        return Date.parse(status.attributes.timestamp) >= startDate;
      });
      var by_day = d3.nest()
        .key(function(d) { return d.attributes.timestamp.substr(0,10); })
        .rollup(function(leaves) {
          return { "users_count": d3.max(leaves, function(d) { return d.attributes.users_new_count;}),
                   "claims_search_count": d3.max(leaves, function(d) { return d.attributes.claims_search_new_count;}),
                   "claims_auto_count": d3.max(leaves, function(d) { return d.attributes.claims_auto_new_count;}),
                   "db_size": d3.max(leaves, function(d) { return d.attributes.db_size;}),
                  };})
        .entries(day_data);

      var members = d3.entries(data[0].attributes.members_count);
      var members_title = d3.sum(members, function(g) { return g.value; });

      barViz(by_day, "#chart_users", "users_count", "days");
      barViz(by_day, "#chart_search_claims", "claims_search_count", "days");
      barViz(by_day, "#chart_auto_claims", "claims_auto_count", "days");
      barViz(by_day, "#chart_db_size", "db_size", "days");

      donutViz(members, "#chart_members", members_title, null, colors, "members");
  });
}
