({
    /**
     * On init, load donation amounts, designation lists, donor, recaptcha, and enable Donate button
     * 
     * @param component     The Donation Form component
     */
    onInit: function (component, event, helper) {
        helper.loadDonationAmounts(component, event);
        helper.loadDesignationList(component, event);
        helper.loadDonor(component, event);
        //helper.loadCountries(component, event);
        helper.loadSalutations(component, event);
        helper.loadErrorMessages(component, event);
        helper.enableSubmitButton(component, event);

        let frequencies = component.get("v.donationFrequencies");
        if(frequencies === "Once and Monthly") {
            component.set("v.donationFrequencyList", ['Once','Monthly']);
            component.set("v.selectedDonateFrequency", 'Once');
        } else if(frequencies === "Monthly and Once") {
            component.set("v.donationFrequencyList", ['Monthly','Once']);
            component.set("v.selectedDonateFrequency", 'Monthly');
        }
        else {
            component.set("v.donationFrequencyList", [frequencies]);
            component.set("v.selectedDonateFrequency", frequencies);
        }
        helper.loadDonationAmounts(component, event);

        let vfOrigin = location.protocol + '//' + location.hostname;
        window.addEventListener("message", function(event) {
            if (event.origin !== vfOrigin) {
                return;
            } 
            if (event.data.captchaVisible) {
                let captchEl = document.getElementById('iframeRecaptcha');
                if(event.data.captchaVisible === 'visible'){
                    captchEl.classList.add('recaptchaChallengeVisible');
                    captchEl.classList.remove('recaptchaChallengeHidden');
                } else {
                    captchEl.classList.remove('recaptchaChallengeVisible');
                    captchEl.classList.add('recaptchaChallengeHidden');
                }
            }
            if (event.data.validity==="VALID" || component.get("v.showCaptcha")==false){
                component.set("v.isSecurityChallengePassed", true)
                component.set("v.captchaResponseKey", event.data.captchaResponseKey);
            }        
        }, false);
        
    },

    /**
     * On handle capture the Event from the reCaptcha LWC comp
     * 
     * @param component     The Donation Form component
     */
    handleDispatchCaptchaEvent: function (component, event, helper) {
        let token = event.getParam('token');
        let bypasstoken = event.getParam('bypasstoken');
        let disabledBtn = event.getParam('disabled');
		component.set("v.rateLimitKey", event.getParam('rateLimitKey'));
        if(token){
            component.set("v.isSecurityChallengePassed", true);
            component.set("v.captchaResponseKey", token); 
            component.set("v.captchaBypassToken", bypasstoken);
        }else if(bypasstoken){
			component.set("v.isSecurityChallengePassed", true);
            component.set("v.captchaBypassToken", bypasstoken);
        }
    },
    
    /**
     * On render, load current user data into the Contact form section
     * 
     * @param component     The Donation Form component
     */
    onRender: function (component, event, helper) {
        
        var constituentRec = component.get("v.constituentRec");
        var isContactInfoLoaded = component.get("v.isContactInfoLoaded");
        var isGtmViewInvoked = component.get("v.isGtmViewInvoked");
        
        if (!isGtmViewInvoked) {
            helper.handleDonationFormView(component);
            component.set("v.isGtmViewInvoked", true)
        }
        if (constituentRec != null && !isContactInfoLoaded) {
            if (constituentRec.FirstName !== undefined) {
                document.getElementById("tbxFirstname").value = constituentRec.FirstName;
            }
            if (constituentRec.LastName !== undefined) {
                document.getElementById("tbxLastname").value = constituentRec.LastName;
            }
            if (constituentRec.Email !== undefined) {
                component.set("v.contactEmail", constituentRec.Email);
            }
            if (constituentRec.Phone !== undefined) {
                component.set("v.contactPhone", constituentRec.Phone);
            }
            component.set("v.isContactInfoLoaded", true);
        }
    },
    
    /**
     * Set selected donation frequency attribute when the selected frequency changes
     * 
     * @param component     The Donation Form component
     */
    onSelectDonationFrequency: function (component, event, helper) {
        var selectedFrequency = event.target.value;
        if (selectedFrequency != null) {
            component.set("v.selectedDonateFrequency", selectedFrequency);
            helper.loadDonationAmounts(component, event);
            
            //Clear textbox value when using selection
            document.getElementById("tbxOtherDonationAmount").value = "";
            
            helper.handleFieldCompletion(component, "Frequency", "Frequency", "String", selectedFrequency.toString(), "1");
        }
    },
    
    /**
     * Set selected donation amount attribute when the selected amount changes
     * 
     * @param component     The Donation Form component
     */
    onSelectDonationAmount: function (component, event, helper) {
        var selectedAmount = event.target.value;
        if (!isNaN(selectedAmount)) {
            component.set("v.selectedDonateAmount", selectedAmount);
            
            //Clear textbox value when using selection
            document.getElementById("tbxOtherDonationAmount").value = "";
            
            helper.handleFieldCompletion(component, "Amount", "Amount", "Currency", selectedAmount.toString(), "1");
        }
    },
    
    /**
     * Set selected donation designation attribute when the selected designation changes
     * 
     * @param component     The Donation Form component
     */
    onSelectDesignation: function (component, event, helper) {
        var selectedDesignation = event.target.value;
        var selectedDesignationId = event.target.id;
        var selectedDesignationLabel = "";
        if (selectedDesignation != null) {
            
            var selectedDesignationLabelObj = event.target.nextSibling;
            while (selectedDesignationLabelObj.nodeName !== "LABEL") {
                selectedDesignationLabelObj = selectedDesignationLabelObj.nextSibling;
            }
            
            if (selectedDesignationLabelObj) {
                selectedDesignationLabel = selectedDesignationLabelObj.innerHTML;
            }
            
            component.set("v.selectedDesignation", selectedDesignation);
            component.set("v.selectedDesignationLabel", selectedDesignationLabel);
            if(selectedDesignationId != null) {
                component.set("v.selectedDesignationId", selectedDesignationId);
            }
            component.set("v.isOtherDesignationSelected", false);
            //Clear textbox value when using selection
            document.getElementById("tbxOtherDesignation").value = "";
            
            helper.handleFieldCompletion(component, "Designation", "Designation", "String", selectedDesignationLabel, "2");
        }
    },
    
    /**
     * Set selected donation amount attribute when the other donation amount is inputed
     * 
     * @param component     The Donation Form component
     */
    onEnterDonationAmount: function (component, event, helper) {
        var selectedAmount = document.getElementById("tbxOtherDonationAmount").value.replaceAll('$', '');
        component.set("v.selectedDonateAmount", selectedAmount);
        helper.handleFieldCompletion(component, "Amount", "Amount", "Currency", selectedAmount.toString(), "1");
        
    },
    
    /**
     * Set selected donation designation attribute when the other designation is inputed
     * 
     * @param component     The Donation Form component
     */
    onEnterDesignation: function (component, event, helper) {
        var selectedDesignation = document.getElementById("tbxOtherDesignation").value;
        if (selectedDesignation != "") {
            component.set("v.selectedDesignation", selectedDesignation);
            component.set("v.selectedDesignationId", component.get("v.defaultDesignationSFId"));
            component.set("v.selectedDesignationLabel", selectedDesignation);
            component.set("v.isOtherDesignationSelected", true);
            //Set radio to Other
            document.getElementById("rbAogOther").checked = true;
            
            helper.handleFieldCompletion(component, "Designation", "Designation", "String", selectedDesignation.toString(), "2");
        }
    },
    
    /**
     * On Donate button clicked
     * 
     * @param component     The Donation Form component
     */
    onSubmitDonation: function (component, event, helper) {
        helper.disableSubmitButton(component, event);
        helper.handleSubmitDonation(component, event, helper);
    },
    
    /**
     * On Field completed
     * 
     * @param component     The Donation Form component
     */
    onCompleteField: function (component, event, helper) {
        var cmpField = event.target.getAttribute("data-componentName");
        var salutation = document.getElementById("ddlSalutation").options[document.getElementById("ddlSalutation").selectedIndex].value;
        var firstname = document.getElementById("tbxFirstname").value;
        var lastname = document.getElementById("tbxLastname").value;
        var cardholdername = document.getElementById("tbxCardholderName").value;
        var cardnumber = document.getElementById("tbxCardNumber").value;
        var cardexpiredate = document.getElementById("tbxCardExpireDate").value;
        var cardsecuritycode = document.getElementById("tbxCardSecurityCode").value;
        var cardtype = document.getElementById("ddlCardType").value;
        
        if (cmpField == "cmpSalutation") {
            helper.handleFieldCompletion(component, "Salutation", "Salutation", "String", salutation, "3");
        } else if (cmpField == "cmpFirstname") {
            helper.handleFieldCompletion(component, "Firstname", "Firstname", "String", (firstname.length > 0) ? "Text entered" : "", "3");
        } else if (cmpField == "cmpLastname") {
            helper.handleFieldCompletion(component, "Lastname", "Lastname", "String", (lastname.length > 0) ? "Text entered" : "", "3");
        }
        else if (cmpField == "cmpCardHolderName") {
            if(cardholdername !== ''){
                if(!helper.validateCardholdername(component, event, cardholdername)){
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Credit card name is invalid"
                    });
                }                
            }
            helper.handleFieldCompletion(component, "CardHolderName", "Card Holder Name", "String", (cardholdername.length > 0) ? "Text entered" : "", "4");
        } else if (cmpField == "cmpCardNumber") {
            if(cardnumber !== '' && cardtype !== ''){
                if(!helper.validateCreditCardNumber(component, event, cardnumber, cardtype)){
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Credit card number is invalid"
                    });
                }
            }
            helper.handleFieldCompletion(component, "CardNumber", "Card Number", "String", (cardnumber.length > 0) ? "Text entered" : "", "4");
        } else if (cmpField == "cmpCardType") {
            if(cardtype !== ''){
                // If Card number is populated then validate it
                if(cardnumber !== ''){
                    if(!helper.validateCreditCardNumber(component, event, cardnumber, cardtype)){
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Error",
                            "message": "Credit card number is invalid"
                        });
                    }
                }     
                // If CVV is populated then validate it
                if(cardsecuritycode !== ''){
                    if(!helper.validateCvv(component, event, cardsecuritycode, cardtype)){
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Error",
                            "message": "Credit card verification value is invalid"
                        });
                    }
                }           
            }
            helper.handleFieldCompletion(component, "CardType", "Card Type", "String", cardtype, "4");
        } else if (cmpField == "cmpCardExpiry") {
            if(cardexpiredate !== ''){
                if(!helper.validateExpirationDate(component, event, cardexpiredate, cardtype)){
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Credit card expiration date is invalid"
                    });
                }                
            }
            helper.handleFieldCompletion(component, "CardExpiryDate", "Card Expiry Date", "String", (cardexpiredate.length > 0) ? "Text entered" : "", "4");
        } else if (cmpField == "cmpCardSecurityCode") {
            if(cardsecuritycode !== '' && cardtype !== ''){
                if(!helper.validateCvv(component, event, cardsecuritycode, cardtype)){
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Credit card verification value is invalid"
                    });
                }
            }
            helper.handleFieldCompletion(component, "CardSecurityCode", "Card Security Code", "String", (cardsecuritycode.length > 0) ? "Text entered" : "", "4");
        }
	}
})