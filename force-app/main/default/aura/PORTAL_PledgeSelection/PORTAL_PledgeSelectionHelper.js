({
    getDataHelper : function(component, event, helper) {

        // let busySpinner = document.getElementById("spinner");
        // if (busySpinner) {
        //     busySpinner.className = "slds-show";
        // }

        let getDataAction = component.get("c.getPledgeRecords");
        var params = {
            "strObjectName":"Opportunity",
            "strFieldSetName":"DataTablePledgeFieldSet",
            "constituentId":component.get("v.constituentId"),
            "organizationId":component.get("v.organizationId")
        };
        getDataAction.setParams({
            "params": params
        });
        getDataAction.setCallback(this, function(response) {
            // let busySpinner = document.getElementById("spinner");
            // if (busySpinner) {
            //     busySpinner.className = "slds-hide";
            // }
            var state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.pledgeColumnHeaders", response.getReturnValue().lstDataTableColumns);
                component.set("v.pledgeRecList", response.getReturnValue().lstDataTableData);

                if (response.getReturnValue().lstDataTableData == null || response.getReturnValue().lstDataTableData.length == 0) {
                    component.set("v.isNoActivePledgeAvailable", true);
                }
                else {
                    component.set("v.isNoActivePledgeAvailable", false);
                }
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
            component.set("v.readyToShowTable", true);
        });
        $A.enqueueAction(getDataAction);
    }
})