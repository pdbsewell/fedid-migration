({
    doInit : function(component, event, helper) {
        // Get a reference to the init() function defined in the Apex controller
        var action = component.get("c.init");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "strSource": "Callista"
        });
        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            console.log('state: ' + state);
            if(state === "SUCCESS") {
                // Set the component attributes using values returned by the API call
                component.set("v.wrapperClass", response.getReturnValue());
                var myData = response.getReturnValue();

                console.log('Special Care Notes: ' + myData.bHasSpecialCareNotes);
                console.log('Encumbrances: ' + myData.bIsEncumbered);
                if(myData.userRole.includes('Connect')){
                    if(myData.studentId != null){
                        if(myData.bIsEncumbered === true){
                            component.set("v.isEncumbered", true);
                            component.set("v.lstEncumbrances",myData.lstEncumbrances);
                            if(myData.bHasSpecialCareNotes === false){
                                if(myData.bIsClosed !== true) {
                                    component.set("v.showEncModal", true);
                                }
                            }
                        }
                    }
                }
                component.set("v.lstPersonNotes",myData.lstPersonNotes);
                console.log(myData.lstPersonNotes);
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
    },

    enquiryUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            component.find('caseRecordLoader').reloadRecord();
            var a = component.get('c.doInit');
            component.set("v.isacknowledged", true);
            $A.enqueueAction(a);
        }
    },

    refresh : function(component, event, helper) {
        var vWrapper = component.get("v.wrapperClass");
        component.set("v.wrapperClass.studentId", '');

        var a = component.get('c.doInit');
        $A.enqueueAction(a);
    },

    Showhide : function(component, event, helper) {
        var checkBoxState = event.getSource().get('v.value');
        component.find("disableenable").set("v.disabled", !checkBoxState);
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
    }
})