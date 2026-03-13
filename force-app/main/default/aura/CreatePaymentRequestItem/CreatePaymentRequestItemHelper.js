({
    openCreatePaymentRequestItem : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            if(response){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    if(response.isSubtab){
                        workspaceAPI.openSubtab({
                            parentTabId: response.parentTabId,
                            pageReference: {
                                "type": "standard__component",
                                "attributes": {
                                    "componentName": "c__CreatePaymentRequestItem"
                                },
                                "state": {
                                    "uid" : component.get("v.recordId") + 'CreatePaymentRequestItem',
                                    "c__paymentrequestid": component.get("v.recordId"),
                                    "c__intializetype": 'aura'
                                }
                            }
                        }).then(function(subtabId) {
                        }).catch(function(error) {
                            console.error(JSON.stringify(error));
                        });
                    }else{
                        workspaceAPI.openSubtab({
                            parentTabId: response.tabId,
                            pageReference: {
                                "type": "standard__component",
                                "attributes": {
                                    "componentName": "c__CreatePaymentRequestItem"
                                },
                                "state": {
                                    "uid" : component.get("v.recordId") + 'CreatePaymentRequestItem',
                                    "c__paymentrequestid": component.get("v.recordId"),
                                    "c__intializetype": 'aura'
                                }
                            }
                        }).then(function(subtabId) {
                        }).catch(function(error) {
                            console.error(JSON.stringify(error));
                        });
                    }                 
                });
            }else{
                var evt = $A.get("e.force:navigateToComponent");
                evt.setParams({
                    componentDef : "c:CreatePaymentRequestItem",
                    componentAttributes: {
                        paymentrequestid : component.get("v.recordId"),
                        intializetype : 'aura'
                    }
                });
                evt.fire();
            }
        })
        .catch(function(error) {
            console.error(error);
        });
    },
    openNewSubTab : function(component, event, helper) {
        var recordUrl = event.getParam('paymentrequestitemurl');

        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            if(response){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    if(response.isSubtab){
                        workspaceAPI.openSubtab({
                            parentTabId: response.parentTabId,
                            url: recordUrl,
                            focus: false
                        }).then(function(subtabId) {
                        }).catch(function(error) {
                            console.error(JSON.stringify(error));
                        });
                    }else{
                        workspaceAPI.openSubtab({
                            parentTabId: response.tabId,
                            url: recordUrl,
                            focus: false
                        }).then(function(subtabId) {
                        }).catch(function(error) {
                            console.error(JSON.stringify(error));
                        });
                    }                 
                });
            }else{
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": recordUrl
                });
                urlEvent.fire();
            }
        })
        .catch(function(error) {
            console.error(error);
        });
    }
})