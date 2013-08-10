$(document).ready(function() {
  var randLT = function(n) {
    return Math.round(Math.random() * n);
  };

  var randomColor = function() {
    return "rgb(" + randLT(255) + ", " + randLT(255) + ", " + randLT(255) + ")";
  };

  var displayDownloadsPieChart = function(data) {
    var pieChartData = [];

    for (doc in data.documents) {

      pieChartData.push({
        value: data.documents[doc].downloads,
        color: randomColor()
      });
    }

    var ctx = $("#downloads-by-document").get(0).getContext("2d");
    var pieChart = new Chart(ctx).Pie(pieChartData);
  };

  var displayStats = function(data) {
    displayDownloadsPieChart(data);

    // TODO: display a time-view of downloads, on a per-document basis.
  };

  // Let's go!
  $.ajax({
    url: '/dash/stats.json',
    dataType: 'json',
    success: displayStats
  });
});