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
//= require tether
//= require bootstrap
//= require jquery_ujs
//= require turbolinks
//= require Chart.min

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
var interval;

function getJenkinsData() {
    console.log("sending request to jenkins....");
    $.ajax({
        'type': 'GET',
        'url': 'branches/updates',
        'dataType': 'html',
        'success': function (response) {
            $("#dashes").html(response);
            $("#1").addClass("active");
            $("#loading").remove();
            console.log("received data from jenkins");
            start();
        },
        'error': function (errorThrown) {
            window.location.reload();
            console.log('Error:', errorThrown);
        }
    });
}

function start() {
    $(".navbar-toggler").on("click", function (event) {
        $(".active #health").toggleClass("toggle");
    });
    setChartConfig();
    makeChart();
    initializeValues();
    interval = setInterval(function () {
        // adds a css property transform to all the cards if the last card is not showing
        if (card.length != 0 && !isShowing(card.last(), cardDeck)) {
            card.each(function () {
                $(this).css("transform", "translateX(-" + translateX + "%)");
            });
            translateX = translateX + initalOffset + cardMargin;
        } else {
            isLastCardShowing = true;
        }

        // adds a css property transform to all the list-items if the last item is not showing
        if (listItem.length != 0 && !isShowing(listItem.last(), listGroup)) {
            listItem.each(function () {
                $(this).css("transform", "translateY(-" + translateY + "%)");
            });
            translateY = translateY + initalOffset;
        } else {
            isLastListItemShowing = true;
        }

        // moves to the next carousel when the last card and item is showing
        if (isLastCardShowing && isLastListItemShowing) {
            if ($(".carousel div:last-child").hasClass("active")) {
                clearInterval(interval);
                insertLoadingDiv();
                getJenkinsData();
            } else {
                slideCarousel();
            }
        }
    }, 5000);
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
        initializeValues();
        makeChart();
    });
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

function isShowing(element, container) {
    var elementPos = element.position();
    if (elementPos.left + element.width() < container.width() &&
        elementPos.top + element.height() <= container.height()) {
        return true;
    } else {
        return false;
    }
}

function insertLoadingDiv() {
    var loadingDiv =
        "<div id=\"loading\">" +
            "<i class=\"fa fa-spin fa-pulse fa-spinner\"></i> " +
            "Loading new data from jenkins server..." +
        "</div>";
    $("#branch .alert").after(loadingDiv);
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
    var successValue = $("#success" + activeCarouselId).val();
    var failValue = $("#fail" + activeCarouselId).val();
    var unstableValue = $("#unstable" + activeCarouselId).val();
    var data = initializeChartData(successValue, failValue, unstableValue);
    var options = {
        showAllTooltips: true,
        title: {
            display: true,
            text: 'Branch Status',
            fontColor: "#fff",
            fontSize: 20,
            fontFamily: "Roboto"
        },
        legend: {
            display: false
        }
    };
    drawChart("doughnutChart" + activeCarouselId, data, options);
}

function initializeChartData(successValue, failValue, unstableValue) {
    var data = {
        datasets: [{
            data: [unstableValue, failValue, successValue],
            backgroundColor: [
                "#FFCD56", //light yellow                
                "#FF6384", //light red
                '#36A2EB' //light blue
            ],
            borderColor: ["#333645", "#333645", "#333645"],
            borderWidth: [2, 2, 2],
        }],
        labels: ['Unstable', 'Fail', 'Success']
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