({
    doInit : function(component, event, helper) {
        let paymentRecWrapper = component.get("v.paymentRecWrapper");

        if (paymentRecWrapper == null) {
            var today = new Date();
            paymentRecWrapper = {
                                    'Id': null,
                                    'Name': '',
                                    'ucinn_ascendv2__Payment_Amount__c': 0.00
                                };

            component.set("v.paymentRecWrapper", paymentRecWrapper);
        }
    },

    setPaymentToTriggerAmountUpdate : function(component, event, helper) {
        let paymentRecWrapper = component.get("v.paymentRecWrapper");
        component.set("v.paymentRecWrapper", paymentRecWrapper);
    }
})