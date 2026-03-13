({

	getAppId:function(component)
	{
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedAppId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                    component.set("v.appId", retrievedAppId);
                    return;
                }
            }
        }
	},

	updateSaveButton:function(component)
	{
        component.set("v.modalSaveDisabled", true);

		// check if there's a file
		var fileId = component.get("v.fileId");
		var docType = component.get("v.documentTypeSelection");
		var filenameIsTooLong = component.get("v.filenameIsTooLong");
		if(fileId && docType && !filenameIsTooLong)
		{
			component.set("v.modalSaveDisabled", false);
		}
	},

	showSpinner: function (component, event, helper) {
        component.set("v.showSpinner", true);
    },
     
    hideSpinner: function (component, event, helper) {
        component.set("v.showSpinner", false);
	},

	clearModalState : function(component)
	{
		component.set("v.fileId", null);
		component.set("v.documentId", "");
		component.set("v.documentTypeSelection", "");
		component.set("v.documentSubTypeSelection", "");
		component.set("v.documentName", "");
		component.set("v.documentComments", "");
		component.set("v.modalSaveDisabled", true);
	},

	saveDocuments : function(component, appId, saveSubmitted) {
		var action = component.get("c.SubmitDocuments");
		action.setParams({
			"appId" : appId,
			"saveSubmitted" : saveSubmitted
		});
		action.setCallback(this, function(response){
			var state = response.getState();
			console.log(state);
			if(state === 'SUCCESS'){
				console.log(response.getReturnValue());
				var urlEvent = $A.get("e.force:refreshView");
                urlEvent.fire();
			}
		});
		$A.enqueueAction(action);
	},


	populateDocumentSubType : function(component){
		var action = component.get("c.GetPicklistValues");
		action.setParams({
			"fieldName" : "Type__c",
			"objectName" : "Contact_Document__c"
		});
		action.setCallback(this, function(response){
			component.set("v.documentSubTypeOptions", response.getReturnValue())
		});
		$A.enqueueAction(action);
	},

})