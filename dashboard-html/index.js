const initalOffset = 100;
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
    initializeValues();
    setInterval(function () {
        // adds a css property transform to all the cards if the last card is not showing
        if (!isShowing(card.last(), cardDeck)) {
            card.each(function () {
                $(this).css("transform", "translateX(-" + translateX + "%)");
            });
            translateX = translateX + initalOffset + cardMargin;
        } else {
            isLastCardShowing = true;
        }

        // adds a css property transform to all the list-items if the last item is not showing
        if (!isShowing(listItem.last(), listGroup)) {
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
                // TODO: CHANGE TO AJAX REQUEST TO RAILS 
                var root = 'https://jsonplaceholder.typicode.com';

                $.ajax({
                    url: root + '/posts/1',
                    method: 'GET'
                }).then(function (data) {
                    console.log(data);
                    slideCarousel();
                });
                // END TODO
            } else {
                slideCarousel();
            }
        }
    }, 5000);
});

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
    var containerPos = container.position();
    if (elementPos.left < container.width() && elementPos.top + 2 < container.height()) {
        return true;
    } else {
        return false;
    }
}


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

var successPercent = document.getElementById("success").value;
var failPercent = document.getElementById("fail").value;
var unstablePercent = document.getElementById("unstable").value;

doughnutData = [successPercent, failPercent, unstablePercent];

var data = {
    datasets: [{
        data: doughnutData,
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

var doughnutCtx1 = document.getElementById('doughnutChart1').getContext('2d');
var doughnutChart1 = new Chart(doughnutCtx1, {
    type: 'doughnut',
    data: data,
    options: options
});
var doughnutCtx2 = document.getElementById('doughnutChart2').getContext('2d');
var doughnutChart2 = new Chart(doughnutCtx2, {
    type: 'doughnut',
    data: data,
    options: options
});
var doughnutCtx3 = document.getElementById('doughnutChart3').getContext('2d');
var doughnutChart3 = new Chart(doughnutCtx3, {
    type: 'doughnut',
    data: data,
    options: options
});