({
    init : function(component, event, helper) {
        document.title = 'Send Offer Email';

        let origin = component.get('v.intializetype');
        var pageReference = component.get('v.pageReference');
        if(pageReference){
            origin = pageReference.state.c__intializetype;
            if(pageReference.state){
                if(pageReference.state.c__opportunityid){
                    component.set('v.opportunityid', pageReference.state.c__opportunityid);
                }
            }
        }
        if(origin === ''){
            //Determine if a redirection should occur
            var action = component.get('c.checkSendOfferEmailPermission');
            //Create a callback that is executed after the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var hasSendOfferEmailAccess = response.getReturnValue();
                    if(hasSendOfferEmailAccess){
                        helper.openEmailPublisher(component, event, helper);
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            'type': 'error',
                            "title": "Insufficient Access!",
                            "message": "You do not have the proper access to send an offer email."
                        });
                        toastEvent.fire();

                        var evt = $A.get("e.force:navigateToSObject");
                        evt.setParams({
                            "recordId": component.get("v.recordId"),
                            "slideDevName": "related"
                        });
                        evt.fire();
                    }                
                }
                else if (state === 'INCOMPLETE') {
                    // do something
                }
                else if (state === 'ERROR') {
                    var errors = response.getError();
                    if(errors) {
                        if(errors[0] && errors[0].message) {
                            console.log('Error message: ' + errors[0].message);
                        }
                    }else {
                        console.log('Unknown error');
                    }
                }
            });
            
            $A.enqueueAction(action);
        }else{ 
            var workspaceAPI = component.find("workspace");
            workspaceAPI.isConsoleNavigation().then(function(response) {
                if(response){
                    workspaceAPI.getEnclosingTabId()
                    .then(function(response) {
                        workspaceAPI.setTabIcon({
                            tabId: response,
                            icon: "standard:email",
                            iconAlt: "Send Offer Email"
                        });
                        workspaceAPI.setTabLabel({
                            tabId: response,
                            label: "Send Offer Email"
                        });
                    })
                    .catch(function(error) {
                        console.log(error);
                    });
                }
            })
            .catch(function(error) {
                console.error(error);
            });
        }
    },
    closeFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    }         
})