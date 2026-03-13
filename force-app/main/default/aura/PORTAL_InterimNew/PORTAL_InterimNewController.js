({
    doInit : function(component, event, helper) {
        let MessageHandlingService = component.find("MessageHandlingService");
        let initializeNewInterimWithOnlineDonationRecordAction = component.get("c.SERVER_initializeNewInterimWithOnlineDonationRecord");
        let params = {
        };
        initializeNewInterimWithOnlineDonationRecordAction.setParams({"params":params});
        initializeNewInterimWithOnlineDonationRecordAction.setCallback(this, function(response) {
            var returnObject = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                var interimRec = returnObject.interimRec;
                component.set("v.interimRec", interimRec);
                component.set("v.recordTypeId", interimRec.RecordTypeId);
            }
            else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            }
            else if (state === "ERROR") {
                let error = response.getError();
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                    MessageHandlingService.errorServerCall();
                }
            }
        });
        $A.enqueueAction(initializeNewInterimWithOnlineDonationRecordAction);
    },

    handleLoad : function(component, event, helper) {
        event.preventDefault();
    },

    handleSubmit : function(component, event, helper) {
        let MessageHandlingService = component.find("MessageHandlingService");
        event.preventDefault();
        var fields = event.getParam("fields");
        var interimRec = component.get("v.interimRec");
        helper.copyJsObjectProperties(fields, interimRec);

        let createInterimAction = component.get("c.SERVER_createInterimForUnknownPortalUsers");
        let params = {
            "interimRec": interimRec
        };
        createInterimAction.setParams({"params":params});
        createInterimAction.setCallback(this, function(response) {
            var returnObject = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                var interimRec = returnObject.interimRec;
                component.set("v.interimRec", interimRec);
                component.set("v.interimRecordId", interimRec.Id);
                component.set("v.saved", true);
            }
            else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            }
            else if (state === "ERROR") {
                let error = response.getError();
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                    MessageHandlingService.errorServerCall();
                }
            }
        });
        $A.enqueueAction(createInterimAction);
    },

    handleSuccess : function(component, event, helper) {
        event.preventDefault();
    },

    submitFormSync : function(component, event, helper) {
        // var submitBtn = component.find("submitBtn");
        // submitBtn.submit();
        document.getElementById("specialInterimFormSubmit").click();
        return;
    }
})