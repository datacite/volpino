/*global d3 */

// construct query string
var params = d3.select("#jwt");

if (!params.empty()) {
  var user_id = params.attr('data-user-id');
  var query = encodeURI("https://impactstory.org/api/person/" + user_id);
}

// load the data from the ImpactStory API
if (query) {
  d3.json(query, function(error, json) {
    if (error) return console.warn(error);
    BadgesViz(json);
  });
}

// add data to page
function BadgesViz(json) {
  data = json.overview_badges;

  if (typeof data === "undefined" || data.length === 0) { return; }

  d3.select("#impactstory-link")
    .attr("href", function() { return "https://impactstory.org/u/" + user_id; })
    .text("go to profile");

  for (var i=0; i<data.length; i++) {
    var badge = data[i];

    d3.select("#impactstory").insert("div")
      .attr("class", "panel panel-default")
      .attr("id", "panel-" + i).insert("div")
      .attr("class", "panel-body")
      .attr("id", "panel-body-" + i);

    d3.select("#panel-body-" + i).insert("div")
      .attr("class", "media")
      .attr("id", "panel-media-" + i).insert("div")
      .attr("class", "media-left media-badge").insert("img")
      .attr("src", encodeURI("https://impactstory.org/static/img/badges/" + badge.name + ".png"));
    d3.select("#panel-media-" + i).insert("div")
      .attr("class", "media-body")
      .attr("id", "panel-media-body-" + i).append("h4")
      .attr("class", "work badge-" + badge.group)
      .html(badge.display_name);

    d3.select("#panel-media-body-" + i).insert("div")
      .attr("class", "description")
      .html(badge.description + " " + badge.context);
  }
}
