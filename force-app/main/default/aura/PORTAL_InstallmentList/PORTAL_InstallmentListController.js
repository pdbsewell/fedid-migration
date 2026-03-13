({
    doInit : function(component, event, helper) {
        var pledgeId = component.get("v.pledgeId");

        if (pledgeId != null) {
            let busySpinner = document.getElementById("spinner");
            if (busySpinner) {
                busySpinner.className = "slds-show";
            }

            let findInstallmentListAction = component.get("c.SERVER_findInstallmentListByPledgeId");
            let params = {"pledgeId": pledgeId};
            findInstallmentListAction.setParams({
                "params": params
            });

            findInstallmentListAction.setCallback(this, function(response) {
                var state = response.getState();

                if (state === "SUCCESS") {
                    var returnObject = response.getReturnValue();
                    var installmentRecList = returnObject.installmentRecList;
                    component.set("v.installmentRecList", installmentRecList);
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
                
                let busySpinner = document.getElementById("spinner");
                if (busySpinner) {
                    busySpinner.className = "slds-hide";
                }
            });
            
            $A.enqueueAction(findInstallmentListAction);
        }
    },

    detailInfoToggled : function(component, event, helper) {
        var acc = component.find('detailInfomation');

        for (var cmp in acc) {
            $A.util.toggleClass(acc[cmp], 'slds-show');
            $A.util.toggleClass(acc[cmp], 'slds-hide');
        }
    }
})