({
    /**
     * Load selectable designations
     * 
     * @param component     The Donation Form component
     */
    loadDesignationList: function (component, event) {
        var action = component.get("c.getSelectableDesignations");
        let designationExtIdList = component.get("v.selectableDesignationIds");
        let defaultDesignationExtId = component.get("v.defaultDesignationId");
        let isExtIdListHasDefault = true;
        if(!designationExtIdList.includes(defaultDesignationExtId)) {
            designationExtIdList += ',';
            designationExtIdList += defaultDesignationExtId;
            isExtIdListHasDefault = false;
        }
        action.setParams({
            designationIdsCommaSeparated : designationExtIdList
        });
        action.setCallback(this, function(a) {
            var state = a.getState();

            if(state ==="SUCCESS") {
                let designationList = a.getReturnValue();
                let spliceIndex = -1;
                for(let i = 0; i < designationList.length; i++) {
                    if(designationList[i].ucinn_ascendv2__External_System_ID__c == defaultDesignationExtId) {
                        component.set("v.defaultDesignationSFId", designationList[i].Id);
                        spliceIndex = i;
                    }
                }
                if(!isExtIdListHasDefault) {
                    designationList.splice(spliceIndex, 1);
                }
                component.set("v.designationList", designationList);
                
            } 
            else if (state === "INCOMPLETE") {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": "Incomplete error."
                });
            }
            else if (state === "ERROR") {
                let error = response.getError();
                if (error && error[0] && error[0].message) {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": error[0].message
                    });
                }
                else {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Error."
                    });
                }
                component.set("v.loaded", true);
            }
        });
        $A.enqueueAction(action);
        component.set("v.loaded", false);
    },
    
    /**
     * Load selectable donation amounts
     * 
     * @param component     The Donation Form component
     */
    loadDonationAmounts: function (component, event) {
        var selectableDonateOnceAmounts = component.get("v.selectableDonateOnceAmounts");
        var selectableDonateMonthlyAmounts = component.get("v.selectableDonateMonthlyAmounts");
        var selectedDonateFrequency = component.get("v.selectedDonateFrequency");
        var selectedDonateAmount = component.get("v.selectedDonateAmount");
        var amounts = [];
        var amountstring = [];
        
        if (selectedDonateFrequency == "Monthly") {
            amountstring = selectableDonateMonthlyAmounts.split("|");
        } else {
            amountstring = selectableDonateOnceAmounts.split("|");
        }
        
        for (let i = 0; i < amountstring.length; i++) {
            if (amountstring[i] != "" && !isNaN(amountstring[i])) {
                amounts.push(amountstring[i]);
            }
        }
        
        component.set("v.donationAmountList", amounts);
        
        // Pre-select the amount
        if (amounts.length > 1) {
            component.set("v.selectedDonateAmount", amounts[1]);
        } else if (amounts.length > 0) {
        component.set("v.selectedDonateAmount", amounts[0]); 
        }
    },
    
    /**
     * Load current user, constituent, and organization
     * 
     * @param component     The Donation Form component
     */
    loadDonor: function (component, event) {
        let findDonorRecAction = component.get("c.getDonorByLoggedInUser");
        findDonorRecAction.setCallback(this, function(response) {
            var returnObject = response.getReturnValue();
            var state = response.getState();

            if(state ==="SUCCESS") {
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
                    component.set("v.organizationRec", returnObject.organizationRec);
                    component.set("v.isAnonymousUser", false);
                    component.set("v.giftTypeSelected", 'OutrightGift');

                    component.set("v.contactEmail", returnObject.constituentRec.Email);
                    component.set("v.contactPhone", returnObject.constituentRec.Phone);
                    component.set("v.emailVerification", returnObject.constituentRec.Emails__r[0].Verification_Status__c);
                    component.set("v.phoneVerification", returnObject.constituentRec.Phones__r[0].Verification_Status__c);
                    component.set("v.phoneSavedCountry", returnObject.constituentRec.Phones__r[0].ISO_Country__c);
                    component.set("v.addressLine", returnObject.constituentRec.Addresses__r[0].Address__c);

                }
                else {
                    component.set("v.isAnonymousUser", true);
                    component.set("v.giftTypeSelected", 'OutrightGift');
                }
                component.set("v.readyForLoading", true);
            } 
            else if (state === "INCOMPLETE") {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": "Incomplete error."
                });
            }
            else if (state === "ERROR") {
                let error = response.getError();
                if (error && error[0] && error[0].message) {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": error[0].message
                    });
                }
                else {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Error."
                    });
                }
            }
            component.set("v.loaded", true);
        });
        $A.enqueueAction(findDonorRecAction);
        component.set("v.loaded", false);
    },
    
    /**
     * Load country selection
     * 
     * @param component     The Donation Form component
     */
    loadCountries: function(component, event) {
        var action = component.get("c.getCountryOptions");
        action.setCallback(this, function(response) {
            var returnObject = response.getReturnValue();
            var state = response.getState();

            if(state ==="SUCCESS") {
                component.set("v.countryOptionList", returnObject);
            } 
            else if (state === "INCOMPLETE") {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": "Incomplete error."
                });
            }
            else if (state === "ERROR") {
                let error = response.getError();
                if (error && error[0] && error[0].message) {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": error[0].message
                    });
                }
                else {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Error."
                    });
                }
            }
            component.set("v.loaded", true);
        });
        $A.enqueueAction(action);
        component.set("v.loaded", false);
    },

    /**
 * Load salutation selection
 * 
 * @param component     The Donation Form component
 */
    loadSalutations: function(component, event) {
    var action = component.get("c.getSalutationsOptions");
    action.setCallback(this, function(response) {
        var returnObject = response.getReturnValue();
        var state = response.getState();

        if(state ==="SUCCESS") {
            component.set("v.salutationList", returnObject);
        } 
        else if (state === "INCOMPLETE") {
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Error",
                "message": "Incomplete error."
            });
        }
        else if (state === "ERROR") {
            let error = response.getError();
            if (error && error[0] && error[0].message) {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": error[0].message
                });
            }
            else {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": "Error."
                });
            }
        }
        component.set("v.loaded", true);
    });
    $A.enqueueAction(action);
    component.set("v.loaded", false);
},
    
    /**
 * Load error message text
 * 
 * @param component     The Donation Form component
 */
    loadErrorMessages: function(component, event) {
    var action = component.get("c.getErrorMessages");
    action.setCallback(this, function(response) {
        var returnObject = response.getReturnValue();
        var state = response.getState();
        if(state ==="SUCCESS") {
            let errorMessageMap = response.getReturnValue();
            
            component.set("v.errorMessageMap", errorMessageMap);                
        } 
        else if (state === "INCOMPLETE") {
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Error",
                "message": "Incomplete error."
            });
        }
        else if (state === "ERROR") {
            let error = response.getError();
            if (error && error[0] && error[0].message) {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": error[0].message
                });
            }
            else {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": "Error."
                });
            }
        }
        component.set("v.loaded", true);
    });
    $A.enqueueAction(action);
    component.set("v.loaded", false);
},
    
    /**
     * Enable Donate button
     * 
     * @param component     The Donation Form component
     */
    enableSubmitButton: function (component, event) {
        var btn = component.find("btnSubmit");
        var submitButtonLabel = component.get("v.submitButtonLabel");
        
        if (btn != null) {
            component.set("v.btnSubmitDisabled", false);
            component.set("v.btnSubmitLabel", submitButtonLabel);
        }
    },
    
    /**
     * Disable Donate button
     * 
     * @param component     The Donation Form component
     */
    disableSubmitButton: function (component, event) {
        var btn = component.find("btnSubmit");
        if (btn != null) {
            component.set("v.btnSubmitDisabled", true);
            component.set("v.btnSubmitLabel", "Processing...");
        }
    },
    
    /**
     * Validate credit card number
     * 
     * @param component            The Donation Form component
     * @param creditCardNumber     The Credit Card Number
     */
    validateCreditCardNumber: function (component, event, creditCardNumber, cardtype) {
        if (creditCardNumber == null || creditCardNumber == "") {
            return false;
        }
        else {
            let cardNumbertrimmed = creditCardNumber.trim();
            if(creditCardNumber.includes(" ")){
                cardNumbertrimmed = creditCardNumber.replace(" ", "");
            }
            var visaRegEx = /^(?:4[0-9]{15}|4[0-9]{12})$/;
            var mastercardRegEx = /^(?:5[1-5][0-9]{14})$/;
            var mastercardRegEx2 = /^(?:2221[0-9]{12})$/;
            var mastercardRegEx3 = /^(?:2720[0-9]{12})$/;
            var amexpRegEx = /^(?:3[47][0-9]{13})$/;
            var isValid = false;

            if(cardtype === 'Mastercard'){
                if (cardNumbertrimmed.length == 16 && 
                    (mastercardRegEx.test(cardNumbertrimmed) || mastercardRegEx2.test(cardNumbertrimmed) || mastercardRegEx3.test(cardNumbertrimmed))){
                    isValid = true;
                }
            }else if(cardtype === 'VISA'){
                if((cardNumbertrimmed.length == 16 || cardNumbertrimmed.length == 13) && visaRegEx.test(cardNumbertrimmed)){
                    isValid = true;
                }                
            }else if(cardtype === 'American Express'){
                if(cardNumbertrimmed.length == 15 && amexpRegEx.test(cardNumbertrimmed)){
                    isValid = true;
                }
            } else if (cardNumbertrimmed == "4242424242424242") {
                isValid = true; // for testing
            }
            return isValid;
        }
    },

    /**
     * Validate credit card expiration date
     * 
     * @param component            The Donation Form component
     * @param exprDate             The Credit Card Expiration Date
     */
    validateExpirationDate: function (component, event, exprDate) {
        if (exprDate == null || exprDate == "" || exprDate == undefined || exprDate.length != 5 || !exprDate.includes("/") || exprDate.indexOf("/") !== 2) {
            return false;
        }
        else {
            
            let monthYearStr  = exprDate.split('/');
            let monthStr = monthYearStr[0];
            let yearStr = monthYearStr[1];
            let month, year ;
            // Cater to the format MM/YY
            var mmyyRegEx = /^(0[1-9]|1[0-2])\/([0-9]{2})$/; 
            var isValid = false;

            if (mmyyRegEx.test(exprDate)) {
                isValid = true;
            }
            if (isValid) {
                month = parseInt(monthStr);
                year = parseInt(yearStr);
                if(month < 1 || month > 12){
                    return false;
                }
                
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

    /**
     * Validate credit card ccv
     * 
     * @param component            The Donation Form component
     * @param cvv                  The Credit Card CVV number
     */
    validateCvv: function(component, event, cvv, cardtype) {
        if (cvv === null || cvv === '') {
            return false;
        }else if(((cardtype === 'Mastercard' || cardtype === 'VISA') && cvv.length == 3) || (cardtype === 'American Express' && cvv.length == 4)){
            var cvvRegEx = /^\d+$/;
            var isValid = false;
            if (cvvRegEx.test(cvv)) {
                isValid = true;
            }

            return isValid;   
        }
        return false;
    },
    
    validateCardholdername: function(component, event, cardholdername) {
        
        var cardholdernameRegex = /^[a-zA-Z \-]*$/;
        if(cardholdername == null || cardholdername == "" || cardholdername.length < 2 || cardholdername.length > 26) {
            return false;
        }
        else if(cardholdernameRegex.test(cardholdername)){
            return true;
        }
        return false;
    },
    
    /**
     * Update iframe Google Tag Manager - Data Layer push
     * 
     * @param component            The Donation Form component
     * @param fieldid              The Field API Name
     * @param fieldname            The Field Label
     * @param fieldtype            The Field Type
     * @param fieldvalue           The Field Value
     * @param stepnumber           The Step Number
     */
    handleFieldCompletion: function (component, fieldid, fieldname, fieldtype, fieldvalue, stepnumber) {
        var stepname = "";
        var tagParams_fieldcompleted = [];
        var seconds = new Date().getTime() / 1000;
        var titleObj = document.getElementById("ucin-headline-title");
        var groupname = "";
        if (titleObj) {
            groupname = titleObj.innerHTML;
        }
        
        if (stepnumber == "1") {
            stepname = "Donation Type/Amount";
        } else if (stepnumber == "2") {
            stepname = "Area of giving";
        } else if (stepnumber == "3") {
            stepname = "My contact details";
        } else if (stepnumber == "4") {
            stepname = "My Payment information";
        }
        
        if (fieldtype == "Currency") {
            fieldvalue = parseFloat(fieldvalue).toFixed(2).toString();
        }
        
        window.postMessage({
            "event": "custom.ecommerce.field.complete",
            "group": groupname,
            "label": fieldname,
            "step": {
                "sequence": stepnumber,
                "label": stepname
            },
            "info": {
                "id": fieldid,
                "type": fieldtype
            },
            "data": {
                "value": fieldvalue
            }
        }, location.origin);
    },
    
    /**
     * Update iframe Google Tag Manager - Data Layer push
     * 
     * @param component            The Donation Form component
     */
    handleDonationFormView: function (component) {
        var stepnumber = "1";
        var stepname = "Form visible to the user";
        var titleObj = document.getElementById("ucin-headline-title");
        var groupname = "";
        if (titleObj) {
            groupname = titleObj.innerHTML;
        }
        
        window.postMessage({
            "event" : "custom.ecommerce.checkout.view",
            "group" : groupname,
            "step" : {
                "sequence" : stepnumber,
                "label" : stepname,
                "variation" : undefined
            },
            "data" : undefined,
            "ecommerceType" : "checkout",
            "ecommerce" : {
                "currencyCode" : "AUD",
                "checkout" : {
                    "actionField" : {
                        "step" : stepnumber,
                        "option" : undefined
                    },
                    "products" : undefined //products: undefined on the first 3 steps.
                }
            }
        }, location.origin);
    },

    throwError : function(component, errorMessage) {
        component.find('notifLib').showNotice({
            "variant": "error",
            "header": "Error",
            "message": errorMessage
        });
    },

    experianEmailValidate : function(component) {
        let personalEmailComp = component.find("personalEmailValidate");
        return personalEmailComp.getEmailValidationResultAsync();
    },

    experianPhoneValidate : function(component) {
        let mobilePhoneComp = component.find("mobileNumberSearch");
        return mobilePhoneComp.getPhoneNumberValidationResultAsync();
    },

    experianAddressValidate : function(component) {
        let addressSearchComp = component.find("addressSearchComp");
        return addressSearchComp.getAddress();
    },

    validateFormEntries: function (component, event, helper){
        var errorMessages = [];
        var isDonationInputCompleted = false;
        var isContactInputCompleted = false;
        var isPaymentInputCompleted = false;
        var isCreditCardInputValid = false;
        var isSecurityChallengePassed = component.get("v.isSecurityChallengePassed");
        var isOtherDesignation = component.get("v.isOtherDesignationSelected");
        var selectedDonateFrequency = component.get("v.selectedDonateFrequency");
        var selectedDonateAmount = component.get("v.selectedDonateAmount");
        var selectedDesignation = component.get("v.selectedDesignation");
        var selectedDesignationId = component.get("v.selectedDesignationId");
        var selectedDesignationLabel = component.get("v.selectedDesignationLabel");
        var defaultDesignation = component.get("v.defaultDesignationId");
        var defaultAppeal = component.get("v.defaultAppealCode");
        var isAnonymousDonation = document.getElementById("cbAnonymousDonation").checked;
        var isLearnMoreWill = document.getElementById("cbLearnMoreWill").checked;
        var isWillReady = document.getElementById("cbWillReady").checked;
        var donationComments = document.getElementById("tbxDonationComments").value;
        var firstname = document.getElementById("tbxFirstname").value;
        var lastname = document.getElementById("tbxLastname").value;

        var salutation = "";
        if (document.getElementById("ddlSalutation").options[document.getElementById("ddlSalutation").selectedIndex] != undefined) {
            salutation = document.getElementById("ddlSalutation").options[document.getElementById("ddlSalutation").selectedIndex].value;
        }
        var cardtype = "";
        if (document.getElementById("ddlCardType").options[document.getElementById("ddlCardType").selectedIndex] != undefined) {
            cardtype = document.getElementById("ddlCardType").options[document.getElementById("ddlCardType").selectedIndex].value;
        }

        var phone = component.get("v.phoneNumber");
        var email = component.get("v.emailAddress");
        var addressLine = component.get("v.addressLine");
        var manualAddressValidity = component.get("v.manualAddressValidity");
        var emailVerification = component.get("v.emailVerificationStatus");
        var phoneVerification = component.get("v.phoneVerificationStatus");
        var address1 = component.get("v.address1");
        var city = component.get("v.city");
        var state = component.get("v.state");
        var postalcode = component.get("v.postalcode");
        var country = component.get("v.country");
        var addressverification = component.get("v.addressverification");
        var dpid = component.get("v.dpid");

        var cardholdername = document.getElementById("tbxCardholderName").value;
        var cardnumber = document.getElementById("tbxCardNumber").value;
        var cardexpiredate = document.getElementById("tbxCardExpireDate").value;
        var cardsecuritycode = document.getElementById("tbxCardSecurityCode").value;

        var paymentChargeId = component.get("v.paymentChargeId");
        var captchaResponseKey = component.get("v.captchaResponseKey");
        var captchaBypassToken = component.get("v.captchaBypassToken");
        var rateLimitKey = component.get("v.rateLimitKey");
        var isAnonymousUser = component.get("v.isAnonymousUser");
        var giftTypeSelected = component.get("v.giftTypeSelected");
        var constituentRec = component.get("v.constituentRec");
        var organizationRec = component.get("v.organizationRec");
        let regex = /^[\d]*\.?[0-9]{1,2}$/;
        var titleObj = document.getElementById("ucin-headline-title");
        var groupname = "";
        if (titleObj) {
            groupname = titleObj.innerHTML;
        }

        window.postMessage({
            "event" : "custom.ecommerce.checkout.submit",
            "group" : groupname,
            "label" : "Donate",
            "step" : {
                "sequence" : 4,
                "label" : "My Payment information"
            },
            "data" : undefined
        }, location.origin);

        //Validate Donation inputs
        if ( $A.util.isEmpty(selectedDesignation) ) {
            errorMessages.push("Please select an area of giving");
        }
        if ( (isNaN(selectedDonateAmount)) ) {
            errorMessages.push("Please select or enter an appropriate Donation Amount");
        } else if (!regex.test(selectedDonateAmount)) {
            errorMessages.push("Please enter a valid donation amount");
        }
        if ( $A.util.isEmpty(salutation) ) {
            errorMessages.push("Please enter your salutation");
        }
        if ( $A.util.isEmpty(firstname) ) {
            errorMessages.push("Please enter contact first name");
        }
        if ( $A.util.isEmpty(lastname) ) {
            errorMessages.push("Please enter contact last name");
        }
        if ( $A.util.isEmpty(email) ) {
            errorMessages.push("Please enter a valid contact email");
        }
        if ( $A.util.isEmpty(phone) ) {
            errorMessages.push("Please enter a valid phone number");
        }
        // Validate address
        if ( $A.util.isEmpty(addressLine) || manualAddressValidity === 'invalid'){
            errorMessages.push("Please fill out the address fields correctly");
        }
        // Validate Credit Card information
        if ( $A.util.isEmpty(cardholdername) ) {
            errorMessages.push("Please enter credit cardholder name");
        }else if (!this.validateCardholdername(component, event, cardholdername)) {
            errorMessages.push("Credit card name is invalid");
        }
        if ( $A.util.isEmpty(cardnumber) ) {
            errorMessages.push("Please enter credit card number");
        } else if (!this.validateCreditCardNumber(component, event, cardnumber, cardtype)) {
            errorMessages.push("Credit card number is invalid");
        }
        if ( $A.util.isEmpty(cardtype) ) {
            errorMessages.push("Please select credit card type");
        }
        if ( $A.util.isEmpty(cardexpiredate)  ) {
            errorMessages.push("Please enter credit card expiry date");
        }else if (!this.validateExpirationDate(component, event, cardexpiredate, cardtype)) {
            errorMessages.push("Credit card expiration date is invalid");
        }
        if ( $A.util.isEmpty(cardsecuritycode) ) {
            errorMessages.push("Please enter credit card security code");
        } else if (!this.validateCvv(component, event, cardsecuritycode, cardtype)) {
            errorMessages.push("Credit card verification value is invalid");
        }
        if (!isSecurityChallengePassed) {
            errorMessages.push("Please complete the security challenge");
        }
        
        if (errorMessages.length == 0) {
            let today = new Date();
            let contactDetails = [];
            contactDetails.push('Salutation: ' + salutation);
            contactDetails.push('First Name: ' + firstname);
            contactDetails.push('Last Name: ' + lastname);
            contactDetails.push('Phone: ' + phone);
            contactDetails.push('Email: ' + email);
            contactDetails.push('Address Line 1: ' + address1);
            contactDetails.push('City: ' + city);
            contactDetails.push('State: ' + state);
            contactDetails.push('Postal Code: ' + postalcode);
            contactDetails.push('Country: ' + country);

            var giftRec = {
                'Id': null,
                'Amount': selectedDonateAmount,
                'Type': (selectedDonateFrequency == "Monthly") ? 'Recurring' : 'Outright',
                'ucinn_ascendv2__Credit_Date__c': today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate(),
                'ucinn_ascendv2__Notes__c': donationComments,
                'ucinn_ascendv2__Entry_Date__c': today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate(),
                'ucinn_ascendv2__Is_Anonymous__c' : isAnonymousDonation,
                'Learn_About_Will__c' : isLearnMoreWill,
                'Gifted_in_Will__c' : isWillReady,
                'Beyond_Today_Contact_Details__c' : contactDetails.join('<br\/>')
            };

            var designationDetailRecList = [];

            // Create copy record to remove address/phone/email information
            var cleanConstituentRec = null;
            if(constituentRec){
                cleanConstituentRec = Object.assign({},constituentRec);
            }

            if(cleanConstituentRec) {
                if (cleanConstituentRec.Addresses__r[0] !== null) {
                    delete cleanConstituentRec.Addresses__r;
                }
                if (cleanConstituentRec.Phones__r[0] !== null) {
                    delete cleanConstituentRec.Phones__r;
                }
                if (cleanConstituentRec.Emails__r[0] !== null) {
                    delete cleanConstituentRec.Emails__r;
                }
            }          

            if (cleanConstituentRec != null) {
                designationDetailRecList.push({
                    'Id': null,
                    'ucinn_ascendv2__Designation__c': selectedDesignationId,
                    'ucinn_ascendv2__Amount__c': selectedDonateAmount,
                    'ucinn_ascendv2__Payment_Frequency__c': (selectedDonateFrequency == "Monthly") ? 'Monthly' : 'One Time',
                    'ucinn_ascendv2__Number_of_Payments__c': '1',
                    'ucinn_ascendv2__Contact__c': cleanConstituentRec.Id,
                    'ucinn_ascendv2__Non_Gift_Amount__c': 0
                });
            }

            var params = {
                "isAnonymousUser" : isAnonymousUser,
                "isOtherDesignation" : isOtherDesignation,
                "giftTypeSelected" : giftTypeSelected,
                "constituentRec" : cleanConstituentRec,
                "organizationRec" : organizationRec,
                "giftRec" : giftRec,
                "designationDetailRecList" : designationDetailRecList,
                "designationName" : selectedDesignation,
                "designationLabel" : selectedDesignationLabel,
                "defaultDesignation" : defaultDesignation,
                "defaultAppeal" : defaultAppeal,
                "paymentChargeId": paymentChargeId,
                "creditCardNumber" : cardnumber.trim(),
                "creditCardType" :  cardtype,
                "creditCardExpirationDate" : cardexpiredate,
                "cardsecuritycode" : cardsecuritycode,
                "amountToPayToday" : selectedDonateAmount,
                "contact_salutation" : salutation,
                "contact_firstname" : firstname,
                "contact_lastname" : lastname,
                "contact_phone" : phone,
                "contact_email" : email,
                "contact_address1" : address1,
                "contact_city" : city,
                "contact_state" : state,
                "contact_postalcode" : postalcode,
                "contact_country" : country,
                "donationFrequency" : selectedDonateFrequency,
                "pageName" : window.location.href.split("/").pop(),
                "captchaResponseKey" : captchaResponseKey,
                "captchaBypassToken" : captchaBypassToken,
                "rateLimitKey" : rateLimitKey,
                // experian attributes
                "address_verification" : addressverification,
                "address_dpid" : dpid,
                "email_verification" : emailVerification,
                "phone_verification" : phoneVerification
            };
            this.performCallout(component, event, helper, params);
        } else {
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Error",
                "message": errorMessages.join("\n")
            });
            this.enableSubmitButton(component, event);
        }
    },


    /**
     * Create donation/gift, create receipt and email it to current user
     * 
     * @param component     The Donation Form component
     */
    handleSubmitDonation: function (component, event, helper) {
        var constituentRec = component.get("v.constituentRec");

        //  Start - Experian Email and Phone Validation
        helper.experianEmailValidate(component, event, helper)
            .then(result => {
                if(result){
                    console.log('Email Validation Result: ' + JSON.stringify(result));
                    component.set("v.emailAddress", result.email);
                    component.set("v.emailVerificationStatus", result.confidence);

                        // Validate Phone
                        helper.experianPhoneValidate(component, event, helper)
                            .then(result => {
                                if(result){
                                    console.log('MobilePhone Validation Result: ' + JSON.stringify(result));
                                    if(result.unicrm_formatted_phone_number !== ''){
                                        component.set("v.phoneNumber", result.unicrm_formatted_phone_number);
                                    }else{
                                        component.set("v.phoneNumber", result.formatted_phone_number);
                                    }
                                    component.set("v.phoneVerificationStatus", result.confidence);

                                    // set old address
                                    console.log('constituentRec: ' + JSON.stringify(constituentRec));
                                    if(constituentRec){
                                        if(constituentRec.Addresses__r[0].Address__c !== null){
                                            component.set("v.addressLine", constituentRec.Addresses__r[0].Address__c);
                                            component.set("v.address1", constituentRec.Addresses__r[0].Street_Name__c);
                                            component.set("v.city", constituentRec.Addresses__r[0].City__c);
                                            component.set("v.state", constituentRec.Addresses__r[0].State__c);
                                            component.set("v.country", constituentRec.Addresses__r[0].Country2__c);
                                            component.set("v.postalcode", constituentRec.Addresses__r[0].Post_Code__c);
                                            component.set("v.dpid", constituentRec.Addresses__r[0].DPID__c);
                                            component.set("v.addressverification", constituentRec.Addresses__r[0].Verification_Status__c);
                                        }
                                    }

                                    // validate address
                                    let experianAddress = helper.experianAddressValidate(component, event, helper);
                                    console.log('Address Validation Result: ' + JSON.stringify(experianAddress));
                                    if(experianAddress.splitRecord.address_line_full !== ''){
                                        if(experianAddress.splitRecord.address_line_full){
                                            component.set("v.dpid", experianAddress.dpId);
                                            component.set("v.addressverification", experianAddress.confidence);

                                            let summedUpAddress;
                                            if(experianAddress.confidence){
                                                summedUpAddress = experianAddress.splitRecord.address_line_full;
                                            }else{
                                                summedUpAddress = experianAddress.splitRecord.address_line_1;
                                            }

                                            component.set("v.address1", summedUpAddress.trim());
                                            component.set("v.city", experianAddress.splitRecord.locality);
                                            component.set("v.state", experianAddress.splitRecord.region);
                                            component.set("v.country", experianAddress.splitRecord.country);
                                            component.set("v.postalcode", experianAddress.splitRecord.postal_code);

                                            let addressLine;
                                            if(summedUpAddress.trim()){
                                                addressLine = summedUpAddress.trim();
                                            }
                                            if(experianAddress.splitRecord.locality){
                                                addressLine += ', ' + experianAddress.splitRecord.locality;
                                            }
                                            if(experianAddress.splitRecord.region){
                                                addressLine += ', ' + experianAddress.splitRecord.region;
                                            }
                                            if(experianAddress.splitRecord.postal_code){
                                                addressLine += ', ' + experianAddress.splitRecord.postal_code;
                                            }
                                            if(experianAddress.splitRecord.country){
                                                addressLine += ', ' + experianAddress.splitRecord.country;
                                            }
                                            component.set("v.addressLine", addressLine);
                                        }
                                    }
                                    component.set("v.manualAddressValidity", experianAddress.manualAddressValidity);

                                    helper.validateFormEntries(component,event,helper);
                                }
                                else{
                                    helper.validateFormEntries(component,event,helper);
                                    this.enableSubmitButton(component, event);
                                }
                            }).catch(error => {
                            console.error(error);
                        });
                }else{
                    helper.validateFormEntries(component,event,helper);
                    this.enableSubmitButton(component, event);
                }
            }).catch(error => {
            console.error(error);
        });
    },


    /**
     * Perform callout to cybersource external payment gateway.
     * 
     * @param params        parameter list needed to create the request to cybersource on ascend's backend.
     */
    performCallout : function (component, event, helper, params) {
        if ( params.giftRec.Type == 'Outright') {
            this.processOutrightPayment (component, event, helper, params);
        } 
        else {
            this.processPayment (component, event, helper, params);
        }
    },
    /**
     * Perform callout to cybersource external payment gateway.
     * 
     * @param params        parameter list needed to create the request to cybersource on ascend's backend.
     */
     processOutrightPayment : function (component, event, helper, params) {
        var SERVER_createTransaction = component.get("c.createTransaction");
        SERVER_createTransaction.setParams({"donationFormParams":params});
        component.set("v.showCaptcha", false);
        SERVER_createTransaction.setCallback(this, function(response){
            var state = response.getState();
            var returnObject = response.getReturnValue();
            if (state === "SUCCESS") {
                if (returnObject != undefined) {
                    params.transactionId = returnObject.transactionId;
                    params.encryptedKey = returnObject.encryptedKey;
                    params.externalPaymentGatewayId = returnObject.externalPaymentGatewayId;
                    delete params.captchaResponseKey;
                    delete params.captchaBypassToken;
                    this.processPayment(component,event,helper,params);
                } else {
                    // Display processing error
                    helper.showToast(component, false, 'Cybersource: Failed');
                    this.enableSubmitButton(component, event);
                    component.set("v.loaded", true);
                }
            } else {
                // display callout error
                var errors = response.getError(); 
                if(errors && errors[0].message){
                    helper.showToast(component, false, errors[0].message); 
                }else{
                    helper.showToast(component, false, "Unable to process your transaction"); 
                }
                this.enableSubmitButton(component, event);
                component.set("v.loaded", true);
            }
        });
        $A.enqueueAction(SERVER_createTransaction);
        component.set("v.loaded", false);
        // Reset the Captcha
        component.set("v.showCaptcha", true); 
		component.set("v.isSecurityChallengePassed", false);
    },

    processPayment : function (component, event, helper, params) {
        component.set("v.showCaptcha", false);
        var SERVER_processPayment = component.get("c.processPayment");
        SERVER_processPayment.setParams({"donationFormParams":params});
        SERVER_processPayment.setCallback(this, function(response){
            var state = response.getState();
            var returnObject = response.getReturnValue();
            if (state === "SUCCESS") {
                if (returnObject.giftReceiptId != undefined) {
                    params.giftReceiptId = returnObject.giftReceiptId;
                    params.paymentGroupId = returnObject.paymentGroupId;
                    this.displayGiftReceipt(component, event, helper, params);
                } else if (returnObject.message != undefined) {
                    // Display message
                    helper.showToast(component, false, returnObject.message);
                    this.enableSubmitButton(component, event);
                    component.set("v.loaded", true);
                } else {
                    // Display processing error 
                    helper.showToast(component, false, 'Cybersource: Failed');
                    this.enableSubmitButton(component, event);
                    component.set("v.loaded", true);
                }
            } else {
                // display callout error
                var errors = response.getError(); 
                if(errors && errors[0].message){
                    helper.showToast(component, false, errors[0].message); 
                }else{
                    helper.showToast(component, false, "Unable to process your donation"); 
                } 
                helper.showToast(component, false, errors[0].message); 
                this.enableSubmitButton(component, event);
                component.set("v.loaded", true);
            }
        });
        $A.enqueueAction(SERVER_processPayment );
        component.set("v.loaded", false);
        // Reset the Captcha
        component.set("v.showCaptcha", true);
		component.set("v.isSecurityChallengePassed", false);
    },

    displayGiftReceipt : function (component, event, helper, params) {
        var titleObj = document.getElementById("ucin-headline-title");
        var groupname = "";
        if (titleObj) {
            groupname = titleObj.innerHTML;
        }

        window.postMessage({
            "event" : "custom.ecommerce.donate",
            "group" : groupname,
            "label" : "Successful Donation",
            "data" : {
                "value" : parseFloat(params["amountToPayToday"]),
                "paymentMethod" : params["creditCardType"]
            },
            "ecommerceType" : "donation",
            "ecommerce" : {
                "currencyCode" : "AUD",
                "purchase" : {
                    "actionField" : {
                        "id" : params["giftReceiptId"],
                        "revenue" : parseFloat(params["amountToPayToday"]),
                        "tax" : 0 //please include this even if it is always 0
                    },
                    "products": [{
                        "id" : params["designationName"], //Selected Area of giving
                        "name" : params["designationLabel"], //Selected Area of giving
                        "price" : parseFloat(params["amountToPayToday"]),
                        "category" : "donation",
                        "quantity" : 1,
                        "variant" : (params["donationFrequency"] == "monthly") ? "Donate Monthly" : "Donate Once" //"Donate Once" or "Donate Monthly"
                    }]
                }
            }
        }, location.origin);
        component.find('notifLib').showToast({
            "variant":"success",
            "title": "Thank You",
            "message": "Thank you for your donation.",
            "mode": "sticky"
        });

        $A.get("e.force:refreshView").fire();
    },

    /**
     * Show Error Toast
     * 
     * @param component     The Donation Form component
     * @param isSuccess     True if success, false if not
     * @param Message       Message to display
     */
    showToast: function (component, isSuccess, Message) {
        if (isSuccess) {
            component.find('notifLib').showToast({
                "variant":"success",
                "title": "Thank You",
                "message": Message,
                "mode": "sticky"
            });
        } else {
            component.find('notifLib').showToast({
                "variant":"error",
                "title": "Error",
                "message": Message,
                "mode": "sticky"
            }); 
        }
    },
    
    /**
     * Show Error Toast
     * 
     * @param component     The Donation Form component
     * @param isSuccess     True if success, false if not
     * @param Message       Message to display
     */
    isNullCheck: function (component, variable) {
        if (variable === null || variable === '' || variable === undefined) {
            return true;
        }else{
            return false;
        }
    }
})