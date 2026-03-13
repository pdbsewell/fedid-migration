({

  // Generates colors dynamically
  getRandomColor: function(component) {
    var letters = '0123456789ABCDEF';
    var color = '#';
    for (var i = 0; i < 6; i++) {
      color += letters[Math.floor(Math.random() * 16)];
    }
    return color;
  },

  // Get predefined colors
  getColor: function(component, index) {

    var colorSet = [];

    colorSet.push("rgba(255, 99, 132, 0.2)");
    colorSet.push("rgba(255, 159, 64, 0.2)");
    colorSet.push("rgba(255, 205, 86, 0.2)");
    colorSet.push("rgba(75, 192, 192, 0.2)");
    colorSet.push("rgba(54, 162, 235, 0.2)");
    colorSet.push("rgba(153, 102, 255, 0.2)");
    colorSet.push("rgba(201, 203, 207, 0.2)");

    index = index % colorSet.length;

    return colorSet[index];
  },

  getBorderColor: function(component, index) {

    var colorSet = [];

    colorSet.push("rgba(255, 99, 132)");
    colorSet.push("rgba(255, 159, 64)");
    colorSet.push("rgba(255, 205, 86)");
    colorSet.push("rgba(75, 192, 192)");
    colorSet.push("rgba(54, 162, 235)");
    colorSet.push("rgba(153, 102, 255)");
    colorSet.push("rgba(201, 203, 207)");

    index = index % colorSet.length;

    return colorSet[index];
  },

  addChartData: function(component, event, helper, chart, barColor, labels, data) {

    chart.data.labels = labels;

    chart.data.datasets.forEach((dataset) => {
      dataset.backgroundColor = barColor;
      dataset.data = data;
    });

    chart.update();
  },

  removeChartData: function(component, event, helper, chart) {
    chart.data.labels = [];
    chart.data.datasets.forEach((dataset) => {
      dataset.data = [];
    });
        
    chart.update();
  },


  createChart: function(component, event, helper, dataResult, chartTitle, xAxisLabel, yAxisLabel, datasetLabel) {
    var chartData = [];
    var labelData = [];

    var backgroundColor = [];

    var borderColorList = [];

    var count = 0;
    for (var key in dataResult) {
      //alert('key: ' + dataResult[key].amt);
        
      var color = helper.getColor(this, count);

      var borderColor = helper.getBorderColor(this, count);

      backgroundColor.push(color);
      borderColorList.push(borderColor);

      labelData.push(key);
      
      if (dataResult[key].amt != undefined) {
       	chartData.push(dataResult[key].amt);
	  }
      else
      {
         chartData.push(dataResult[key]);
      }
        
      count++;
    }

//    alert('chartData: ' + chartData);
    var chartComponentData = {
      labels: labelData,
      datasets: [{
        label: datasetLabel,
        data: chartData,
        backgroundColor: backgroundColor,
        borderColor: borderColorList,
        borderWidth: 1,
        fill: true,
        pointBackgroundColor: "#FFFFFF",
        pointBorderWidth: 4,
        pointHoverRadius: 5,
        pointRadius: 3,
        bezierCurve: true,
        pointHitRadius: 10
      }]
    }

    //Get the context of the canvas element we want to select
    //var ctx = component.find("donationByGiftType").getElement();

    //var ctx = document.getElementById("chart-area").getContext('2d');

    var outputEventName = component.get("v.outputEventName");
      
    var ctx = component.find("chart-area").getElement();
      
      if (component.chartComponent != undefined) {
          component.chartComponent.destroy();
      }

    component.chartComponent = new Chart(ctx, {
      type: 'bar',
      data: chartComponentData,
      options: {
        legend: {
          display: true
        },
        title: {
          display: true,
          text: chartTitle,
        },
        responsive: true,
        onClick: function(event) {
            if (outputEventName != '') {
            	console.log('clicked');
              var elements = component.chartComponent.getElementAtEvent(event);
              console.log("elements");
              console.log(elements);
              if (elements.length === 1) {
                  var year = labelData[elements[0]._index];
                  console.log('year: ' + year);
                  
                  var tempData = component.get("v.chartData");
                  
                  console.log('tempData: ' + JSON.stringify(tempData[year].amtMap));

                  var chartEvent = $A.get("e.c:PORTAL_EVT_Chart");
                  chartEvent.setParams({
                      data: tempData[year].amtMap,
                      name: outputEventName,
                      drillDownScope: year
                  });
                  chartEvent.fire();
              }
        	}
        },          
        scales: {
          yAxes: [{
            ticks: {
              callback: function(value, index, values) {
                return value.toLocaleString("en-US", {
                  style: "currency",
                  currency: "USD"
                });
              },
              suggestedMin: 0    // minimum will be 0, unless there is a lower value.
            },
            scaleLabel: {
              display: true,
              labelString: yAxisLabel
            }
          }],
          xAxes: [{
            scaleLabel: {
              display: true,
              labelString: xAxisLabel
            }
          }]
        },
        tooltips: {
          callbacks: {
            label: function(tooltipItem, data) {
              return "$" + Number(tooltipItem.yLabel).toFixed(0).replace(/./g, function(c, i, a) {
                return i > 0 && c !== "." && (a.length - i) % 3 === 0 ? "," + c : c;
              });
            }
          }
        }
      }
    });

  }
})