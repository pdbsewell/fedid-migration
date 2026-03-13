({
    doInit : function(component, event, helper) {
        let giftTypeSelected = component.get("v.giftTypeSelected");
        if (giftTypeSelected == "Pledge") {
            helper.initializePledgeRec(component, event, helper);
        }
        else if (giftTypeSelected == "OutrightGift") {
            helper.initializeGiftRec(component, event, helper);
        }
    },

    paymentDayOfMonthOptionChange : function(component, event, helper) {
        var portalDonationSetupParams = component.get("v.portalDonationSetupParams");
        var selectedPaymentDayOfMonth = component.find("availableMonthOptions").get("v.value");
        portalDonationSetupParams.selectedPaymentDayOfMonth = selectedPaymentDayOfMonth;
        component.set("v.portalDonationSetupParams", portalDonationSetupParams);
    },

    paymentFrequencyChange : function(component, event, helper) {
        var portalDonationSetupParams = component.get("v.portalDonationSetupParams");
        var selectedPaymentFrequency = component.find("availableFrequencyOptions").get("v.value");
        portalDonationSetupParams.selectedPaymentFrequency = selectedPaymentFrequency;
        component.set("v.portalDonationSetupParams", portalDonationSetupParams);
    }
})