/**
 *  @description:       Retrieves Contact's Call Attempt History
 *  @author:            APRivera
 *  @revisionHistory:   APRivera - 02.AUG.19 - Created
 */

({
    doInit : function(component, event, helper) {
        // Get a reference to the init() function defined in the Apex controller
        var taskRecordId = component.get("v.recordId");
        console.log('Record Id: ' +taskRecordId);

        var action = component.get("c.retrieveCallAttemptHistory");
        action.setParams({
            "recordId": taskRecordId
        });

        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if(state === "SUCCESS"){
                var lstTasks = response.getReturnValue();
                for( var i = 0; i < lstTasks.length; i++){
                    if(taskRecordId === lstTasks[i].Id){
                        if(lstTasks.length > 1){
                            lstTasks.splice(i, 1);
                        }
                    }
                }
                if(lstTasks.length>0){
                    component.set("v.contactName",lstTasks[0].Who.Name);
                    component.set("v.lstTasks", lstTasks);
                    component.set("v.hasPreviousCallAttempts", true);
                }
                component.set("v.enableSpinner", false);
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
    },

    navigateToTask:function(component, event, helper){
        var recordId = event.target.dataset.taskid;
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        sObjectEvent .setParams({
            "recordId": recordId,
            "slideDevName": "detail"
        });
        sObjectEvent.fire();
    }
});