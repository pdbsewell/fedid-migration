({
    initializeNewPledge : function(component, event, helper) {
        let pledgeRec = component.get("v.pledgeRec");

        if (pledgeRec != null) {
            // If there are already pre-defined designation detail due to page navigation by users
            // We need to recalculate the total amount on pledge
            var designationDetailRecList = component.get("v.designationDetailRecList");
            
            let pledgeTotalAmount = 0.00;

            for (var oneDesignationDetail of designationDetailRecList) {
                if (oneDesignationDetail.ucinn_ascendv2__Amount__c != undefined && oneDesignationDetail.ucinn_ascendv2__Amount__c != '' && oneDesignationDetail.ucinn_ascendv2__Amount__c > 0) {
                    pledgeTotalAmount += oneDesignationDetail.ucinn_ascendv2__Amount__c;
                }
            }

            component.set("v.pledgeRec.Amount", pledgeTotalAmount);
            /* End of re-calculation */
        }
    },

    calculateInstallments : function(component, event, helper) {
        helper.calculateInstallmentsWithCallback(component, event, helper, null);
    },

    calculateInstallmentsWithCallback : function(component, event, helper, otherValidationsAndCallback) {
        let MessageHandlingService = component.find("MessageHandlingService");
        let busySpinner = document.getElementById("spinner");
        if (busySpinner) {
            busySpinner.className = "slds-show";
        }

        let pledgeRec = component.get("v.pledgeRec");
        let designationDetailRecList = component.get("v.designationDetailRecList");

        let validated = true;
        validated = helper.checkDesignationDetails(component, designationDetailRecList, pledgeRec, helper);
        if (validated == false) {
            busySpinner.className = "slds-hide ";
            return;
        }

        let selectedPaymentDayOfMonth = component.get("v.portalDonationSetupParams").selectedPaymentDayOfMonth;
        var calculateInstallmentAction = component.get("c.SERVER_calculateInstallmentsForNewPledge");
        let params = {
            "pledgeRec": pledgeRec,
            "designationDetailRecList": designationDetailRecList,
            "selectedPaymentDayOfMonth": selectedPaymentDayOfMonth
        };
        calculateInstallmentAction.setParams({
            "params": params
        });
        calculateInstallmentAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnObject = response.getReturnValue();
                var installmentRecList = returnObject.installmentRecList;
                component.set("v.installmentRecList", installmentRecList);

                if (otherValidationsAndCallback != null) {
                    let busySpinner = document.getElementById("spinner");
                    if (busySpinner) {
                        busySpinner.className = "slds-hide";
                    }
                    otherValidationsAndCallback();
                    return;
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
            
            let busySpinner = document.getElementById("spinner");
            if (busySpinner) {
                busySpinner.className = "slds-hide";
            }
        });
        $A.enqueueAction(calculateInstallmentAction);
    },

    checkDesignationDetails : function(component, designationDetailRecList, helper) {

        let MessageHandlingService = component.find("MessageHandlingService");
        var portalDonationSetupParams = component.get("v.portalDonationSetupParams");
        var selectedPaymentFrequency = portalDonationSetupParams.selectedPaymentFrequency;

        var designationName = new Array();
        // var designationDetailRecList_totalAmount = 0;

        for (var i = 0 ; i < designationDetailRecList.length; i++) {
            var designationDetailRec = designationDetailRecList[i];
            designationName.push(designationDetailRec.ucinn_ascendv2__Designation__c);

            designationDetailRec.ucinn_ascendv2__Payment_Frequency__c = selectedPaymentFrequency;

            //check amount input
            if (designationDetailRec.ucinn_ascendv2__Amount__c == null || designationDetailRec.ucinn_ascendv2__Amount__c <= 0) {
                MessageHandlingService.validationError("Please specify a positive designation amount for \'" + designationDetailRec.ucinn_ascendv2__Designation__r.Name + "\'.");
                return false;
            }
            else if (designationDetailRec.ucinn_ascendv2__Number_of_Payments__c <= 0) {
                MessageHandlingService.validationError("Please specify a positive number of payments for \'" + designationDetailRec.ucinn_ascendv2__Designation__r.Name + "\'.");
                return false;
            }
            else if (!designationDetailRec.ucinn_ascendv2__Number_of_Payments__c) {
                MessageHandlingService.validationError("Please specify the number of payments for \'" + designationDetailRec.ucinn_ascendv2__Designation__r.Name + "\'.");
                return false;
            }
            // else {
            //     designationDetailRecList_totalAmount += designationDetailRec.ucinn_ascendv2__Amount__c;

            //     // i is not at the end of the iteration
            //     if (i != designationDetailRecList.length-1) {
            //         continue;
            //     }
            //     else{
            //         if(designationDetailRecList_totalAmount != pledgeRec.Amount) {
            //             var errorMsg = "The total amount of $" + designationDetailRecList_totalAmount + " for the designation details does not match the pledge amount of $" + pledgeRec.Amount
            //             MessageHandlingService.validationError(errorMsg);
            //             return false;
            //         }
            //     }
            // }
        }
        return true;
    },

    checkTributeDetails : function (component, tributeRecList, helper) {
        let MessageHandlingService = component.find("MessageHandlingService");

        if (tributeRecList == null) {
            return true;
        }

        for (let tributeRec of tributeRecList) {

            if (!tributeRec.ucinn_ascendv2__Tribute_Type__c) {
                MessageHandlingService.validationError("Please specify a tribute type for the Tributes Information.");
                return false;
            }
            else if (!tributeRec.ucinn_ascendv2__Contact_Text__c) {
                MessageHandlingService.validationError("Please specify a constituent for the Tributes Information.");
                return false;
            }
            else if (!tributeRec.ucinn_ascendv2__Tributee__c) {
                MessageHandlingService.validationError("Please specify a tributee for the Tributes Information.");
                return false;
            }
            else if (!tributeRec.ucinn_ascendv2__Notify_Contact_Text__c) {
                MessageHandlingService.validationError("Please specify notify for the Tributes Information.");
                return false;
            }
            else if (!tributeRec.ucinn_ascendv2__Notify_Address__c) {
                MessageHandlingService.validationError("Please specify an address for the Tributes Information.");
                return false;
            }
            else if (!tributeRec.ucinn_ascendv2__Occasion__c) {
                MessageHandlingService.validationError("Please specify an occasion for the Tributes Information.");
                return false;
            }
        }
        return true;
    }
})