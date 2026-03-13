({
    validateCreditCardNumber : function(component, helper, creditCardNumber) {
        if (creditCardNumber == null || creditCardNumber == "") {
            return false;
        }
        else {
            var visaRegEx = /^(?:4[0-9]{12}(?:[0-9]{3})?)$/;
            var mastercardRegEx = /^(?:5[1-5][0-9]{14})$/;
            var amexpRegEx = /^(?:3[47][0-9]{13})$/;
            var discovRegEx = /^(?:6(?:011|5[0-9][0-9])[0-9]{12})$/;
            var isValid = false;

            if (visaRegEx.test(creditCardNumber)) {
                isValid = true;
            } else if(mastercardRegEx.test(creditCardNumber)) {
                isValid = true;
            } else if(amexpRegEx.test(creditCardNumber)) {
                isValid = true;
            } else if(discovRegEx.test(creditCardNumber)) {
                isValid = true;
            } else if (creditCardNumber == "4242424242424242") {
                isValid = true; // for testing
            }

            return isValid;
        }
    },

    validateExpirationDate : function(component, helper, exprDate) {
        if (exprDate == null || exprDate == "" || exprDate.length != 4) {
            return false;
        }
        else {
            var mmyyRegEx = /^(([0][1-9])|([1][0-2]))([1-9][0-9])$/;
            var isValid = false;

            if (mmyyRegEx.test(exprDate)) {
                isValid = true;
            }

            if (isValid) {
                var monthStr = exprDate.substring(0,2);
                var yearStr = exprDate.substring(2,4);
                var month = parseInt(monthStr);
                var year = parseInt(yearStr);
                
                let today = new Date();
                var currentYearLastTwoDigitsStr = today.getFullYear().toString().substring(2,4);
                var currentYearLastTwoDigits = parseInt(currentYearLastTwoDigitsStr);
                var currentMonthDigits = today.getMonth() + 1;

                if (year < currentYearLastTwoDigits) {
                    return false;
                }
                else if (year == currentYearLastTwoDigits) {
                    if (month < currentMonthDigits) {
                        return false;
                    }
                }
            }

            return isValid;
        }
    },

    validateCvv : function(component, helper, cvv) {
        if (cvv == null || cvv == "" || cvv.length < 3) {
            return false;
        }
        else {
            var cvvRegEx = /^\d+$/;
            var isValid = false;

            if (cvvRegEx.test(cvv)) {
                isValid = true;
            }

            return isValid;
        }
    }
})