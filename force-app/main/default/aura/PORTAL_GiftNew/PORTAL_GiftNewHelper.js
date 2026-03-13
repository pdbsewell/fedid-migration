({
    initializeNewGift : function (component, event, helper) {
        let giftRec = component.get("v.giftRec");

        if (giftRec != null) {
            // If there are already pre-defined designation detail due to page navigation by users
            // We need to recalculate the total amount on pledge
            var designationDetailRecList = component.get("v.designationDetailRecList");
            
            let giftTotalAmount = 0.00;

            for (var oneDesignationDetail of designationDetailRecList) {
                if (oneDesignationDetail.ucinn_ascendv2__Amount__c != undefined && oneDesignationDetail.ucinn_ascendv2__Amount__c != '' && oneDesignationDetail.ucinn_ascendv2__Amount__c > 0) {
                    giftTotalAmount += oneDesignationDetail.ucinn_ascendv2__Amount__c;
                }
            }

            component.set("v.giftRec.Amount", giftTotalAmount);
            /* End of re-calculation */
        }
    },

    checkDesignationDetails : function (component, designationDetailRecList, helper) {

        let MessageHandlingService = component.find("MessageHandlingService");

        for (let designationDetailRec of designationDetailRecList) {

            if (designationDetailRec.ucinn_ascendv2__Amount__c == null || designationDetailRec.ucinn_ascendv2__Amount__c == "" || designationDetailRec.ucinn_ascendv2__Amount__c <= 0) {
                MessageHandlingService.validationError("Please specify a positive designation amount for \'" + designationDetailRec.ucinn_ascendv2__Designation__r.Name + "\'.");
                return false;
            }
        }
        return true;
    },

    checkTributeDetails : function (component, tributeRecList, helper) {

        if (tributeRecList == null) {
            return true;
        }

        let MessageHandlingService = component.find("MessageHandlingService");

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