({
	doInit : function(component, event, helper) {

        var action = component.get("c.getChartData");
        
        action.setCallback(this, function(response){
            var state = response.getState();
            
            if (state === "SUCCESS") {
                //alert(response.getReturnValue());
                
                var dataResult = JSON.parse(response.getReturnValue());
                
                var chartEvent = $A.get("e.c:PORTAL_EVT_Chart");
                chartEvent.setParams({
                    name: "Start",
                    data: dataResult
                });
                chartEvent.fire();                        
            }
            else {
                alert('Error in getting data');
            }
        });
        
        $A.enqueueAction(action);
	}
})