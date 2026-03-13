({
    doInit : function(component, event, helper) {
        let constituentId = component.get("v.constituentId");
        let organizationId = component.get("v.organizationId");
        let MessageHandlingService = component.find("MessageHandlingService");
        
        var action = component.get('c.getBaseUrl')
        action.setCallback(this, function (response) {
            var state = response.getState()
            
            console.log('state: ' + state);
            
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue()
            
            	console.log('baseUrl: ' + result);

            	component.set('v.baseUrl', result)

            }
        })
        $A.enqueueAction(action)        

        if ($A.util.isEmpty(constituentId) == false) {
            let findDonorRecAction = component.get("c.SERVER_getDonorById");
            let params = {
                "constituentId" : constituentId
            };
            findDonorRecAction.setParams({"params":params});
            findDonorRecAction.setCallback(this, function(response) {
                var returnObject = response.getReturnValue();
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.constituentRec", returnObject.constituentRec);
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
                if (busySpinner != null) {
                    busySpinner.className = "slds-hide";
                }
            });
            $A.enqueueAction(findDonorRecAction);
            component.set("v.isAnonymousUser", false);
        }
        // else if ($A.util.isEmpty(organizationId) == false) {
        //     component.set("v.isAnonymousUser", false);
        // }
        else {

            let findDonorRecAction = component.get("c.SERVER_getDonorByLoggedInUser");
            let params = {
            };
            findDonorRecAction.setParams({"params":params});
            findDonorRecAction.setCallback(this, function(response) {
                var returnObject = response.getReturnValue();
                var state = response.getState();
                if (state === "SUCCESS") {

                    if (returnObject.currentUser && returnObject.currentUser.Id) {
                        let currentUser = returnObject.currentUser;
                        let recommendType1 = currentUser.Recommend_Type_1__c;
                        let recommendType2 = currentUser.Recommend_Type_2__c;
                        let recommendType3 = currentUser.Recommend_Type_3__c;

                        var portalUserRecommendationParam = {};
                        portalUserRecommendationParam.recommendType1 = recommendType1;
                        portalUserRecommendationParam.recommendType2 = recommendType2;
                        portalUserRecommendationParam.recommendType3 = recommendType3;
                        component.set("v.portalUserRecommendationParam", portalUserRecommendationParam);
                    }

                    if (returnObject.constituentRec) {
                        component.set("v.constituentRec", returnObject.constituentRec);
                        component.set("v.constituentId", returnObject.constituentRec.Id);
                        component.set("v.isAnonymousUser", false);
                    }
                    else {
                        component.set("v.isAnonymousUser", true);
                        component.set("v.giftTypeSelected", 'OutrightGift');
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
                if (busySpinner != null) {
                    busySpinner.className = "slds-hide";
                }
            });
            $A.enqueueAction(findDonorRecAction);
        }
    },

    clearAndGoBack : function(component, event, helper) {
        let currentStep = component.get("v.currentStep");
        let isAnonymousUser = component.get("v.isAnonymousUser");

        if (currentStep == "step2") {
            component.set("v.selectedPledgeRec", null);
            component.set("v.currentStep", "step1");
        }
        else if (currentStep == "step3") {
            component.set("v.currentStep", "step2");
        }
        else if (currentStep == "step4") {
            if (isAnonymousUser == true) {
                component.set("v.currentStep", "step3");
            }
            else {
                component.set("v.currentStep", "step2");
            }
        }
    },

    validateAndGoNextStep : function(component, event, helper) {
        var currentStep = component.get("v.currentStep");
        var validated = true;
        var giftTypeSelected = component.get("v.giftTypeSelected");
        var nextStep = "";

        if (currentStep == "step1") {
            if (giftTypeSelected == 'OutrightGift' || giftTypeSelected == 'Pledge') {
                let step1_DesignationSelectionCmp = component.find("step1_DesignationSelectionCmpId");
                validated = step1_DesignationSelectionCmp.validateDesignationsSelectionInfomationSync();
            }
            else if (giftTypeSelected == 'PledgePayment') {
                let step1_PledgeSelectionCmp = component.find("step1_PledgeSelectionCmpId");
                validated = step1_PledgeSelectionCmp.validatePledgeSelectionInfomationSync();
            }

            if (validated == false) {
                return;
            }

            nextStep = "step2";
        }
        else if (currentStep == "step2") {

            let isAnonymousUser = component.get("v.isAnonymousUser");
            if (isAnonymousUser == true) {
                nextStep = "step3";
            }
            else {
                nextStep = "step4";
            }
            
            if (giftTypeSelected == 'OutrightGift') {
                let step2_GiftNewCmp = component.find("step2_GiftNewCmpId");
                validated = step2_GiftNewCmp.validateGiftInfomationSync();
            }
            else if (giftTypeSelected == 'Pledge') {
                let step2_PledgeNewCmp = component.find("step2_PledgeNewCmpId");
                var callbackOnLongValidation = function(validated) {

                    if (validated == false) {
                        return;
                    }
                    else {
                        if (isAnonymousUser == true) {
                            component.set("v.currentStep", 'step3');
                        }
                        else {
                            component.set("v.currentStep", 'step4');
                        }
                    }
                }
                step2_PledgeNewCmp.validatePledgeInfomationAsync(callbackOnLongValidation);
                return;
            }
            else if (giftTypeSelected == 'PledgePayment') {
                let step2_PledgePaymentNewCmp = component.find("step2_PledgePaymentNewCmpId");
                validated = step2_PledgePaymentNewCmp.validatePledgePaymentInfomationSync();
            }

            if (validated == false) {
                return;
            }
        }
        else if (currentStep == "step3") {
            // nextStep = "step4";
            let step3_interimNewCmp = component.find("step3_interimNewCmpId");
            step3_interimNewCmp.submitFormSync();
            return;
        }
        else if (currentStep == "step4") {
            let step4_hirdPartyPaymentCmp_Stripe = component.find("step4_hirdPartyPaymentCmp_Stripe_id");
            validated = step4_hirdPartyPaymentCmp_Stripe.validateCreditCardInfomationSync();
            if (validated == false) {
                return;
            }

            var previousButton = component.find("donationPreviousBtnId");

            if (previousButton != undefined) {
                previousButton.set("v.disabled", true);
            }

            let stripeChargeId = 'test123456';
            helper.SERVER_createNewOnlineDonation(component, helper, stripeChargeId);

            // let giftTypeSelected = component.get("v.giftTypeSelected");

            // if (giftTypeSelected == 'OutrightGift') {
            //     helper.createGiftAsync(component, helper, stripeChargeId);
            // }
            // else if (giftTypeSelected == 'Pledge') {
            //     helper.createPledgeAsync(component, helper, stripeChargeId);
            // }
            // else if (giftTypeSelected == 'PledgePayment') {
            //     helper.createPledgePaymentAsync(component, helper, stripeChargeId);
            // }
            return;
        }

        if ($A.util.isEmpty(nextStep) == false) {
            component.set("v.currentStep", nextStep);
        }
    },

    cancelAndClear : function(component, event, helper) {
        component.set("v.giftTypeSelected", undefined);
        component.set("v.currentStep", "step1");

        helper.initializeAttributes(component, helper);
    },

    goHome : function(component, event, helper) {
        component.set("v.giftTypeSelected", undefined);
        component.set("v.currentStep", "step1");

        helper.initializeAttributes(component, helper);
    },

    giftTypeSelected : function(component, event, helper) {
        let giftTypeSelected = event.target.id;
        let isAnonymousUser = component.get("v.isAnonymousUser");
        if (isAnonymousUser == true && (giftTypeSelected == "Pledge" || giftTypeSelected == "PledgePayment")) {
            helper.showToastForRequiredLogin(component, event, helper);
            return;
        }
        component.set("v.giftTypeSelected", giftTypeSelected);
    },

    giftTypeChanged : function(component, event, helper) {
        let oldValue = event.getParam("oldValue");
        let newValue = event.getParam("value");

        if (oldValue != newValue) {
            if (oldValue == 'PledgePayment') {
                component.set("v.selectedPledgeRec", null);
                component.set("v.paymentRecWrapper", null);
                component.set("v.installmentRecList", null);
            }
            else if (newValue == 'PledgePayment') {
                component.set("v.portalDonationSetupParams", null);
                component.set("v.availableDesignations", null);
                component.set("v.selectedDesignations", null);
                component.set("v.installmentRecList", null);
                component.set("v.tributeRecList", null);
                component.set("v.giftRec", null);
                component.set("v.pledgeRec", null);
            }
            else if (oldValue == 'Pledge') {
                component.set("v.pledgeRec", null);
                component.set("v.installmentRecList", null);
            }
            else if (oldValue == 'OutrightGift') {
                component.set("v.giftRec", null);
            }
        }
    },

    updateAmountToPayToday : function(component, event, helper) {
        let giftTypeSelected = component.get("v.giftTypeSelected");

        if (giftTypeSelected == 'OutrightGift') {
            let giftRec = component.get("v.giftRec");
            component.set("v.amountToPayToday", giftRec.Amount);
        }
        else if (giftTypeSelected == 'Pledge') {
            let installmentRecList = component.get("v.installmentRecList");

            if (installmentRecList != null && installmentRecList.length > 0) {
                // Here assuming first record of installment list has the earliest expected date. Otherwise, provide sorting method and sort it before following statements
                var firstInstallmentRec = installmentRecList[0];
                
                let today = new Date();
                let dateTodayLocalTimezoneStr = today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate() + " GMT";
                let todayDateOnly = Date.parse(dateTodayLocalTimezoneStr);

                var amountToPayToday = 0.00;

                for (let installmentRec of installmentRecList) {
                    if (Date.parse(installmentRec.ucinn_ascendv2__Expected_Date__c) == todayDateOnly) {
                        amountToPayToday += installmentRec.ucinn_ascendv2__Amount__c;
                    }
                }
                component.set("v.amountToPayToday", amountToPayToday);
            }
        }
        else if (giftTypeSelected == 'PledgePayment') {
            let paymentRecWrapper = component.get("v.paymentRecWrapper");
            if (paymentRecWrapper != null) {
                component.set("v.amountToPayToday", paymentRecWrapper.ucinn_ascendv2__Payment_Amount__c);
            }
        }
    },

    interimRecordIdChanged : function(component, event, helper) {
        let interimRecordId = component.get("v.interimRecordId");
        let isAnonymousUser = component.get("v.isAnonymousUser");

        if (isAnonymousUser == true && $A.util.isEmpty(interimRecordId) == false) {
            // anonymous user data saved
            component.set("v.currentStep", "step4");
        }
    },

    goGiftReceipt : function(component, event, helper) {
        var lightningHostUrl = window.location.hostname;
        var paymentGroupId = component.get("v.paymentGroupId");
        
        var baseUrl = component.get("v.baseUrl");

        var receiptUrl = baseUrl + "/PORTAL_STRIPE_ReceiptPage?paymentGroupId="+paymentGroupId;

        window.open(receiptUrl,"_blank");
    }
})