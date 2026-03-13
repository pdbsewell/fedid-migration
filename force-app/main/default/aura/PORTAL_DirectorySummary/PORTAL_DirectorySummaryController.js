({
	doInit : function(component, event, helper) {

        var topCountryAction = component.get("c.SERVER_getTopCountriesList");

        topCountryAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();

            if (state === "SUCCESS") {
                component.set("v.topCountriesList", result);
                
                //alert('result: ' + JSON.stringify(result));
            }
            else {

            }
        });

        $A.enqueueAction(topCountryAction);
        
        
        var countAction = component.get("c.SERVER_getTotalAlumniCount");

        countAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();

            if (state === "SUCCESS") {
                component.set("v.totalAlumniCount", result);
                
                //alert('result: ' + JSON.stringify(result));
            }
            else {

            }
        });

        $A.enqueueAction(countAction);

        
        var topIndustryAction = component.get("c.SERVER_getTopIndustriesList");

        topIndustryAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();

            if (state === "SUCCESS") {
                component.set("v.topIndustriesList", result);
                
                //alert('result: ' + JSON.stringify(result));
            }
            else {

            }
        });

        $A.enqueueAction(topIndustryAction);
	},
})