({
	doInit: function (component, event, helper) {
	    helper.retrieveContentDocuments(component, event);
    },
	handleFilesChange : function(component, event, helper) {
		var fileName = 'No File Selected..';
        if (event.getSource().get('v.files').length > 0) {
            fileName = event.getSource().get('v.files')[0]['name'];
        }
        component.set('v.fileName', fileName);
        
        //Upload file
        if(component.find('fileId').get('v.files').length > 0) {
            //helper.uploadHelper(component, event);
        } else {
            alert('Please Select a Valid File');
        }
	},
	submitFile : function(component, event, helper) {
	    //Upload file
        helper.uploadHelper(component, event);
	},
	doSave: function(component, event, helper) {
        if(component.find('fileId').get('v.files').length > 0) {
            helper.uploadHelper(component, event);
        } else {
            alert('Please Select a Valid File');
        }
    },
    removeDocument: function(component, event, helper) {
        //Show remove confirmation form
        component.set('v.showRemoveConfirmationForm', true);
        
        var div = event.currentTarget;
        var documentId = div.getAttribute('data-documentVersionId');
        var documentName = div.getAttribute('data-documentVersionTitle');
        
        //Set document details
        component.set('v.removeDocumentId', documentId);
        component.set('v.removeDocumentName', documentName);
    },
    cancelRemoveDocument: function(component, event, helper) {
        //Hide remove confirmation form
        component.set('v.showRemoveConfirmationForm', false);
    },
    confirmRemoveDocument: function(component, event, helper) {
        //Show spinner
        component.set('v.showRemoveDocumentSpinner', true);
        
        //Disable button
        var cancelBtn = component.find('cancelRemoveBtn');
        cancelBtn.set('v.disabled', true);
        
        var submitBtn = component.find('submitRemoveBtn');
        submitBtn.set('v.disabled', true);
        
        //Initialize Action
        var action = component.get('c.deleteFile');
        
        //Set Id of Application
        action.setParams({ documentId : component.get('v.removeDocumentId') });
        
        // Create a callback that is executed after the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                helper.retrieveContentDocuments(component, event);
                
                //Hide spinner
                component.set('v.showRemoveDocumentSpinner', false);
                component.set('v.showRemoveConfirmationForm', false);
                
                //Enable button
                var cancelBtn = component.find('cancelRemoveBtn');
                cancelBtn.set('v.disabled', true);
                
                var submitBtn = component.find('submitRemoveBtn');
                submitBtn.set('v.disabled', true);
            }
            else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE');
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + 
                                 errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
        });

        $A.enqueueAction(action);
    }
})