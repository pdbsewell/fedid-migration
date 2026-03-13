({
	doInit : function(component, event, helper) {

		helper.showSpinner(component);

		helper.getAppId(component);

        var appId = component.get("v.appId");

        if(appId)
        {
            var action = component.get("c.getInitLoad");
            action.setParams({
                "appId" : appId
            });
            action.setCallback(this, function(response){
                //Get State
                var state = response.getState();
                if(state == "SUCCESS")
                {
                    console.log('FileUploaderController::getInitLoad');

                    var objResponse = response.getReturnValue();

                    // user
                    var objUser = objResponse.user;
                    component.set("v.user", objUser);

                    // contact/applicant
                    var contactId = objResponse.contactId;
                    component.set("v.contactId", contactId);

                    // doc type options
                    var docTypeOptions = objResponse.documentTypes;
                    component.set("v.documentTypeOptions", docTypeOptions);

                    // documents
                    var listDocuments = objResponse.contactDocuments;
                    component.set("v.documents", listDocuments);

                    helper.hideSpinner(component);
                }
            });
            $A.enqueueAction(action);
        }
        else {
            helper.hideSpinner(component);
        }


	},


	saveContactDoc : function(component, event, helper){

		helper.showSpinner(component);
        var action = component.get("c.saveFileAndContactDocument");

        var fileId = component.get("v.fileId");
        var contactId = component.get("v.contactId");
        var appId = component.get("v.appId");
        var docType = component.get("v.documentTypeSelection");
        var docSubType = component.get("v.documentSubTypeSelection");
        var comments = component.get("v.documentComments");

        var objParams = {
            "fileId": fileId,
			"contactId": contactId,
			"appId": appId,
			"docTypeValue": docType,
			"docSubTypeValue": docSubType,
			"docComments": comments
		};

        console.log('saveContactDoc{');
        for(var k in objParams)
		{
			console.log(k + ':' + objParams[k]);
		}
		console.log('}');

        action.setParams(objParams);
        action.setCallback(this, function(response){
            //Get State
            var state = response.getState();
            if(state == "SUCCESS")
            {
                console.log('FileUploaderController::saveFileAndContactDocument');
                var objResponse = response.getReturnValue();
                console.log(objResponse);

                // refresh the documents list
                var listDocuments = objResponse.contactDocuments;
                component.set("v.documents", listDocuments);

                // close the modal
                component.set("v.addDocumentModal", false);
                // clear states
                helper.clearModalState(component);
                // hide the spinner
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(action);

	},

	submitDocuments : function(component, event, helper){
		console.log("Test");
		var appId = component.get("v.appId");
		console.log(appId);
		helper.saveDocuments(component, appId, true);
	},

	removeDocument : function(component, event, helper)
	{
		helper.showSpinner(component);
		var documentId = event.target.id;
		var appId = component.get("v.appId");
        var action = component.get("c.RemoveContactDocument");
        action.setParams({
            "conDocId" : documentId,
			"appId" : appId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                var objResponse = response.getReturnValue();
                if(objResponse.deleteStatus == 'failed')
				{
					console.error('FileUploaderController:: error in removing ' + objResponse.message);
				}

                // refresh the documents list
                var listDocuments = objResponse.contactDocuments;
                component.set("v.documents", listDocuments);

                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(action);
	},

	showUploadModal : function(component, event, helper){
        // clear values
        helper.clearModalState(component);
        //Pop the Document Modal
		component.set("v.addDocumentModal", true);
		window.setTimeout(
                    $A.getCallback(function() {
                       component.find("docType").focus();
                    }), 50
        );
	},

    onChangeDocType : function(component, event, helper)
    {
        var docType = component.get("v.documentTypeSelection");
        console.log('doc type = ' + docType);

        // check to enable save
		helper.updateSaveButton(component);
    },

	handleUploadFinished : function(component, event, helper){

		// remove the previous file
		var fileId = component.get("v.fileId");

		var uploadedFiles = event.getParam("files");
		var objFile = uploadedFiles[0];
		component.set("v.fileId", objFile.documentId);
		
        if(objFile.name.length > 100)
        {
            component.set("v.filenameIsTooLong", true);
        } else
        {
            component.set("v.filenameIsTooLong", false);
        }
        
		var fileName = objFile.name;
        component.set("v.documentName", fileName);
		console.log("FileUploaderController:: fileId = " + objFile.documentId + ", " + objFile.name);


        var action = component.get("c.deleteUploadedFile");
        action.setParams({
            "fileId" : fileId
        });
        action.setCallback(this, function(response){
            //Get State
            var state = response.getState();
            if(state == "SUCCESS")
            {
                console.log('FileUploaderController::Upload File deleteFile');
                var objResponse = response.getReturnValue();
                console.log(objResponse);

                helper.updateSaveButton(component);
            }
        });
        $A.enqueueAction(action);
        window.setTimeout(
                    $A.getCallback(function() {
                       component.find("comments").focus();
                    }), 50
                );
	},



    closeUploadModal : function(component, event, helper)
    {
        helper.showSpinner(component);

        var fileId = component.get("v.fileId");
        var action = component.get("c.deleteUploadedFile");
        action.setParams({
            "fileId" : fileId
        });
        action.setCallback(this, function(response){
            //Get State
            var state = response.getState();
            if(state == "SUCCESS")
            {
                console.log('FileUploaderController::Close/Cancel Modal deleteFile');
                var objResponse = response.getReturnValue();
                console.log(objResponse);
            }

            helper.clearModalState(component);
            component.set("v.addDocumentModal", false);
            helper.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },

})