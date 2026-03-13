({
    doInit : function(component, event, helper) {
        var thirdPartyPaymentData = component.get("v.thirdPartyPaymentData");
        if (thirdPartyPaymentData == null) {
            thirdPartyPaymentData = {};
        }
        thirdPartyPaymentData.provider = "stripeAPI";
        component.set("v.thirdPartyPaymentData", thirdPartyPaymentData);
    },

    validateCreditCardInfomationSync : function(component, event, helper) {
        let thirdPartyPaymentData = component.get("v.thirdPartyPaymentData");

        var isValid = true;
        
        if (helper.validateCreditCardNumber(component, helper, thirdPartyPaymentData.creditCardNumber) == false) {
            var stripeCreditCardField = component.find("stripeCreditCardFieldId");
            stripeCreditCardField.set("v.errors", null);
            stripeCreditCardField.set("v.errors", [{message:"Credit Credit Number is invalid."}]);
            isValid = false;
        }
        if (helper.validateExpirationDate(component, helper, thirdPartyPaymentData.exprDate.replace('/', '')) == false) {
            var stripeExpirationDateField = component.find("stripeExpirationDateFieldId");
            stripeExpirationDateField.set("v.errors", null);
            stripeExpirationDateField.set("v.errors", [{message:"Expiration Date is invalid."}]);
            isValid = false;
        }
        if (helper.validateCvv(component, helper, thirdPartyPaymentData.cvv) == false) {
            var stripeCcvField = component.find("stripeCcvFieldId");
            stripeCcvField.set("v.errors", null);
            stripeCcvField.set("v.errors", [{message:"Card Verification Value is invalid."}]);
            isValid = false;
        }

        return isValid;

    },

    creditCardNumberChanged : function(component, event, helper) {
        let stripeCreditCardField = component.find("stripeCreditCardFieldId");
        var ccNumStr = component.get("v.thirdPartyPaymentData").creditCardNumberStr;
        var ccNumStr_nospace_nodash = ccNumStr || "";
        ccNumStr_nospace_nodash = ccNumStr_nospace_nodash.replace(/\s/g, '');
        ccNumStr_nospace_nodash = ccNumStr_nospace_nodash.replace(/-/g, '');

        stripeCreditCardField.set("v.errors", null);

        if (helper.validateCreditCardNumber(component, helper, ccNumStr_nospace_nodash) == false) {
            // Show error to field
            if (ccNumStr == null || ccNumStr == "") {
                stripeCreditCardField.set("v.errors", [{message:"Credit Credit Number is requried."}]);
            }
            else {
                stripeCreditCardField.set("v.errors", [{message:"Credit Credit Number is invalid."}]);
            }
        }
        else {
            component.set("v.thirdPartyPaymentData.creditCardNumber", ccNumStr_nospace_nodash);
        }
    },

    expirationDateChanged : function(component, event, helper) {
        let stripeExpirationDateField = component.find("stripeExpirationDateFieldId");
        var exprDateStr = component.get("v.thirdPartyPaymentData").exprDateStr;
        stripeExpirationDateField.set("v.errors", null);

        if (exprDateStr && exprDateStr.substring(2,3) != "/") {
            stripeExpirationDateField.set("v.errors", [{message:"Expiration Date is invalid."}]);
        }
        var exprDateStr_noslash = exprDateStr || "";
        exprDateStr_noslash = exprDateStr_noslash.replace('/', '');

        if (helper.validateExpirationDate(component, helper, exprDateStr_noslash) == false) {
            // Show error to field
            if (exprDateStr == null || exprDateStr == "") {
                stripeExpirationDateField.set("v.errors", [{message:"Expiration Date is requried."}]);
            }
            else {
                stripeExpirationDateField.set("v.errors", [{message:"Expiration Date is invalid."}]);
            }
        }
        else {
            component.set("v.thirdPartyPaymentData.exprDate", exprDateStr);
        }
    },

    cvvChanged : function(component, event, helper) {
        let stripeCcvField = component.find("stripeCcvFieldId");
        var cvvStr = component.get("v.thirdPartyPaymentData").cvvStr;

        stripeCcvField.set("v.errors", null);

        if (helper.validateCvv(component, helper, cvvStr) == false) {
            if (cvvStr == null || cvvStr == "") {
                stripeCcvField.set("v.errors", [{message:"Card Verification Value is requried."}]);
            }
            else {
                stripeCcvField.set("v.errors", [{message:"Card Verification Value is invalid."}]);
            }
        }
        else {
            component.set("v.thirdPartyPaymentData.cvv", cvvStr);
        }
    }
})