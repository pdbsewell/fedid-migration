({
	openContactEnquiriesReport : function(component, event, helper) {
		var navigationService = component.find('navigationService');
        // Sets the route to /lightning/o/Account/home
        var pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Report',
                actionName: 'home'
            }
        };
        
        var workspaceAPI = component.find('workspaceService');
        workspaceAPI.getEnclosingTabId().then(function(enclosingTabId) {
            workspaceAPI.openSubtab({
                parentTabId: enclosingTabId,
                url: '/lightning/r/Report/00O0I00000ASfX5UAL/view?fv0=' + component.get('v.simpleContact.Id') + '&fv1=' + component.get('v.simpleContact.Name'),
                focus: true
            });
        });
	}
})