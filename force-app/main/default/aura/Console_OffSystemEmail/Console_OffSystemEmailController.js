({
    doInit : function(component, event, helper) {
        // Get a reference to the init() function defined in the Apex controller
        var action = component.get("c.init");
        action.setParams({"recordId": component.get("v.recordId")});
        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if(state === "SUCCESS") {
                // Set the component attributes using values returned by the API call
                var thisWrapper = response.getReturnValue();
                component.set("v.wrapperClass", thisWrapper);
                console.log(thisWrapper);

                var lstOptions = [];
                for(var i=0; i < thisWrapper.lstFacultyOptionsWrapper.length; i++){
                    lstOptions.push({
                        value : thisWrapper.lstFacultyOptionsWrapper[i].strEmailAddress,
                        key : thisWrapper.lstFacultyOptionsWrapper[i].strLabel
                    });
                }
                lstOptions.sort();
                component.set('v.facultyOptions', lstOptions);
                component.set('v.contactId', thisWrapper.caseRecord.ContactId);
                component.set('v.listAttachments', thisWrapper.lstAttachments);
                component.set('v.listContentDocuments', thisWrapper.lstContentDocuments);
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
    },
   
    doHandleChange : function(component, event, helper) {
        // Get a reference to the init() function defined in the Apex controller
        var selObject = component.find('selectObject').get('v.value');
        component.set('v.recipientAddress', selObject);
    },

    doSelectAttachment : function(component, event, helper) {
        var selected = [], checkboxes = component.find("attachmentsCheckbox");
        if(!checkboxes) {   // Find returns zero values when there's no items
            checkboxes = [];
        } else if(!checkboxes.length) { // Find returns a normal object with one item
            checkboxes = [checkboxes];
        }
        checkboxes.filter(checkbox => checkbox.get("v.value"))    // Get only checked boxes
        .forEach(checkbox => selected.push(checkbox.get("v.text")));   // And get the labels
        component.set("v.selectedAttachments", selected);    // Set to display

        console.log('Selected Attachments: ' + component.get('v.selectedAttachments'));
    },

    doSendPreview : function(component, event, helper) {
        // Get a reference to the init() function defined in the Apex controller
        var action = component.get("c.initiateSendingEmail");
        action.setParams({
            "RecordId": component.get("v.recordId"),
            "ToEmailAddress": component.get("v.recipientAddress"),
            "lstAttIds": component.get("v.selectedAttachments"),
            "previewMode": "True",
            "emailMessageBody": component.find("emailMessage").get("v.value")
        });

        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if(state === "SUCCESS") {
                // Set the component attributes using values returned by the API call
                var thisWrapper = response.getReturnValue();
                component.set("v.wrapperClass", thisWrapper);
                console.log(thisWrapper.strFeedbackMessage);

                var feedbackMsg = thisWrapper.strFeedbackMessage;
                var toastType = '';
                var toastTitle = '';

                if(feedbackMsg.includes('Preview sent to')){
                    toastType = 'success';
                    toastTitle = 'Preview Sent!';
                }else if(feedbackMsg.includes('You need to link')){
                    toastType = 'Error';
                    toastTitle = 'Error Sending';
                }

                //Show success toast
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'type': toastType,
                    'title': toastTitle,
                    'message': feedbackMsg
                });
                toastEvent.fire();

                //Refresh standard components on page
                $A.get('e.force:refreshView').fire();

            }else{
                console.log(state);
            }
            
            //Hide spinner
		    component.set('v.showSendOffEmailSpinner', false);
        });
        
        //Show spinner
		component.set('v.showSendOffEmailSpinner', true);
    		
        // Invoke the service
        $A.enqueueAction(action);
    },

    doSend : function(component, event, helper) {		
        var recipient = component.get("v.recipientAddress");
        var staticLabel = $A.get("$Label.c.Off_System_Default_Message");
        if(recipient === '' || recipient === undefined){
            //Show success toast
            var toastEvent = $A.get('e.force:showToast');
            toastEvent.setParams({
                'type': 'Error',
                'title': 'Error',
                'message': 'Please select a recipient first'
            });
            toastEvent.fire();
			
            //Refresh standard components on page
            $A.get('e.force:refreshView').fire();
            
        }else{
            // Get a reference to the init() function defined in the Apex controller
            var action = component.get("c.initiateSendingEmail");
            action.setParams({
                "RecordId": component.get("v.recordId"),
                "ToEmailAddress": component.get("v.recipientAddress"),
                "lstAttIds": component.get("v.selectedAttachments"),
                "previewMode": "False",
                "emailMessageBody": component.find("emailMessage").get("v.value")
            });

            // Register the callback function
            action.setCallback(this, function(response) {
                //store state of response
                var state = response.getState();
                if(state === "SUCCESS") {
                    // Set the component attributes using values returned by the API call
                    var thisWrapper = response.getReturnValue();
                    component.set("v.wrapperClass", thisWrapper);
                    console.log(thisWrapper.strFeedbackMessage);

                    var feedbackMsg = thisWrapper.strFeedbackMessage;
                    var toastType = '';
                    var toastTitle = '';

                    if(feedbackMsg.includes('Successfully sent')){
                        toastType = 'success';
                        toastTitle = 'Email Sent';
                        /* Start - APR - 6/11/18 - Fix to reset values of field after sending */
                        component.set('v.recipientAddress', '');
                        component.find("emailMessage").set("v.value", staticLabel);
                        /* End - APR - 6/11/18 */
                    }else if(feedbackMsg.includes('You need to link')){
                        toastType = 'Error';
                        toastTitle = 'Error Sending';
                    }

                    //Show success toast
                    var toastEvent = $A.get('e.force:showToast');
                    toastEvent.setParams({
                        'type': toastType,
                        'title': toastTitle,
                        'message': feedbackMsg
                    });
                    toastEvent.fire();

                    //Refresh standard components on page
                    $A.get('e.force:refreshView').fire();
                }else{
                    console.log(state);
                }
                
                //Hide spinner
    		    component.set('v.showSendOffEmailSpinner', false);
            });
            
            //Show spinner
    		component.set('v.showSendOffEmailSpinner', true);
		
            // Invoke the service
            $A.enqueueAction(action);
        }
    },

})