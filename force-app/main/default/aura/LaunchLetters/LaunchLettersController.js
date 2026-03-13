({
    initialize: function(component) {
      
        var myPageRef = component.get("v.pageReference");
        var studentId = myPageRef.state.c__studentId;
        var contactId = myPageRef.state.c__contactId;
        component.set("v.studentId", studentId);
        component.set("v.contactId", contactId);
        
        // Set subtab label to Entitlements (otherwise defaults to "Loading..."")
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId().then(function(response) {
            var enclosingTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: enclosingTabId,
                label: "Letters"
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    onPageReferenceChange: function(component) {
        var myPageRef = component.get("v.pageReference");
        var studentId = myPageRef.state.c__studentId;
        var contactId = myPageRef.state.c__contactId;
        component.set("v.studentId", studentId);
        component.set("v.contactId", contactId);
    }
})