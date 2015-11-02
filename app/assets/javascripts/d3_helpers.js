/*global d3 */

var formatDate = d3.time.format.utc("%B %d, %Y"),
    formatMonthYear = d3.time.format.utc("%B %Y"),
    formatYear = d3.time.format.utc("%Y"),
    formatTime = d3.time.format.utc("%H:%M UTC"),
    formatWeek = d3.time.format.utc("%U"),
    formatHour = d3.time.format.utc("%H"),
    formatNumber = d3.format(",d"),
    formatFixed = d3.format(",.0f"),
    formatPercent = d3.format(",.0%");

function numberWithDelimiter(number) {
  if(number !== 0) {
    return formatFixed(number);
  } else {
    return null;
  }
}

// Format file size into human-readable format
function numberToHumanSize(bytes) {
  var thresh = 1000;
  if(bytes < thresh) { return bytes + ' B'; }
  var units = ['KB','MB','GB','TB','PB'];
  var u = -1;
  do { bytes /= thresh; ++u; } while(bytes >= thresh);
  return bytes.toFixed(1) + ' ' + units[u];
}

// construct date object from date parts
function datePartsToDate(date_parts) {
  var len = date_parts.length;

  // not in expected format
  if (len === 0 || len > 3) { return null; }

  // turn numbers to strings and pad with 0
  for (var i = 0; i < len; ++i) {
    if (date_parts[i] < 10) {
      date_parts[i] = "0" + date_parts[i];
    } else {
      date_parts[i] = "" + date_parts[i];
    }
  }

  // convert to date, workaround for different time zones
  var timestamp = Date.parse(date_parts.join('-') + 'T12:00');
  return new Date(timestamp);
}

// format date
function formattedDate(date, len) {
  switch (len) {
    case 1:
      return formatYear(date);
    case 2:
      return formatMonthYear(date);
    case 3:
      return formatDate(date);
  }
}

// pagination
function paginate(json, tag) {
  if ((json.meta.page !== "") && json.meta.total_pages > 1) {
    var prev = (json.meta.page > 1) ? "«" : null;
    var next = (json.meta.page < json.meta.total_pages) ? "»" : null;

    d3.select(tag).append("div")
      .attr("id", "paginator")
      .attr("class", "text-center");

    $('#paginator').bootpag({
      total: json.meta.total_pages,
      page: json.meta.page,
      maxVisible: 10,
      href: json.href,
      leaps: false,
      prev: prev,
      next: next
    });
  }
}

// link to individual work
function pathForWork(id) {
  if (typeof id === "undefined") { return ""; };

  if (id.substring(0, 15) === "http://doi.org/" ||
      id.substring(0, 35) === "http://www.ncbi.nlm.nih.gov/pubmed/" ||
      id.substring(0, 41) === "http://www.ncbi.nlm.nih.gov/pmc/works/PMC" ||
      id.substring(0, 41) === "http://www.ncbi.nlm.nih.gov/pmc/works/PMC" ||
      id.substring(0, 21) === "http://arxiv.org/abs/" ||
      id.substring(0, 15) === "http://n2t.net/") {
    return id.replace(/^https?:\/\//,'');
  } else {
    return id;
  }
}

function signpostsToString(work, sources, source_id, sort) {
  var name = "";
  if (typeof source_id !== "undefined" && source_id !== "") {
    name = source_id;
  } else if (typeof sort !== "undefined" && sort !== "") {
    name = sort;
  }

  if (name !== "") {
    var source = sources.filter(function(d) { return d.id === name; })[0];
  }

  if (typeof source !== "undefined" && source !== "") {
    var a = [source.title + ": " + formatFixed(work.events[name])];
  } else {
    var a = [];
  }

  var b = [],
      signposts = signpostsFromWork(work);

  if (signposts.viewed > 0) { b.push("Viewed: " + formatFixed(signposts.viewed)); }
  if (signposts.cited > 0) { b.push("Cited: " + formatFixed(signposts.cited)); }
  if (signposts.saved > 0) { b.push("Saved: " + formatFixed(signposts.saved)); }
  if (signposts.discussed > 0) { b.push("Discussed: " + formatFixed(signposts.discussed)); }
  if (b.length > 0) {
    a.push(b.join(" • "));
    return a.join(" | ");
  } else if (a.length > 0) {
    return a;
  } else {
    return "";
  }
}

function signpostsFromWork(work) {
  var viewed = (work.events.counter || 0) + (work.events.pmc || 0);
  var cited = work.events.crossref;
  var saved = (work.events.citeulike || 0) + (work.events.mendeley || 0);
  var discussed = (work.events.facebook || 0) + (work.events.twitter || 0) + (work.events.twitter_search || 0);

  return { "viewed": viewed, "cited": cited, "saved": saved, "discussed": discussed };
}

function relationToString(work, sources, relation_types) {
  var source = sources.filter(function(d) { return d.id === work.source_id; })[0];
  if (typeof source == "undefined" || source === "") { return []; }

  var relation_type = relation_types.filter(function(d) { return d.id === work.relation_type_id; })[0];
  if (typeof relation_type == "undefined" || relation_type === "") { return []; }

  return [relation_type.inverse_title, " via " + source.title];
}

// construct author object from author parts
function formattedAuthor(author) {
  author = author.map(function(d) { return d.given + " " + d.family; });
  switch (author.length) {
    case 0:
    case 1:
    case 2:
      return author.join(" & ");
    case 3:
    case 4:
      return author.slice(0,-1).join(", ") + " & " + author[author.length - 1];
    default:
      return author.slice(0,3).join(", ") + ", <em>et al</em>";
  }
}

// format event type
function formattedType(type) {
  var types = { "article-journal": "Journal article",
                "article-newspaper": "News",
                "post": "Blog post",
                "webpage": "Web page",
                "broadcast": "Podcast/Video",
                "personal_communication": "Personal communication" };
  return types[type] || "Other";
}
