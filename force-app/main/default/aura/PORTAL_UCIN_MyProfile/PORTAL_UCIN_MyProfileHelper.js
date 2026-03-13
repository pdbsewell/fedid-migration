({
    /**
     * Resets the styling on all tabs so a new tab can be selected.
     *
     * @param component     The MyProfile component
     * @param helper        This MyProfileHelper class
     */
    clearTabs : function(component, helper) {
        component.set("v.showBioDetails", false);
        component.set("v.showProfInfo", false);
        component.set("v.showContactInfo", false);
        component.set("v.showCommsPref", false);
        component.set("v.showYourDegrees", false);

        var showBioDetails = component.find("showBioDetails");
        helper.switchTab(showBioDetails, false);

        var showProfInfo = component.find("showProfInfo");
        helper.switchTab(showProfInfo, false);

        var showContactInfo = component.find("showContactInfo");
        helper.switchTab(showContactInfo, false);

        var showCommsPref = component.find("showCommsPref");
        helper.switchTab(showCommsPref, false);

        var showYourDegrees = component.find("showYourDegrees");
        helper.switchTab(showYourDegrees, false);

    },

    /**
     * Sets the styling for the chosen tab based on whether it is selected.
     *
     * @param  thisComponent        The tab to be updated
     * @param {Boolean} selected    Whether to make the tab appear clicked or not
     */
    switchTab : function(thisComponent, selected) {
        if (selected) {
            $A.util.addClass(thisComponent, 'bg-gray');
            $A.util.addClass(thisComponent, 'text-blue');
            $A.util.addClass(thisComponent, 'border-t-4');
            $A.util.addClass(thisComponent, 'font-medium');
            $A.util.addClass(thisComponent, 'border-blue');
            $A.util.addClass(thisComponent, 'bg-gray-mon');
            $A.util.removeClass(thisComponent, 'border-b-4');
            $A.util.removeClass(thisComponent, 'border-dark-grey');
        } else {
            $A.util.removeClass(thisComponent, 'bg-gray');
            $A.util.removeClass(thisComponent, 'text-blue');
            $A.util.removeClass(thisComponent, 'border-t-4');
            $A.util.removeClass(thisComponent, 'font-medium');
            $A.util.removeClass(thisComponent, 'border-blue');
            $A.util.removeClass(thisComponent, 'bg-gray-mon');
            $A.util.addClass(thisComponent, 'border-b-4');
            $A.util.addClass(thisComponent, 'border-dark-grey');
        }
    },

    /**
     * Retrieves Contact information for display on the page.
     *
     * @param component The MyProfile component
     */
    loadContactDetails : function(component, event) {
        let action = component.get('c.SERVER_getUserInfo');
        action.setCallback(this, function(response){
            var state = response.getState();

            if(state ==="SUCCESS") {
                let result = response.getReturnValue();
                if(response.getReturnValue()) {
                    let areasList = [];
                    response.getReturnValue().interestAreas.forEach(function(area) {
                        if(response.getReturnValue().interestAreas && response.getReturnValue().contact.Volunteer_Areas_of_Interest__c != undefined
                            && response.getReturnValue().contact.Volunteer_Areas_of_Interest__c.includes(area)) {
                            areasList.push({'label': area, 'filled': true});
                        } else {
                            areasList.push({'label': area, 'filled': false});
                        }
                    });
                    component.set('v.interestAreaTracker', areasList);
                }

                // Capture the Gender Label
                if(result.genderValueLabel){
                    component.set('v.genderLabel', result.genderValueLabel);
                }

                // Convert Date Achieved to degree year for each degree
                if (result.contact.Contact_Qualifications__r != undefined && result.contact.Contact_Qualifications__r.length > 0) {
                    for (var eachDegree of result.contact.Contact_Qualifications__r) {
                        var dt = new Date(eachDegree.Date_Achieved__c);
                        eachDegree.degreeYear = dt.getFullYear();
                    }
                }

                // Split skills & expertise and areas of interest into arrays
                if (result.contact.Volunteer_Areas_of_Interest__c != undefined) {
                    var array = [];
                    array = result.contact.Volunteer_Areas_of_Interest__c.split(';');
                    result.AOIArray = array;
                }
                if (result.contact.Volunteer_Skills__c != undefined) {
                    var array = [];
                    array = result.contact.Volunteer_Skills__c.split(';');
                    result.SkillsArray = array;
                }

                component.set("v.contactMap", result);
                component.set("v.contactMapOrig", JSON.parse(JSON.stringify(result)));

                this.storeOriginalContactEmail(component, result);
                this.setAddressLine(component, result);

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

    throwError : function(component, errorMessage) {
        component.find('notifLib').showNotice({
            "variant": "error",
            "header": "Error",
            "message": errorMessage
        });
    },

    storeOriginalContactEmail : function(component, result){
        component.set('v.oldEmailValue', result.emailMap.Personal.Name);
        if(result.emailMap.Business){
            component.set('v.oldBusinessEmailValue', result.emailMap.Business.Name);
        }
    },

    setAddressLine : function(component, result){
        let addressLine = '';
        if(result.prefAddress.Street_Name__c || result.prefAddress.Street_Name__c != undefined){
            addressLine = result.prefAddress.Street_Name__c + ', ';
        }
        if(result.prefAddress.City__c  || result.prefAddress.City__c != undefined){
            addressLine += result.prefAddress.City__c + ', ';
        }
        if(result.prefAddress.State__c || result.prefAddress.State__c != undefined){
            addressLine += result.prefAddress.State__c + ', ';
        }
        if(result.prefAddress.Post_Code__c || result.prefAddress.Post_Code__c != undefined){
            addressLine += result.prefAddress.Post_Code__c + ', ';
        }
        if(result.prefAddress.Country2__c || result.prefAddress.Country2__c != undefined){
            addressLine += result.prefAddress.Country2__c;
        }
        component.set("v.addressLine", addressLine);
        component.set("v.origAddressLine", addressLine);
    },

    updateAddress : function(component, updatedAddress){
        let summedUpAddress;
        if(updatedAddress.confidence){
            summedUpAddress = updatedAddress.splitRecord.address_line_full;
        }else{
            summedUpAddress = updatedAddress.splitRecord.address_line_1;
        }

        component.set("v.contactMap.prefAddress.Street_Name__c", summedUpAddress.trim());
        component.set("v.contactMap.prefAddress.City__c", updatedAddress.splitRecord.locality);
        component.set("v.contactMap.prefAddress.State__c", updatedAddress.splitRecord.region);
        component.set("v.contactMap.prefAddress.Country2__c", updatedAddress.splitRecord.country);
        component.set("v.contactMap.prefAddress.Post_Code__c", updatedAddress.splitRecord.postal_code);

        let addressLine;
        if(summedUpAddress.trim()){
            addressLine = summedUpAddress.trim();
        }
        if(updatedAddress.splitRecord.locality){
            addressLine += ', ' + updatedAddress.splitRecord.locality;
        }
        if(updatedAddress.splitRecord.region){
            addressLine += ', ' + updatedAddress.splitRecord.region;
        }
        if(updatedAddress.splitRecord.postal_code){
            addressLine += ', ' + updatedAddress.splitRecord.postal_code;
        }
        if(updatedAddress.splitRecord.country){
            addressLine += ', ' + updatedAddress.splitRecord.country;
        }
        component.set("v.addressLine", addressLine);
    },

    experianAddressValidate: function(component, event, helper){
        let profileUpdate = component.find("desktopMyProfileContactInfo") ? component.find("desktopMyProfileContactInfo") : component.find("mobileMyProfileContactInfo");
        let addressSearchComp = profileUpdate.find("addressSearchComp");
        let updatedAddress = addressSearchComp.getAddress();

        if(updatedAddress.splitRecord.address_line_full !== ''){
            if(updatedAddress.splitRecord.address_line_full){
                this.updateAddress(component, updatedAddress);
                component.set("v.contactMap.prefAddress.DPID__c", updatedAddress.dpId);
                component.set("v.contactMap.prefAddress.Verification_Status__c", updatedAddress.confidence);
            }
        }
        component.set("v.manualAddressValidity", updatedAddress.manualAddressValidity);
    },

    experianPersonalEmailValidate : function(component) {
        let profileUpdate = component.find("desktopMyProfileContactInfo") ? component.find("desktopMyProfileContactInfo") : component.find("mobileMyProfileContactInfo");
        let personalEmailComp = profileUpdate.find("personalEmailValidate");
        console.log('EMAIL: ' + personalEmailComp.savedEmail);



        return personalEmailComp.getEmailValidationResultAsync();
    },

    experianBusinessEmailValidate : function(component) {
        let profileUpdate = component.find("desktopMyProfileContactInfo") ? component.find("desktopMyProfileContactInfo") : component.find("mobileMyProfileContactInfo");
        let businessEmailComp = profileUpdate.find("businessEmailValidate");
        return businessEmailComp.getEmailValidationResultAsync();
    },

    experianMobileValidate : function(component) {
        let profileUpdate = component.find("desktopMyProfileContactInfo") ? component.find("desktopMyProfileContactInfo") : component.find("mobileMyProfileContactInfo");
        let mobilePhoneComp = profileUpdate.find("mobileNumberSearch");
        return mobilePhoneComp.getPhoneNumberValidationResultAsync();
    },

    experianHomePhoneValidate : function(component) {
        let profileUpdate = component.find("desktopMyProfileContactInfo") ? component.find("desktopMyProfileContactInfo") : component.find("mobileMyProfileContactInfo");
        let homePhoneComp = profileUpdate.find("homeNumberSearch");
        return homePhoneComp.getPhoneNumberValidationResultAsync();
    },

    experianWorkPhoneValidate : function(component) {
        let profileUpdate = component.find("desktopMyProfileContactInfo") ? component.find("desktopMyProfileContactInfo") : component.find("mobileMyProfileContactInfo");
        let workPhoneComp = profileUpdate.find("workNumberSearch");
        return workPhoneComp.getPhoneNumberValidationResultAsync();
    },

    validateMobilePhone : function(component, event, helper){
        helper.experianMobileValidate(component, event, helper)
            .then(result => {
                if(result){
                    console.log('MobilePhone: ' + JSON.stringify(result));
                    if(!result.confidence && result.entered_phone_number){
                        helper.throwError(component,'A Phone number with correct format is required.')
                    }else{
                        if(result.unicrm_formatted_phone_number !== ''){
                            component.set("v.contactMap.phoneMap.Mobile.Name", result.unicrm_formatted_phone_number);
                        }else{
                            component.set("v.contactMap.phoneMap.Mobile.Name", result.formatted_phone_number);
                        }
                        component.set("v.contactMap.phoneMap.Mobile.Verification_Status__c", result.confidence);

                        // validate Home Phone
                        helper.validateHomePhone(component, event, helper);
                    }
                }
            }).catch(error => {
            console.error(error);
        });
    },

    validateHomePhone : function(component, event, helper){
        helper.experianHomePhoneValidate(component, event, helper)
            .then(result => {
                if(result){
                    console.log('HomePhone: ' + JSON.stringify(result));
                    if(!result.confidence && result.entered_phone_number){
                        helper.throwError(component,'A Phone number with correct format is required.')
                    }else{
                        if(result.unicrm_formatted_phone_number !== ''){
                            component.set("v.contactMap.phoneMap.Home.Name", result.unicrm_formatted_phone_number);
                        }else{
                            component.set("v.contactMap.phoneMap.Home.Name", result.formatted_phone_number);
                        }
                        component.set("v.contactMap.phoneMap.Home.Verification_Status__c", result.confidence);

                        // validate Home Phone
                        helper.validateWorkPhone(component, event, helper);
                    }
                }
            }).catch(error => {
            console.error(error);
        });
    },

    validateWorkPhone : function(component, event, helper){
        helper.experianWorkPhoneValidate(component, event, helper)
            .then(result => {
                if(result){
                    console.log('WorkPhone: ' + JSON.stringify(result));
                    if(!result.confidence && result.entered_phone_number){
                        helper.throwError(component,'A Phone number with correct format is required.')
                    }else{
                        if(result.unicrm_formatted_phone_number !== ''){
                            component.set("v.contactMap.phoneMap.Work.Name", result.unicrm_formatted_phone_number);
                        }else{
                            component.set("v.contactMap.phoneMap.Work.Name", result.formatted_phone_number);
                        }
                        component.set("v.contactMap.phoneMap.Work.Verification_Status__c", result.confidence);

                        // validate personal email change
                        helper.validateEmailChange(component, event, helper);
                    }
                }
            }).catch(error => {
            console.error(error);
        });
    },

    validateEmailChange : function(component, event, helper) {
        let emailChangeMessages = 'Please note\n'+
            'You have made a change to your personal email address.\n'+
            'This will also update the Username (email) that you use to log in to this site.\n'+
            'You will receive an email with a verification link sent to your new email address.\n'+
            'You MUST open this email and click the link for this email address to be confirmed.';

        let personalEmailExists = Boolean(component.get("v.contactMap.emailMap.Personal.Name"));
        let personalEmailOldValue = component.get('v.oldEmailValue');
        let personalEmailNewValue = component.get('v.contactMap.emailMap.Personal.Name');
        if((personalEmailOldValue != personalEmailNewValue) && personalEmailExists){
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Info",
                "message": emailChangeMessages,
                closeCallback: function(){
                    helper.inputValidation(component, event, helper);
                }
            });
        } else{
            this.inputValidation(component, event, helper);
        }
    },

    inputValidation : function(component, event, helper) {
        //  Start - Experian Address Validation
            this.experianAddressValidate(component);
        //  End - Experian Address Validation

        let manualAddressValidity = component.get("v.manualAddressValidity");
        let typeExists = Boolean(component.get("v.contactMap.prefAddress.Classification__c"));
        let businessCountryExists = Boolean(component.get("v.contactMap.businessAddress.Country2__c"));
        let businessStreetExists = Boolean(component.get("v.contactMap.businessAddress.Street_Name__c"));
        let streetExists = Boolean(component.get("v.contactMap.prefAddress.Street_Name__c"));
        let businessCityExists = Boolean(component.get("v.contactMap.businessAddress.City__c"));

        let mobilePhoneExists = Boolean(component.get("v.contactMap.phoneMap.Mobile.Name"));
        let homePhoneExists = Boolean(component.get("v.contactMap.phoneMap.Home.Name"));
        let workPhoneExists = Boolean(component.get("v.contactMap.phoneMap.Work.Name"));

        let prefAddress = component.get("v.contactMap.prefAddress");
        let businessAddress = component.get("v.contactMap.businessAddress");
        let profMap = component.get("v.contactMap.affilMap");
        let newEmailMap = component.get("v.contactMap.emailMap");
        let newPhoneMap = component.get("v.contactMap.phoneMap");
        let newSocialMap = component.get("v.contactMap.socialMap");
        let errorMessages = [];
        let isDuplicateEmail = false;
        let isDuplicatePhone = false;
        let isDuplicateSocial = false;
        let isPersonalEmailMonash = false;
        let MONASH_DOMAINS = ["student.monash.edu","monash.edu", "monashcollege.edu.au",
            "jmss.vic.edu.au","iitbmonash.org","monsu.org","climateworksaustralia.org","hudson.org.au"];

        if(newEmailMap.Personal){
            var splitEmail = newEmailMap.Personal.Name.split("@");
            if(splitEmail.length > 1){
                var domain = splitEmail[1].toLowerCase();
                if(MONASH_DOMAINS.includes(domain)) {
                    isPersonalEmailMonash = true;
                }
            }
        }

        if(newEmailMap.Personal && newEmailMap.Business) {
            if(newEmailMap.Personal.Name){
                if(newEmailMap.Personal.Name == newEmailMap.Business.Name) {
                    isDuplicateEmail = true;
                }
            }
        }
        if(mobilePhoneExists && homePhoneExists && workPhoneExists) {
            if(newPhoneMap.Mobile.Name == newPhoneMap.Home.Name || newPhoneMap.Mobile.Name == newPhoneMap.Work.Name || newPhoneMap.Work.Name == newPhoneMap.Home.Name) {
                isDuplicatePhone = true;
            }
        } else if(mobilePhoneExists && homePhoneExists) {
            if(newPhoneMap.Mobile.Name == newPhoneMap.Home.Name) {
                isDuplicatePhone = true;
            }
        } else if(mobilePhoneExists && workPhoneExists) {
            if(newPhoneMap.Mobile.Name == newPhoneMap.Work.Name) {
                isDuplicatePhone = true;
            }
        } else if(homePhoneExists && workPhoneExists) {
            if(newPhoneMap.Work.Name == newPhoneMap.Home.Name) {
                isDuplicatePhone = true;
            }
        }

        if(!component.get("v.isAllValid")) {
            errorMessages.push("Please ensure that Email and Phone information entered is in a valid format.");
        }

        if(isPersonalEmailMonash) {
            errorMessages.push("A Monash email address may only be added to the Business Email field.  Please try again.");
        }
        //Ensures that all required information for an Address exists if one is to be created
        if(manualAddressValidity === 'invalid'){
            errorMessages.push("Please ensure to fill out the Address fields.");
            component.set("v.addressLine", component.get("v.origAddressLine"));
        }
        if( ((!typeExists) && streetExists)  || ((!typeExists) && businessStreetExists)) {
            errorMessages.push("Please ensure Address Type is selected.");
        }
        if(!((businessCountryExists && businessStreetExists && businessCityExists)||!(businessCountryExists || businessStreetExists || businessCityExists))) {
            errorMessages.push("Please ensure that Employment Country, Address, and Suburb are entered.");
        }
        //Ensure org name is populated if position or industry is
        if((profMap.orgIndustry || profMap.position) && !profMap.orgName) {
            errorMessages.push("Please ensure Organization Name is entered.");
        }
        if(isDuplicateEmail) {
            errorMessages.push("You have entered the same email address more than once. Please enter it only as one of personal or professional.");
        }
        if(isDuplicatePhone) {
            errorMessages.push("You have entered the same phone number more than once. Please enter it only as one of mobile, home/other or work phone.");
        }
        if(businessAddress.Country2__c == prefAddress.Country2__c && businessAddress.Street_Name__c == prefAddress.Street_Name__c &&
            businessAddress.City__c == prefAddress.City__c && businessAddress.State__c == prefAddress.State__c &&
            businessAddress.Post_Code__c == prefAddress.Post_Code__c && prefAddress.Classification__c == "Private") {
            errorMessages.push("Preferred address must be type 'Business' if it is the same as Employment address.");
        }
        if(!Boolean(component.get("v.contactMap.preferredName.Last_Name__c"))) {
            errorMessages.push("Please ensure Last Name is entered.");
        }

        console.log('error: ' + errorMessages.length);
        if(errorMessages.length === 0) {
            this.saveDetails(component, event, helper);
        } else {
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Error",
                "message": errorMessages.join("\n\n")
            });
        }
    },


    saveDetails : function (component, event, helper){
        //Turn off edit mode
        component.set("v.isEditingMaster", false);
        component.set('v.oldEmailValue', component.get("v.contactMap.emailMap.Personal.Name"));
        component.set('v.oldBusinessEmailValue', component.get("v.contactMap.emailMap.Business.Name"));
        //Format interest areas into a savable format
        let interestAreas = "";
        component.get("v.interestAreaTracker").forEach(area => {
            if(area.filled) {
                interestAreas += area.label + ';';
            }
        });
        component.set("v.contactMap.contact.Volunteer_Areas_of_Interest__c", interestAreas)

        // Experian Confidence needs first letter in Upper Case to match UniCRM picklist values
        let personalMailConf = component.get('v.contactMap.emailMap.Personal.Verification_Status__c');
        let businessMailConf = component.get('v.contactMap.emailMap.Business.Verification_Status__c');

        if(personalMailConf != null && personalMailConf != undefined && personalMailConf.trim() !== ''){
            personalMailConf = personalMailConf.substring(0,1).toUpperCase() + personalMailConf.substring(1);
            component.set('v.contactMap.emailMap.Personal.Verification_Status__c', personalMailConf);
        }
        if(businessMailConf != null && businessMailConf != undefined && businessMailConf.trim() !== ''){
            businessMailConf = businessMailConf.substring(0,1).toUpperCase() + businessMailConf.substring(1);
            component.set('v.contactMap.emailMap.Business.Verification_Status__c', businessMailConf);
        }

        // Save setup objects first
        new Promise($A.getCallback((resolve, reject) => {
            let actionSetup = component.get('c.SERVER_saveSetupInformation');
            actionSetup.setParams({
                userSettings : component.get("v.contactMap.userSettings"),
            });
            actionSetup.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    resolve();
                } else if (state === "INCOMPLETE"){
                    reject('@@@error - Incomplete');
                }
                else {
                    let error = response.getError();
                    reject('@@@error'+JSON.stringify(error));
                }
            });
            $A.enqueueAction(actionSetup);
            component.set("v.loaded", false);
        }))
        .then(() => {
            // Save non-setup objects
            return new Promise($A.getCallback(function(resolve, reject) {
                let action = component.get('c.SERVER_saveProfileInformation');
                action.setParams({
                    cont : component.get("v.contactMap.contact"),
                    preferredMap : component.get("v.contactMap.preferredMap"),
                    preferredName : component.get("v.contactMap.preferredName"),
                    emailMap : component.get("v.contactMap.emailMap"),
                    phoneMap : component.get("v.contactMap.phoneMap"),
                    socialMap : component.get("v.contactMap.socialMap"),
                    origEmailMap : component.get("v.contactMapOrig.emailMap"),
                    origPhoneMap : component.get("v.contactMapOrig.phoneMap"),
                    origSocialMap : component.get("v.contactMapOrig.socialMap"),
                    origPrefAddress : component.get("v.contactMapOrig.prefAddress"),
                    prefAddress : component.get("v.contactMap.prefAddress"),
                    origBusinessAddress : component.get("v.contactMapOrig.businessAddress"),
                    businessAddress : component.get("v.contactMap.businessAddress"),
                    origAffiliation : component.get("v.contactMapOrig.affiliations"),
                    origAffilMap : component.get("v.contactMapOrig.affilMap"),
                    affilMap : component.get("v.contactMap.affilMap"),
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        resolve();
                    } else if (state === "INCOMPLETE"){
                        reject('@@@error - Incomplete');
                    }
                    else {

                        let error = response.getError();
                        reject('@@@error'+JSON.stringify(error));
                    }
                });
                $A.enqueueAction(action);
            }));
            
        })
        .then(() => {
            this.loadContactDetails(component, event);
            component.find('notifLib').showToast({
                    "variant": "success",
                    "title": "Success!",
                    "message": "The record has been updated successfully." });
            component.set("v.loaded", true);
            let childMFAComp=component.find("alumniManageSmsMFA");
            let childMFACompMobile=component.find("alumniManageSmsMFAMobile");

            childMFAComp.onLoadGetCurrentUserDetails();
            childMFACompMobile.onLoadGetCurrentUserDetails();
        })
        .catch(error => {
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Error",
                "message": "We cannot save your changes now, sorry about that.\nPlease try once more and if you see this message again, please email monashalumni@monash.edu"
            });
            component.set("v.loaded", true);
            console.error(error)
        });
    

    }
})