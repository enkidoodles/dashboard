// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks

var initalOffset = 100;
var card; // card element
var listItem; // list-item element
var cardDeck; // card parent element
var listGroup; // list-item parent element
var cardMargin; // margin of card element
var translateX; // value for moving the card elements (x-axis)
var translateY; // value for moving the list-item elements (y-axis)
var isLastCardShowing; // is the last card inside the parent element
var isLastListItemShowing; // is the last item inside the parent element

$(document).ready(function () {
    $(".navbar-toggler").on("click", function (event) {
        $(".active #health").toggleClass("toggle");
    });
    getJenkinsData();
});

function getJenkinsData() {
    $.ajax({
        'type': 'GET',
        'url': 'branches/updates',
        'dataType': 'html',
        'success': function (response) {
            $("#dashes").html(response);
            $("#1").addClass("active");
            start();
        },
        'error': function (errorThrown) {
            window.location.reload();
            console.log('Error:', errorThrown);
        }
    });
}

function start() {
    setChartConfig();
    makeChart();
    initializeValues();
    move();
    var lastCarouselItem = $(".carousel div:last-child");
    if (lastCarouselItem.hasClass("active")) {
        getJenkinsData();
    } else { // moves to the next carousel when the last card and item is showing
        slideCarousel();
        start();
    }
}

function initializeValues() {
    card = $(".active .card.translate-x");
    listItem = $(".active .list-group-item.translate-y");
    cardDeck = card.parent();
    listGroup = listItem.parent();
    cardMargin = ((cardDeck.width() * 0.02) / card.width()) * 100;
    translateX = initalOffset + cardMargin;
    translateY = initalOffset;
    isLastCardShowing = false;
    isLastListItemShowing = false;
}

function move() {
    setTimeout(function () {
        moveCards();
        moveLists();
        if (!isLastCardShowing && !isLastListItemShowing) {
            move();
        }
    }, 3000);
}

function moveCards() {
    // adds a css property transform to all the cards if the last card is not showing
    if (!isElementInContainer(card.last(), cardDeck)) {
        card.each(function () {
            $(this).css("transform", "translateX(-" + translateX + "%)");
        });
        translateX = translateX + initalOffset + cardMargin;
    } else {
        isLastCardShowing = true;
    }
}

function moveLists() {
    // adds a css property transform to all the list-items if the last item is not showing
    if (!isElementInContainer(listItem.last(), listGroup)) {
        listItem.each(function () {
            $(this).css("transform", "translateY(-" + translateY + "%)");
        });
        translateY = translateY + initalOffset;
    } else {
        isLastListItemShowing = true;
    }
}

function slideCarousel() {
    $(".carousel").carousel("next");
    // fires callback after carousel has slid
    $('.carousel').on('slid.bs.carousel', function () {
        // reset position
        card.each(function () {
            $(this).css("transform", "translateX(0%)");
        });
        listItem.each(function () {
            $(this).css("transform", "translateY(0%)");
        });
    });
}

function isElementInContainer(element, container) {
    var elementPos = element.position();
    if (elementPos.left < container.width() && elementPos.top + 2 < container.height()) {
        return true;
    } else {
        return false;
    }
}

// Chart.js Section


// PluginService

function setChartConfig() {
    Chart.pluginService.register({
        beforeRender: function (chart) {
            if (chart.config.options.showAllTooltips) {
                // create an array of tooltips
                // we can't use the chart tooltip because there is only one tooltip per chart
                chart.pluginTooltips = [];
                chart.config.data.datasets.forEach(function (dataset, i) {
                    chart.getDatasetMeta(i).data.forEach(function (sector, j) {
                        chart.pluginTooltips.push(new Chart.Tooltip({
                            _chart: chart.chart,
                            _chartInstance: chart,
                            _data: chart.data,
                            _options: chart.options.tooltips,
                            _active: [sector]
                        }, chart));
                    });
                });

                // turn off normal tooltips
                chart.options.tooltips.enabled = false;
            }
        },
        afterDraw: function (chart, easing) {
            if (chart.config.options.showAllTooltips) {
                // we don't want the permanent tooltips to animate, so don't do anything till the animation runs atleast once
                if (!chart.allTooltipsOnce) {
                    if (easing !== 1)
                        return;
                    chart.allTooltipsOnce = true;
                }

                // turn on tooltips
                chart.options.tooltips.enabled = true;
                Chart.helpers.each(chart.pluginTooltips, function (tooltip) {
                    tooltip.initialize();
                    tooltip.update();
                    // we don't actually need this since we are not animating tooltips
                    tooltip.pivot();
                    tooltip.transition(easing).draw();
                });
                chart.options.tooltips.enabled = false;
            }
        }
    });

    Chart.defaults.scale.ticks.beginAtZero = true;
}

function makeChart() {
    var activeCarouselId = $(".active")[0].id;
    var successValue = $(this).find("#success" + activeCarouselId).val();
    var failValue = $(this).find("#fail" + activeCarouselId).val();
    var unstableValue = $(this).find("#unstable" + activeCarouselId).val();
    var data = initializeChartData(successValue, failValue, unstableValue);
    var options = {
        showAllTooltips: true,
        cutoutPercentage: 50,
        title: {
            display: true,
            text: 'Branch Status',
            fontColor: "#fff",
            fontSize: 20,
            fontFamily: "Segoe UI Light"
        },
        legend: {
            display: false,
            labels: {
                fontColor: "#fff",
                fontSize: 16,
                fontFamily: "Segoe UI Light"
            }
        }
    };
    drawChart("doughnutChart" + activeCarouselId, data, options);
}

function initializeChartData(successValue, failValue, unstableValue) {
    var data = {
        datasets: [{
            data: [successValue, failValue, unstableValue],
            backgroundColor: [
                '#36A2EB', //light blue
                "#FF6384", //light red
                "#FFCD56" //light yellow
            ],
            borderColor: ["#333645", "#333645", "#333645"],
            borderWidth: [2, 2, 2],
        }],
        labels: ['Success', 'Fail', 'Unstable']
    };
    return data;
}

function drawChart(elementId, data, options) {
    var ctx = document.getElementById(elementId).getContext('2d');
    var doughnutChart = new Chart(ctx, {
        type: 'doughnut',
        data: data,
        options: options
    });
}