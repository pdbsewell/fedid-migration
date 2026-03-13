({
    validatePledgePaymentInfomationSync : function(component, event, helper) {
        let MessageHandlingService = component.find("MessageHandlingService");
        let paymentRecWrapper = component.get("v.paymentRecWrapper");

        if (paymentRecWrapper.ucinn_ascendv2__Payment_Amount__c  == null || paymentRecWrapper.ucinn_ascendv2__Payment_Amount__c <= 0) {
            MessageHandlingService.validationError("Please specify a positive payment amount.");
            return false;
        }
        return true;
    }
})