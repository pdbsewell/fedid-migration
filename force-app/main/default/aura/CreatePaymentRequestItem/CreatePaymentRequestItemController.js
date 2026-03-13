({
    init : function(component, event, helper) {
        document.title = 'Create Payment Request Item';

        let origin = component.get('v.intializetype');
        var pageReference = component.get('v.pageReference');
        if(pageReference){
            origin = pageReference.state.c__intializetype;
            if(pageReference.state){
                if(pageReference.state.c__paymentrequestid){
                    component.set('v.paymentrequestid', pageReference.state.c__paymentrequestid);
                }
            }
        }
        if(origin === ''){
            helper.openCreatePaymentRequestItem(component, event, helper);
        }else{ 
            var workspaceAPI = component.find("workspace");
            workspaceAPI.isConsoleNavigation().then(function(response) {
                if(response){
                    workspaceAPI.getEnclosingTabId()
                    .then(function(response) {
                        workspaceAPI.setTabIcon({
                            tabId: response,
                            icon: "custom:custom45",
                            iconAlt: "Create Payment Request Item"
                        });
                        workspaceAPI.setTabLabel({
                            tabId: response,
                            label: "Create Payment Request Item"
                        });
                        document.title = 'Create Payment Request Item';
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
    },
    openMultipleTabs : function(component, event, helper) {
        helper.openNewSubTab(component, event, helper);
    }        
})