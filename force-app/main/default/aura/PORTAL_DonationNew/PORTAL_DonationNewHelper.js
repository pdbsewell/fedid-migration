({
    initializeAttributes : function(component, helper) {
        // availableDesignations
        component.set("v.availableDesignations", null);
        // selectedDesignations
        component.set("v.selectedDesignations", null);

        component.set("v.giftRec", null);
        component.set("v.pledgeRec", null);
        component.set("v.designationDetailRecList", null);
        component.set("v.tributeRecList", null);
        component.set("v.amountToPayToday", null);
        component.set("v.thirdPartyPaymentData", null);

        component.set("v.interimRecordId", null);
        component.set("v.transactionRecordId", null);
        component.set("v.paymentGroupId", null);
        component.set("v.showGiftReceipt", false);
    },

    clearAndHideMessage : function(component) {
        var messageDiv = component.find("messageDiv");
        messageDiv.set("v.body", null);
    },

    SERVER_createNewOnlineDonation : function(component, helper, stripeChargeId) {
        let MessageHandlingService = component.find("MessageHandlingService");

        let isAnonymousUser = component.get("v.isAnonymousUser");
        let giftTypeSelected = component.get("v.giftTypeSelected");
        let constituentRec = component.get("v.constituentRec");
        let organizationRec = component.get("v.organizationRec");
        let giftRec = component.get("v.giftRec");
        let designationDetailRecList = component.get("v.designationDetailRecList");
        let tributeRecList = component.get("v.tributeRecList");
        let pledgeRec = component.get("v.pledgeRec");
        let paymentRecWrapper = component.get("v.paymentRecWrapper");
        let installmentRecList = component.get("v.installmentRecList");
        let selectedPledgeRec = component.get("v.selectedPledgeRec");
        let interimRecordId = component.get("v.interimRecordId");
        let thirdPartyPaymentData = component.get("v.thirdPartyPaymentData");
        thirdPartyPaymentData = thirdPartyPaymentData || {};
        let amountToPayToday = component.get("v.amountToPayToday");

        let busySpinner = document.getElementById("spinner");
        if (busySpinner != null) {
            busySpinner.className = "slds-show";
        }

        let params = {
            "isAnonymousUser" : isAnonymousUser,
            "giftTypeSelected" : giftTypeSelected,
            "constituentRec" : constituentRec,
            "organizationRec" : organizationRec,
            "giftRec" : giftRec,
            "designationDetailRecList" : designationDetailRecList,
            "tributeRecList" : tributeRecList,
            "pledgeRec": pledgeRec,
            "paymentRecWrapper": paymentRecWrapper,
            "installmentRecList": installmentRecList,
            "selectedPledgeRec": selectedPledgeRec,
            "stripeChargeId": stripeChargeId,
            "interimRecordId" : interimRecordId,
            "creditCardNumber" : thirdPartyPaymentData.creditCardNumber,
            "creditCardType" :  'Visa',
            "creditCardExpirationDate" : thirdPartyPaymentData.exprDate,
            "amountToPayToday" : amountToPayToday
        };
        
        var createGiftAsyncAction = component.get("c.SERVER_createNewOnlineDonation");
        createGiftAsyncAction.setParams({"params":params});
        createGiftAsyncAction.setCallback(this, function(response) {
            let busySpinner = document.getElementById("spinner");
            if (busySpinner != null) {
                busySpinner.className = "slds-hide";
            }
            var state = response.getState();
            var returnObject = response.getReturnValue();

            if (state === "SUCCESS") {
                // AI stuff
                let donatedDesignationIds = returnObject.donatedDesignationIds;
                if (donatedDesignationIds != null && donatedDesignationIds.length > 0) {
                    var recordActionRecommendationEngineProcessAction = component.get("c.SERVER_recordActionRecommendationEngineProcessAction");
                    recordActionRecommendationEngineProcessAction.setParams({"donatedDesignationIds":donatedDesignationIds});
                    recordActionRecommendationEngineProcessAction.setCallback(this, function(response) {
                        // Do nothing
                    });
                    $A.enqueueAction(recordActionRecommendationEngineProcessAction);
                }

                component.set("v.serverResult", returnObject);
                let paymentGroupId = returnObject.paymentGroupId;
                if (paymentGroupId) {
                    component.set("v.paymentGroupId", paymentGroupId);
                    component.set("v.showGiftReceipt", true);
                }
                component.set("v.currentStep", 'step5');
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
        $A.enqueueAction(createGiftAsyncAction);
    },

    showToastForRequiredLogin : function(component, event, helper) {

        let isAnonymousUser = component.get("v.isAnonymousUser");

        if (isAnonymousUser == true) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                mode: 'dismissible',
                duration: '1000',
                type: 'info',
                title: 'Please login.',
                message: 'You will have to login first.'
            });
            toastEvent.fire();
        }
    }
})