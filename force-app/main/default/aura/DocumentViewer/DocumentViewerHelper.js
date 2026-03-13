({
    retrieveContactDocumentUrlId : function(component, event, helper) {
        //Parse the URL
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedApplicationId = '';
        var retrievedContactDocumentId = '';
        var retrievedDocumentChecklistId = '';
        var retrievedOfferId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if(sParameterName[j] === 'app'){
                    retrievedApplicationId = sParameterName[j+1];
                }
                if (sParameterName[j] === 'cd') { //get the app Id from the parameter
                    retrievedContactDocumentId = sParameterName[j+1];
                }
                if(sParameterName[j] === 'dc'){
                    retrievedDocumentChecklistId = sParameterName[j+1];
                }
                if(sParameterName[j] === 'opp'){
                    retrievedOfferId = sParameterName[j+1];
                }
            }
        }
        
        if(retrievedApplicationId != '') {
            component.set("v.selectedApplicationId", retrievedApplicationId);
        }
        if(retrievedContactDocumentId != '') {
            component.set("v.selectedContactDocumentId", retrievedContactDocumentId);
        }
        if(retrievedDocumentChecklistId != '') {
            component.set("v.selectedDocumentChecklistId", retrievedDocumentChecklistId);
        }
        if(retrievedOfferId != '') {
            component.set("v.selectedOfferId", retrievedOfferId);
        }        
    },
    setupSplitListener : function(component, event, helper) {
        window.addEventListener("message", function(event) {
            //Process splitting response
            if(event.data.name == 'SplitFileResponse'){

                //Store split result data
                component.set('v.splitResultData', event.data.data);
                //Send data downwards
                component.find('fileChecklistSection').splitResultSent();

            }else if(event.data.name == 'DetermineFileDetailsResponse'){    

                component.set('v.totalPageCount', event.data.data);
                component.set('v.pageReady', true);

            }else if(event.data.name == 'DetermineFileDetailsPdfResponse'){

                component.set('v.selectedContentDocumentData', event.data.pdfBlob);
                component.set('v.totalPageCount', event.data.data);
                component.set('v.pageReady', true);

            }
        }, false);
    },
    retrieveFileDetails : function(component, event, helper) {
        var action = component.get("c.retrieveContentDocumentData");
        action.setParams({
            "contactDocumentId" : component.get("v.selectedContactDocumentId")
        });

        action.setCallback(this, function(response){
            var state = response.getState();

            if(state === 'SUCCESS'){
                var result = response.getReturnValue();                

                //Retrieve contact document info
                component.set("v.checklistId", result.ContactDocument.Document_Checklist__c);
                if(result.ContactDocument.Application__c){
                    component.set("v.applicationId", result.ContactDocument.Application__c);
                    component.set("v.applicantId", result.ContactDocument.Application__r.Applicant__c);
                }

                if(result.ContactDocument.Opportunity__c){
                    component.set("v.offerId", result.ContactDocument.Opportunity__c);
                    component.set("v.applicantId", result.ContactDocument.Opportunity__r.PrimaryContact__c);
                } 
                
                //Set checklist options
                component.set('v.checklistsMap', result.ChecklistMap);
                //Set checklist document types
                component.set('v.checklistDocumentTypesMap', result.ChecklistDocumentTypeMap);
                //Set file extension
                component.set('v.fileExtensionType', result.FileExtension);

                //Retrieve primary file info
                if(result.ContentLink){
                    component.set("v.selectedContentDocumentLink", result.ContentLink);
                }
                if(result.ContentDocumentBody){
                    if(result.FileExtension === 'html'){
                        var htmlFile = new Blob([result.ContentDocumentBody], {type : 'text/html'});
                        var reader = new FileReader();
                        reader.onloadend = function() {
                            component.set("v.selectedContentDocumentData", atob(reader.result));
                        }
                        reader.readAsText(htmlFile);
                    }else{
                        component.set("v.selectedContentDocumentData", result.ContentDocumentBody);
                    }
                }

                //Set browser title
                document.title = result.DocumentName;
                
                //Flag component is complete initializing
                component.set("v.initializeReady", true);

                //Ensure frame and initialize is ready before reading the initial file content
                let frameReady = component.get('v.frameReady');
                if(frameReady){
                    helper.readFileDetails(component, event, helper);
                }
            }
        });

        $A.enqueueAction(action);
    },
    retrieveChecklistDetails : function(component, event, helper) { 
        var action = component.get("c.retrieveChecklistData");
        action.setParams({
            "relatedId" : component.get("v.selectedApplicationId") ? component.get("v.selectedApplicationId") : component.get("v.selectedOfferId"),
            "documentChecklistId" : component.get("v.selectedDocumentChecklistId")
        });

        action.setCallback(this, function(response){
            var state = response.getState();

            if(state === 'SUCCESS'){
                var result = response.getReturnValue();                

                //Retrieve contact document info
                component.set("v.checklistId", component.get("v.selectedDocumentChecklistId"));
                component.set("v.applicationId", component.get("v.selectedApplicationId"));
                component.set("v.offerId", component.get("v.selectedOfferId"));                
                component.set("v.applicantId", result.Applicant);

                //Set browser title
                document.title = 'Select a file';
                
                //Set checklist options
                component.set('v.checklistsMap', result.ChecklistMap);
                //Set checklist document types
                component.set('v.checklistDocumentTypesMap', result.ChecklistDocumentTypeMap);
                
                //Flag component is complete initializing
                component.set("v.pageReady", true);
                component.set("v.initializeReady", true);

                //Ensure frame and initialize is ready before reading the initial file content
                let frameReady = component.get('v.frameReady');
                if(frameReady){
                    helper.readFileDetails(component, event, helper);
                }
            }
        });

        $A.enqueueAction(action);
    },
    retrieveNewChecklistList : function(component, event, helper) {
        var action = component.get("c.retrieveContentDocumentData");
        action.setParams({
            "contactDocumentId" : component.get("v.selectedContactDocumentId")
        });

        action.setCallback(this, function(response){
            var state = response.getState();

            if(state === 'SUCCESS'){
                var result = response.getReturnValue();                

                //Set checklist options
                component.set('v.checklistsMap', result.ChecklistMap);
                //Set checklist name options
                component.set('v.checklistsNameMap', result.ChecklistNameMap);
                //Set checklist document types
                component.set('v.checklistDocumentTypesMap', result.ChecklistDocumentTypeMap);
                
                //Flag component is complete initializing
                component.set("v.initializeReady", true);
            }
        });

        $A.enqueueAction(action);
    },
    readFileDetails : function(component, event, helper) {
         //Organize request data
         var message = {};
         message.name = 'DetermineFileDetailsRequest';
         message.hostUrl = window.location.hostname;
         message.contentDocumentData = component.get('v.selectedContentDocumentData');
         message.fileType = component.get('v.fileExtensionType');
         
         //Send request
         component.find('documentSplitter').getElement().contentWindow.postMessage(message, '*');
    },
    requestSplitting : function(component, event, helper) {
        //Organize request data
        var message = {};
        message.name = 'SplitFileRequest';
        message.requestedPages = component.get('v.requestedPages');
        message.hostUrl = window.location.hostname;
        message.contentDocumentData = component.get('v.selectedContentDocumentData');
        
        //Send request
        component.find('documentSplitter').getElement().contentWindow.postMessage(message, '*');
    }
})