({
    doInit : function(component, event, helper) {
            var applId = component.get('v.recordId');
            console.log('ApplId=='+applId);
            var accAction = component.get("c.hasSubmitApplicationBtnAccess");
            accAction.setParams({"applicationId": applId});
            accAction.setCallback(this, function(res) {
            console.log('submitButton Return=='+res.getReturnValue());
            if(res.getReturnValue()!= 'All good')
            {
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Checking permissions and Application status",
                    "message": res.getReturnValue(),
                    "type":"warning"
                });
                resultsToast.fire();
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            }else{
                var applicationId = component.get('v.recordId');
                var action = component.get("c.sendApplication");
                console.log(applicationId);
                action.setParams({"ApplicationId": applicationId});
                action.setCallback(this, function(response) {
                    if(response.getState() === 'SUCCESS'){
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "message": "Application is now queued for processing.",
                            "type":"success"
                        });
                        resultsToast.fire();                
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }
                    else{
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title": "Unexpected Error",
                            "message": response.getError(),
                            "type":"error"
                        });
                        resultsToast.fire();
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }
                });
                $A.enqueueAction(action);
            }
        }); 
        $A.enqueueAction(accAction);
      
       
    }
})