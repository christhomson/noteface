$(document).ready(function() {
  var randLT = function(n) {
    return Math.round(Math.random() * n);
  };

  var randomColor = function() {
    return "rgb(" + randLT(255) + ", " + randLT(255) + ", " + randLT(255) + ")";
  };

  var chooseColors = function(documents) {
    var _colors = {};

    for (doc in documents) {
      _colors[doc] = randomColor();
    }

    return _colors;
  };

  var renderDownloadsPieChart = function(documents) {
    var chartData = [];

    for (doc in documents) {

      chartData.push({
        value: documents[doc].downloads.total,
        color: randomColor()
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
      $li.find('.document-name').text(doc.name);
      $li.find('.total-downloads').text(doc.downloads.total);
      $li.find('.downloads-today').text(doc.downloads.today);
      $li.find('.downloads-week').text(doc.downloads.this_week);
      $('ul#documents').append($li);
    }
  };

  var renderStats = function(data) {
    renderDownloadsPieChart(data.documents);
    colors = chooseColors(data.documents);
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