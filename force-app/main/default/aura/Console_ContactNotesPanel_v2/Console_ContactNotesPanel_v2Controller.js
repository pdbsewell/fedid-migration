({
    doInit : function(component, event, helper) {
        // Get a reference to the init() function defined in the Apex controller
        var action = component.get("c.init");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "strSource": "CRM"
        });
        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if(state === "SUCCESS") {
                // Set the component attributes using values returned by the API call
                component.set("v.wrapperClass", response.getReturnValue());
                var myData = response.getReturnValue();
                component.set("v.lstPersonNotes",myData.lstPersonNotes);
                if(myData.userRole.includes('Connect')){
                    if(myData.bIsClosed !== true){
                        component.set("v.showSCNModal", true);
                        if(myData.bIsEncumbered === true){
                            component.set("v.isEncumbered", true);
                            component.set("v.lstEncumbrances",myData.lstEncumbrances);
                        }
                    }
                }
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
    },

    confirmNotes: function(component, event, helper) {
        component.set('v.showSCNModal', false);
        component.set("v.showSpinner", true);
        var action = component.get("c.insertCaseComments");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "bIsPersonNotes" : true
        });
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if(state === "SUCCESS") {
                component.set("v.showSpinner", false);
                component.set("v.isSCNAcknowledged", true);
                console.log('Case Comment for Special Care Notes Acknowledgement inserted.');
                console.log('Contact Encumbred: ', component.get("v.isEncumbered"));
                if(component.get("v.isEncumbered")){
                    component.set('v.showEncModal', true);
                }
            }else{
                component.set('v.showSCNModal', true);
                console.log('Case Comment for Special Care Notes Acknowledgement Failed.');
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
    },

    confirmEncumbrances: function(component, event, helper) {
        component.set('v.showEncModal', false);
        component.set("v.showSpinner", true);
        var action = component.get("c.insertCaseComments");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "bIsPersonNotes" : false
        });
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if(state === "SUCCESS") {
                component.set("v.showSpinner", false);
                component.set("v.isEncAcknowledged", true);
                console.log('Case Comment for Encumbrance Acknowledgement inserted.');
            }else{
                console.log('Case Comment for Encumbrance Acknowledgement Failed.');
                component.set('v.showEncModal', true);
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
    },

    Showhide : function(component, event, helper) {
        var checkBoxState = event.getSource().get('v.value');
        component.find("disableenable").set("v.disabled", !checkBoxState);
    },

    handleClick: function (component, event, helper) {
        var wrapper = component.get("v.wrapperClass");
        var relatedListEvent = $A.get("e.force:navigateToRelatedList");
        relatedListEvent.setParams({
            "relatedListId": "Person_Notes__r",
            "parentRecordId": wrapper.contactId
        });
        relatedListEvent.fire();
    }

})