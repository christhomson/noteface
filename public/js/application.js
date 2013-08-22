$(document).ready(function() {
  var colors = {};

  var randLT = function(n) {
    return Math.round(Math.random() * n);
  };

  var randomColor = function() {
    return { r: randLT(255), g: randLT(255), b: randLT(255) };
  };

  var getColor = function(id, rgba) {
    if (typeof rgba === 'undefined') { rgba = 1; }

    if (!colors[id]) {
      colors[id] = randomColor();
    }

    return "rgba(" + colors[id].r + ", " + colors[id].g + ", " + colors[id].b + ", " + rgba + ")";
  };

  var renderDownloadsPieChart = function(documents) {
    var chartData = [];

    for (doc in documents) {

      chartData.push({
        value: documents[doc].downloads.total,
        color: getColor(doc)
      });
    }

    var ctx = $("#downloads-by-document").get(0).getContext("2d");
    var chart = new Chart(ctx).Doughnut(chartData);
  };

  var renderDownloadCounts = function(documents) {
    var doc;
    for (doc_name in documents) {
      doc = documents[doc_name];

      $li = $('li.template').clone().removeClass('template');
      $li.find('.document-name').text(doc.course.code);
      $li.find('.total-downloads').text(doc.downloads.total);
      $li.find('.downloads-today').text(doc.downloads.today);
      $li.find('.downloads-week').text(doc.downloads.this_week);
      $li.find('.users-count').text(Object.keys(doc.users).length);
      $li.find("h2").css({color: getColor(doc_name)});
      $('ul#documents').append($li);
    }
  };

  var renderStats = function(data) {
    renderDownloadsPieChart(data.documents);
    renderDownloadCounts(data.documents);

    // TODO: display a time-view of downloads, on a per-document basis.
  };

  // Let's go!
  $.ajax({
    url: '/dash/stats.json',
    dataType: 'json',
    success: renderStats
  });
});