({
    doInit : function(component, event, helper) {

        let processTransactionAction = component.get("c.SERVER_ProcessTransactionBy_ascend");
        let MessageHandlingService = component.find("MessageHandlingService");
        let params = {
            "transactionId": component.get("v.recordId")
        }
        console.log(params);
        processTransactionAction.setParams({"params": params
        });
        processTransactionAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.finishedProcessing", true);
                setTimeout(function() {
                    $A.get("e.force:closeQuickAction").fire();
                }, 2000);
            } else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            } else if (state === "ERROR") {
                let error = response.getError();
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                    MessageHandlingService.errorServerCall();
                }
            }
        });
        $A.enqueueAction(processTransactionAction);
    }
})