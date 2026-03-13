({
    doInit : function(component, event, helper) {
        console.log(window.location.host.split('.')[0]);
        var iframeSrc = 'https://'+ window.location.host.split('.')[0] + '--c.visualforce.com/apex/StudFirst_GlobalActionSendEmail?Id=' + component.get("v.recordId");
        component.set('v.urlforVF', iframeSrc);
        window.addEventListener("message", function(event) {
            console.log(event.data);
            if(event.data == 'closeQuickAction'){
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "message": "Email Sent Successfully",
                    "type":"success"
                });
                //resultsToast.fire();
                $A.get("e.force:closeQuickAction").fire()

            }
            if(event.data == 'messageFailure'){
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "message": "Unexpected error occurred",
                    "type":"error"
                });
                //resultsToast.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        }, false);
    }
})