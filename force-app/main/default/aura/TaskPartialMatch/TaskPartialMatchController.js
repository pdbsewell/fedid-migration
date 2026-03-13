({
    init: function (component, event, helper) {
        component.set("v.showSpinner",true);
        helper.onLoad(component, event, helper);
    },

    updateSelectedText: function (cmp, event) {
        var selectedRows = event.getParam('selectedRows');
        cmp.set('v.selectedRowsCount', selectedRows.length);
    },
    
    loadMoreData: function (component, event, helper) {
        //Display a spinner to signal that data is being loaded
        event.getSource().set("v.isLoading", true);
        //Display "Loading" when more data is being loaded
        component.set('v.loadMoreStatus', 'Loading');
        helper.fetchData(component, component.get('v.rowsToLoad')).then($A.getCallback(function (data) {
            if (component.get('v.data').length >= component.get('v.totalNumberOfRows')) {
                component.set('v.enableInfiniteLoading', false);
                component.set('v.loadMoreStatus', 'No more data to load');
            } else {
                var currentData = component.get('v.data');
                //Appends new data to the end of the table
                var newData = currentData.concat(data);
                component.set('v.data', newData);
                component.set('v.loadMoreStatus', 'Please wait ');
            }
            event.getSource().set("v.isLoading", false);
        }));
    },
    
    merge : function(component, event, helper) {
        component.set("v.showSpinner",true);
        helper.mergeContacts(component, event, helper);
    },

    proceedAction : function(component, event, helper) {

        var duplicateCheckOutcomeField = component.find("duplicateCheckOutcomeField");
        var value = duplicateCheckOutcomeField.get("v.value");
        // value empty
        if(value === "") {
            duplicateCheckOutcomeField.setCustomValidity("This field is required.");
        }else {
            duplicateCheckOutcomeField.setCustomValidity(""); // if there was a custom error before, reset it
        }
        duplicateCheckOutcomeField.reportValidity();

        // execute logic
        if(value !== "") {              
            component.set("v.showSpinner", true);        
            let applicationRecord = component.get('v.simpleApplicationRecord');
            applicationRecord.Duplicate_Check_Outcome__c = component.get('v.duplicateCheckOutcomeValue');

            // do not update Status field if it's in Sent Draft Application to Applicant
            // https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/467632201/Change+Log+Declaration+email+not+received+by+the+applicant#Solution-Option:-Handle-Duplicates-on-%E2%80%9CSent-Draft-Application-to-Applicant-Status%E2%80%9D
            if(applicationRecord.Status__c != 'Sent Draft Application to Applicant') {
                applicationRecord.Status__c = 'Sent for Submission';
            }
            applicationRecord.Task_Duplicate_Check__c = 'Completed';

            component.set('v.simpleApplicationRecord', applicationRecord);
            component.find("recordHandler").saveRecord($A.getCallback(function(saveResult) {
                // use the recordUpdated event handler to handle generic logic when record is changed
                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                    // handle component related logic in event handler
                } else if (saveResult.state === "INCOMPLETE") {
                    console.log("User is offline, device doesn't support drafts.");
                } else if (saveResult.state === "ERROR") {
                    console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
                } else {
                    console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                }
                component.set("v.showSpinner", false);  
            }));
        }
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            // get the fields that changed for this record
            var changedFields = eventParams.changedFields;
            console.log('Fields that are changed: ' + JSON.stringify(changedFields));
            // record is changed, so refresh the component (or other component logic)
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                'type': 'success',
                'title': 'Success!',
                "message": "Application successfully Sent for Submission."
            });
            resultsToast.fire();

        } else if(eventParams.changeType === "LOADED") {
            // record is loaded in the cache
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted and removed from the cache
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving or deleting the record
        }
    }
})