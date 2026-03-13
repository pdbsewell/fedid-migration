({
    doinit : function(component,event,helper) {

    },

    generateChart : function(component, event, helper) {       
       

    },
    
    chartChange: function(component, event, helper) {
        
        var chartTitle = component.get("v.chartTitle");
        var xAxisLabel = component.get("v.xAxisLabel");
        var yAxisLabel = component.get("v.yAxisLabel");
        var datasetLabel = component.get("v.datasetLabel");
        
        var inputEventName = component.get("v.inputEventName");

        var dataResult = event.getParam("data");
        var eventName = event.getParam("name");
        var drillDownScope = event.getParam("drillDownScope");
        
        if (eventName == inputEventName) {
            component.set('v.chartData', dataResult);
            
	       	var toggleText = component.find("chart-box");
 			$A.util.removeClass(toggleText, "slds-hide");
            
            if (drillDownScope != null) {
                chartTitle += ' (' + drillDownScope + ')';
            }
            
            helper.createChart(component, event, helper, dataResult, chartTitle, xAxisLabel, yAxisLabel, datasetLabel);
        }

    }
})