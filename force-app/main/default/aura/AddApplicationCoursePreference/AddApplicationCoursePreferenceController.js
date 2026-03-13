({
    init : function(component) {
        //Open subtab if component is called from the related list
        let origin = component.get('v.openedOnRelatedList');
        if(origin === 'relatedList'){   //  on first initial load, set call navigateToComponent and set applicationId so it can open in console sub tab
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:AddApplicationCoursePreference",
                componentAttributes: {
                    applicationId : component.get("v.parentFieldId"),
                    openedOnRelatedList : 'aura'
                }
            });
            evt.fire();
            component.set('v.openedOnRelatedList', '');
        }else{ // open the component in console sub tab
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getEnclosingTabId()
            .then(function(response) {
                workspaceAPI.setTabIcon({
                    tabId: response,
                    icon: "custom:custom5",
                    iconAlt: "Application Course Preference"
                });
                workspaceAPI.setTabLabel({
                    tabId: response,
                    label: "New ACP"
                });
                component.set('v.openedOnRelatedList', '');
            })
            .catch(function(error) {
                console.log(error);
            });
        }
    },
    closeTab : function(component, event, helper) {
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