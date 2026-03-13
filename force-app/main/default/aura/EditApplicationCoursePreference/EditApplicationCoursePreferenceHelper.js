({
    openEditCourseOffering : function(component, event, helper) {
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
                                    "componentName": "c__EditApplicationCoursePreference"
                                },
                                "state": {
                                    "uid" : component.get("v.recordId") + 'EditApplicationCoursePreference',
                                    "c__acpid": component.get("v.recordId"),
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
                                    "componentName": "c__EditApplicationCoursePreference"
                                },
                                "state": {
                                    "uid" : component.get("v.recordId") + 'EditApplicationCoursePreference',
                                    "c__acpid": component.get("v.recordId"),
                                    "c__intializetype": 'aura'
                                }
                            }
                        }).then(function(subtabId) {
                            console.log('went here3');
                        }).catch(function(error) {
                            console.error(JSON.stringify(error));
                        });
                    }                 
                });
            }else{
                var evt = $A.get("e.force:navigateToComponent");
                evt.setParams({
                    componentDef : "c:EditApplicationCoursePreference",
                    componentAttributes: {
                        acpid : component.get("v.recordId"),
                        intializetype : 'aura'
                    }
                });
                evt.fire();
            }
        })
        .catch(function(error) {
            console.error(error);
        });
    }
})