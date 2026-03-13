/**
 * Created by trentdelaney on 22/8/18.
 */
({
    navigateToUrl : function(address)
    {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": address,
            "isredirect" :false
        });
        urlEvent.fire();
    },

    progressStatus : function(component, page, appId, direction)
    {
        component.set("v.locationError", false);
        console.log(page);
        var action = component.get("c.ProcessStatus");
        action.setParams({
            "appId" : appId,
            "direction" : direction
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var objResponse = response.getReturnValue();
                
                if(objResponse.status === 'ValidationError' && objResponse.header && objResponse.message){
                    component.set("v.validationError", true);
                    component.set("v.validationHeader", objResponse.header);
                    component.set("v.validationMessage", objResponse.message);
                    
                } else if(objResponse.status === 'Error' && objResponse.message === 'Not Australia')
                {
                    // show alert
                    console.log("This is not australia");
                    component.set("v.textType", true);
                    component.set("v.locationError", true);
                }else if(objResponse.status === 'Error' && objResponse.message === 'Empty'){
                    console.log("This is blank");
                    component.set("v.textType", false);
                    component.set("v.locationError", true);
                }
                else
                {
                   	var address = page + '?appId=' + appId;
                    this.navigateToUrl(address);
                }
            }
        });

        $A.enqueueAction(action);
    },

    createApplication : function(component, page)
    {
        var action = component.get("c.CreateApplication");

        action.setCallback(this, function(response){
            var state = response.getState();
            console.log(state);
            if(state === "SUCCESS"){
                var appId = response.getReturnValue();
                var address = page + '?appId=' + appId;
                this.navigateToUrl(address);
            }
        });

        $A.enqueueAction(action);
    }
})