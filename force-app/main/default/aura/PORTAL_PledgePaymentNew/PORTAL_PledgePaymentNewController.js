({
    validatePledgePaymentInfomationSync : function(component, event, helper) {
        return helper.validatePledgePaymentInfomationSync(component, event, helper);
    },
    installmentRecListUpdated : function(component, event, helper) {

        var paymentRecWrapper = component.get("v.paymentRecWrapper");

        if (paymentRecWrapper != null && paymentRecWrapper.ucinn_ascendv2__Payment_Amount__c != null && paymentRecWrapper.ucinn_ascendv2__Payment_Amount__c > 0) {
            return;
        }
        var installmentRecList = component.get("v.installmentRecList");

        for (var oneInstallmentRec of installmentRecList) {
            if (oneInstallmentRec.ucinn_ascendv2__Expected_Less_Payment_Amount_Formula__c > 0) {
                paymentRecWrapper.ucinn_ascendv2__Payment_Amount__c = oneInstallmentRec.ucinn_ascendv2__Expected_Less_Payment_Amount_Formula__c;
                component.set("v.paymentRecWrapper", paymentRecWrapper);
                break;
            }
        }
    }
})