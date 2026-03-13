({
    doInit: function(component, event, helper) {
        
        var recordTypeId = component.get("v.recordTypeId");
        
        // Prepare a new record from template
        component.find("listingRecordCreator").getNewRecord(
            "Listing__c", // sObject type (entityAPIName)
            recordTypeId,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newListing");
                var error = component.get("v.newListingError");
                if (error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                }
                else {
                    console.log("Record template initialized: " + rec.sobjectType);
                }
            })
        );
    },
    
    handleSaveListing: function(component, event, helper) {

            component.find("listingRecordCreator").saveRecord(function(saveResult) {
                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                    // record is saved successfully
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Saved",
                        "message": "The record was saved."
                    });
                    resultsToast.fire();
                } else if (saveResult.state === "INCOMPLETE") {
                    // handle the incomplete state
                    console.log("User is offline, device doesn't support drafts.");
                } else if (saveResult.state === "ERROR") {
                    // handle the error state
                    console.log('Problem saving listing, error: ' + 
                                 JSON.stringify(saveResult.error));
                } else {
                    console.log('Unknown problem, state: ' + saveResult.state +
                                ', error: ' + JSON.stringify(saveResult.error));
                }
            });
    },

    handleLoad: function(component, event, helper) {
		console.log('load');
        var recUi = event.getParam("fields");
        console.log('load1: ' + JSON.stringify(recUi));

    },
    
    handleSubmit: function(component, event, helper) {
       
        //event.preventDefault(); // stop form submission
        //event.stopPropagation();
        
        //var eventFields = event.getParam("fields");
        // eventFields["Field__c"] = "Test Value";
        //component.find('myform').submit(eventFields);
    },
    
    handleSuccess: function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({"title": "Success!","message": "Event application submitted.","type": "success"});
        toastEvent.fire();
        component.find("overlayLibListingCreate").notifyClose();
        //event.preventDefault();
        //event.stopImmediatePropagation();
    },
    
    handleCancel: function(component, event, helper) {
        console.log('cancel');
		component.find("overlayLibListingCreate").notifyClose();
        console.log('closed');
    },
    
    saveWithRecordEdit : function(component, event, helper) {
        console.log('saving...');
        component.find("edit").get("e.recordSave").fire();     
    },
    
    handleSaveSuccessWithRecordEdit : function(component, event) {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({"title": "Success!","message": "Event application submitted.","type": "success"});
        toastEvent.fire();
        component.find("overlayLibListingCreate").notifyClose();   
    }    
})