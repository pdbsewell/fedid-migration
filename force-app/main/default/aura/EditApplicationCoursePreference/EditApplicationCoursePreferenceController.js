({
    init : function(component, event, helper) {
        document.title = 'Edit Course Offering';

        let origin = component.get('v.intializetype');
        var pageReference = component.get('v.pageReference');
        if(pageReference){
            origin = pageReference.state.c__intializetype;
            if(pageReference.state){
                if(pageReference.state.c__acpid){
                    component.set('v.acpid', pageReference.state.c__acpid);
                }
            }
        }
        if(origin === ''){
            helper.openEditCourseOffering(component, event, helper);
        }else{ 
            var workspaceAPI = component.find("workspace");
            workspaceAPI.isConsoleNavigation().then(function(response) {
                if(response){
                    workspaceAPI.getEnclosingTabId()
                    .then(function(response) {
                        workspaceAPI.setTabIcon({
                            tabId: response,
                            icon: "custom:custom5",
                            iconAlt: "Application Course Preference"
                        });
                        workspaceAPI.setTabLabel({
                            tabId: response,
                            label: "Edit Course Offering"
                        });
                        document.title = 'Edit Course Offering';
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