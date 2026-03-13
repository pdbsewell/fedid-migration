/**
 * Created by trentdelaney on 3/10/18.
 */
 ({
    doInit : function(component, event, helper)
    {
        component.set('v.showSpinner', true);
        // populate static components
        helper.populatePronoun(component);
        helper.populateTitles(component);
        helper.populateOptions(component);
        helper.populatePreviousInstitutions(component);
        helper.populateMalaysiaPassType(component);
        helper.loadPicklistOptions(component, "c.getCountryAttributes", "v.countryOBOptions", true, "v.countryMap");
        // load server data
        var action = component.get("c.GetPersonalDetailsInitLoad");
        var appId = helper.parseApplicationId(component);
        if(!appId){
            appId = component.get("v.applicationId");
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + appId;
        }        
        action.setParams({
            applicationId : appId,
            currentUrl : window.location.href
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS") {
                var objResponse = response.getReturnValue();
				 
				 helper.populatePreviousInstitutions(component);
 				// set the country of birth options
                //component.set("v.countryOBOptions", objResponse.countryOBOptions);
                // set the country options
                component.set("v.countryOptions", objResponse.countryOptions);
                // set the gender options
                component.set("v.genderOptions", objResponse.genderOptions);
                // set previous application
                component.set("v.applicationRecord", objResponse.previousApplication);
      

                // dynamically convert user ui's date
                let systemDateString = [];
                for(let counter = 0; counter < objResponse.TODAY.split('-').length; counter++){
                    systemDateString.push(parseInt(objResponse.TODAY.split('-')[counter]));
                }
                let clientDateString = [];
                clientDateString.push(new Date().getFullYear());
                clientDateString.push(new Date().getMonth() + 1);
                clientDateString.push(new Date().getDate());

                // check if a day needs to be added
                let needAddDay = false;
                for(let counter = 0; counter < systemDateString.length; counter++){
                    if(clientDateString[counter] < systemDateString[counter]){
                        // only flag if still false
                        if(!needAddDay){
                            needAddDay = true;
                        }
                    }
                }
                if(objResponse.previousApplication !== undefined){
                    component.set("v.typeOfStudy", objResponse.previousApplication.Type_of_Study__c);
                }
                
				component.set("v.cobCountryId", objResponse.contact.CountryOfBirth__c);
                component.set("v.contactRecord", objResponse.contact);

                if(component.get('v.contactRecord').Previous_Surname__c != null || component.get('v.contactRecord').Previous_Firstname__c != null){
                    component.set("v.previousNameExist", true);
                }else{
                    component.set("v.previousNameExist", false);
                }
                
                if(component.get('v.contactRecord').Is_Mononymous_Name__c){
                    component.set("v.previousLastNameLabel", 'Previous name');
                    component.set("v.isMononymousPreviousName", component.get('v.contactRecord').Is_Mononymous_Name__c);
                }

                if(component.get('v.contactRecord').Monash_Staff_ID__c != null){
                    component.set("v.previousMonashStaffIdChecked", true);
                }else{
                    component.set("v.previousMonashStaffIdChecked", false);
                }

                // lock the form if there are previous applications
                component.set("v.formLocked", objResponse.hasPreviousApplications);
                helper.buildFullAddress(component, objResponse.contact);

                if(!component.get("v.formLocked") )
                {
                    if( component.get("v.displayAddress"))
                        component.set("v.updateAddress", true);
                }else
                {
                    component.set("v.updateAddress", false);
                    component.set("v.isMobileNoToggleVisible", false);
                }

                if(objResponse.previousApplication !== undefined){
                    component.set("v.studyLocation", objResponse.previousApplication.Campus_Location__c);
                }

                // set whether the user is meant to be mfa challenged
                component.set('v.mfaRequired', objResponse.mfaRequired);
                
                //MGROI-880 adding code for sacntioned countries to bypass mobile MFA 
                if(objResponse.isCountrySanctioned !== undefined) {
                    component.set("v.isCountrySanctioned", true);
                    component.set('v.mfaRequired', false);//overwriting the MFA conditions for Sanctioned countries
                }

                // Logic to check previous monash id validity
                if(component.get('v.contactRecord').Previous_Monash_ID__c){
                    component.set("v.enteredPreviousMonashId", component.get('v.contactRecord').Previous_Monash_ID__c);
                    helper.checkPreviousMonashId(component, event);
                }

                // Logic to check for Mononymous names
                if (!component.get('v.contactRecord').First_Name__c || !component.get('v.contactRecord').First_Name__c.trim()) {
                    component.set("v.isMononymousName", true);
                }

                // set MFA verified Phone number from MFA Component or Contact, whichever is available first
                let mfaMobile = component.get("v.mfaVerifiedPhoneNumber"); 
                if (!mfaMobile || !mfaMobile.trim()) {
                    mfaMobile = objResponse.mfaPhoneNo;
                }
                let contactPhone = component.get('v.contactRecord').Phone;
                let contactMobile = component.get('v.contactRecord').MobilePhone;
                component.set("v.mobilePhoneNumber", contactMobile);
                if (mfaMobile != contactMobile) {
                    component.set("v.isMobilePhoneLocked", true);
                    component.set("v.isMobileNoToggleVisible", false);
                    if (!contactMobile || !contactMobile.trim()) { // Mobile no is Blank, due to roll-up delays
                        component.set("v.mobilePhoneNumber", mfaMobile);
                        component.set("v.isMobileNoToggleVisible", true);
                    }
                }

                component.set("v.showSpinner", false);
            }
        });

        $A.enqueueAction(action);
    },

    mapStudyLocation : function(component, event){
        var param = event.getParam("picklist");
        component.set("v.studyLocation", param);
    },
    
    saveDetails : function (component, event, helper) {
        var params = event.getParam('arguments');
        var callback;
        if (params) {
            callback = params.callback;
        }
        var contact = component.get("v.contactRecord");
        contact.CountryOfBirth__c = component.get("v.cobCountryId");

        //check validity for previous name
        if(!helper.checkPreviousNameFieldValidation(component, contact)) {
            return;
        }
        // check if a day needs to be added
        let needAddDay = component.get("v.dayIncremented");
        if(needAddDay){
            let contactBirthDateString = contact.Birthdate.split('-');
            //re-initialize contact birthdate
            let contactBirthDate = new Date();
            contactBirthDate.setFullYear(parseInt(contactBirthDateString[0]));
            contactBirthDate.setMonth(parseInt(contactBirthDateString[1])-1);
            contactBirthDate.setDate(parseInt(contactBirthDateString[2]));
            //increment a day
            contactBirthDate.setDate(contactBirthDate.getDate() - 1);
            //set corrected date
            let newYear = contactBirthDate.getFullYear();
            let newMonth = (contactBirthDate.getMonth() + 1);
            let newDate = contactBirthDate.getDate();
            contact.Birthdate = newYear + '-' + (newMonth.toString().length < 2 ? '0' : '') + newMonth + '-' + (newDate.toString().length < 2 ? '0' : '') + newDate;
        }

        //Check if Mononymous name
        if (component.get("v.isMononymousName")) {
            contact.First_Name__c = '';
            contact.FirstName = '';
        }

        // handling mobile phone no.
        helper.buildContactMobileNumber(component, contact);

        //save malaysian details
        helper.saveMalaysiaDetails(component);

        //save study location details
        if(!component.get("v.isRedirect") && component.get("v.applicationRecord").Campus_Location__c != 'Online'){
            var childCmp = component.find("childStudyLocation");
            childCmp.onClickSaveCitizenship(function(response){
                if (callback) {
                    callback(response);
                }
                component.set('v.showDetailsSpinner', true);
                var action = component.get("c.SavePersonalDetails");

                //Clean previous monash id when previously studied at monash is set to false
                if(!contact.Previously_Studied_at_Monash__c){
                    contact.Previous_Monash_ID__c = '';
                }
                helper.buildContactMailingAddress(component, contact)
                helper.buildFullAddress(component, contact);

                //Check if previous student selected but no previous monash id is entered
                if(contact.Previously_Studied_at_Monash__c && !contact.Previous_Monash_ID__c){
                    //Show error message
                    var previousMonashIdField = component.find("previousMonashIdNumber");
                    previousMonashIdField.setCustomValidity("Please enter your Previous Monash Id");
                    previousMonashIdField.reportValidity();
                    component.set('v.showDetailsSpinner', false);
                    return;
                }

                action.setParams({
                    "updatedContact" : contact,
                    "mfaRequired" : component.get('v.mfaRequired')
                });
                action.setCallback(this, function(response){
                    var state = response.getState();
                    if(state === "SUCCESS"){
                        var result = response.getReturnValue();
                        if(result.length > 0){
                            //Errors in the SS validation
                            component.set("v.errors", result);
                            component.set("v.showErrors", true);
                            component.set('v.showDetailsSpinner', false);
                        }else{
                            if(component.get("v.isRedirect")){
                                helper.routeUserOnSuccess(component.get("v.isRedirect"));
                            }
                        }
                    }
                });

                    $A.enqueueAction(action);
            
            });
        }else{
            component.set('v.showDetailsSpinner', true);
            var action = component.get("c.SavePersonalDetails");
            helper.buildContactMailingAddress(component, contact);
                      
            //Clean previous monash id when previously studied at monash is set to false
            if(!contact.Previously_Studied_at_Monash__c){
                contact.Previous_Monash_ID__c = '';
            }

            //Check if previous student selected but no previous monash id is entered
            if(contact.Previously_Studied_at_Monash__c && !contact.Previous_Monash_ID__c){
                //Show error message
                var previousMonashIdField = component.find("previousMonashIdNumber");
                previousMonashIdField.setCustomValidity("Please enter your Previous Monash Id");
                previousMonashIdField.reportValidity();
                component.set('v.showDetailsSpinner', false);
                return;
            }

            action.setParams({
                "updatedContact" : contact,
                "mfaRequired" : component.get('v.mfaRequired')
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === "SUCCESS"){
                    var result = response.getReturnValue();
                    if (callback) {
                        callback(result);
                    }

                    if(result.length > 0){
                        //Errors in the SS validation
                        component.set("v.errors", result);
                        component.set("v.showErrors", true);
                        component.set('v.showDetailsSpinner', false);
                    }else{
                        if(component.get("v.isRedirect")){
                            helper.routeUserOnSuccess(component.get("v.isRedirect"));
                        }
                    }
                }
            });

            $A.enqueueAction(action);
        }
    },
    saveDetailsFromPartner : function(component, event, helper){
        var params = event.getParam('arguments');
        var callback;
        if (params) {
            callback = params.callback;
        }

        var contact = component.get("v.contactRecord");

        //Check if Mononymous name
        if (component.get("v.isMononymousName")) {
            contact.First_Name__c = '';
            contact.FirstName = '';
        }

        // handling mobile phone no.
        helper.buildContactMobileNumber(component, contact);

        //save study location details
        if(component.get("v.applicationRecord").Campus_Location__c != 'Online'){
            var childCmp = component.find("childStudyLocation");
            childCmp.onClickSaveCitizenship(function(response){
                if (callback) {
                    callback(response);
                }
            });
        }
        
   
        component.set('v.showDetailsSpinner', true);
        var action = component.get("c.SavePersonalDetails");

        //Clean previous monash id when previously studied at monash is set to false
        if(!contact.Previously_Studied_at_Monash__c){
            contact.Previous_Monash_ID__c = '';
        }
        helper.buildContactMailingAddress(component, contact);
        helper.buildFullAddress(component, contact);
        //Check if previous student selected but no previous monash id is entered
        if(contact.Previously_Studied_at_Monash__c && !contact.Previous_Monash_ID__c){
            //Show error message
            var previousMonashIdField = component.find("previousMonashIdNumber");
            previousMonashIdField.setCustomValidity("Please enter your Previous Monash Id");
            previousMonashIdField.reportValidity();
            component.set('v.showDetailsSpinner', false);
            return;
        }

        action.setParams({
            "updatedContact" : contact,
            "mfaRequired" : component.get('v.mfaRequired')
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var result = response.getReturnValue();

                if(result.length > 0){
                    //Errors in the SS validation
                    component.set("v.errors", result);
                    component.set('v.showDetailsSpinner', false);
                }
            }
        });

        $A.enqueueAction(action);
    },

    onToggleATSI : function(component, event, helper){
        var contact = component.get("v.contactRecord");
         
   
        helper.savePersonalDetails(component, contact);
    },

    saveDetailsAndContinue : function (component, event, helper) {
        component.set('v.showDetailsSpinner', true);
        var contact = component.get("v.contactRecord");
        var appRecord = component.get("v.applicationRecord");
         var country = component.get('v.cobCountryId');
         contact.CountryOfBirth__c = country;
         helper.buildContactMailingAddress(component, contact);
         helper.buildFullAddress(component, contact);
         contact.MobilePhone = component.get("v.mobilePhoneNumber");

         var contactErrorMessages = helper.getContactFieldValidationErrorMessages(component, contact, appRecord);

        if (contactErrorMessages.length>0) {
            //Show error message
            component.set("v.errors", contactErrorMessages);
            component.set("v.showErrors", true);
            component.set('v.showDetailsSpinner', false);
            return;
        }
       
        
        helper.savePersonalDetails(component, contact);
    },

    clearErrors : function (component) {
        component.set("v.errors", false);
        component.set("v.errorDetails", false);
        component.set("v.showErrors", false);
    },

    mfafetched: function (component, event, helper) {
        // set MFA Mobile no
        component.set("v.mfaVerifiedPhoneNumber", event.getParam('_mfaVerifiedNum'));
        // if mobile no already filled, do NOT overwrite; else fill it with MFA Mobile no
        let mobileNo = component.get("v.mobilePhoneNumber");
        if (!mobileNo || !mobileNo.trim()) {
            component.set("v.mobilePhoneNumber", event.getParam('_mfaVerifiedNum'));
        }
    },

    checkPhone : function(component, event, helper) {
        helper.validatePhone(component);
    },

    onClickCloseAlert:function(component, event, helper)
    {
        component.set("v.showErrors", false);
    },

    toggleMobilePhoneEdit : function(component) {
        component.set("v.isMobilePhoneLocked", !component.get("v.isMobilePhoneLocked"));
    },

    onChangeDisability : function (component, event ,helper) {
        component.set("v.accessAndEquityLoading", true);
        helper.saveApplication(component);
    },

    onChangeRegisteredDisabilitySupport : function (component, event, helper) {
        component.set("v.accessAndEquityLoading", true);
        helper.saveExistingAusDisabilitySupport(component);
    },

    handleCheckPreviousMonashId : function (component, event, helper) {
        if(component.find("previousMonashIdNumber")){
            if(component.find("previousMonashIdNumber").get("v.value")){
                component.set("v.enteredPreviousMonashId", component.find("previousMonashIdNumber").get("v.value"));
                helper.checkPreviousMonashId(component, event);
            }
        }
    },

    handleCheckPreviousName : function (component, event) {
        component.set("v.previousNameExist", component.find("prevNameCheckbox").get("v.checked"));
        component.set("v.showMonoNameQuestion",component.find("prevNameCheckbox").get("v.checked"));
    },

    handleCheckMononymousName : function (component, event) {
        var isChecked = component.find("mononymousMameCheckbox").get("v.checked");
        if (isChecked) {
            component.set("v.previousLastNameLabel", 'Previous name');
        } else {
            component.set("v.previousLastNameLabel", 'Previous last name');
        }
        component.set("v.isMononymousPreviousName", component.find("mononymousMameCheckbox").get("v.checked"));
    },

    handleCheckPreviousMonashStaff : function (component, event, helper) {
        var isChecked = component.find("previousMonashIdToggle").get("v.checked");
        component.set("v.previousMonashStaffIdChecked", isChecked);
        if (!isChecked) {
           // component.set("v.contactRecord.Monash_Staff_ID__c", null);
            var staffIdInput = component.find("previousMonashStaffId");
            if (staffIdInput) {
                staffIdInput.set("v.value", null);
            }
        }
    },

    changeCampusLocation : function(component, event, helper){
        var params = event.getParam('arguments');
        if (params) {
            var campusLocation = params.campusLocation;
            var applicationRecord = component.get('v.applicationRecord');
            applicationRecord.Campus_Location__c = campusLocation;
            component.set('v.applicationRecord', applicationRecord);
        }
    },
    changeResidencyStatus : function(component, event, helper){
        var params = event.getParam('arguments');
        if (params) {
            var residencyStatus = params.residencyStatus;
            var applicationRecord = component.get('v.applicationRecord');
            applicationRecord.Residency_Status__c = residencyStatus;
            component.set('v.applicationRecord', applicationRecord);
        }
    },
    validateAllFields : function(component, event, helper){
        var params = event.getParam('arguments');
        var callback;
        if (params) {
            callback = params.callback;
        }
        var contactRecord = component.get("v.contactRecord");
        var appRecord = component.get("v.applicationRecord");
        contactRecord.CountryOfBirth__c = component.get("v.cobCountryId");
       
        helper.buildContactMailingAddress (component, contactRecord);
        helper.buildContactMobileNumber (component, contactRecord);

        var contactErrorMessages = helper.getContactFieldValidationErrorMessages(component, contactRecord, appRecord);

        var hasContactErrorMessages = contactErrorMessages.length>0;
        var formattedErrorMessage = 'Please complete the following:<br/>';
        if (hasContactErrorMessages == true) {
            contactErrorMessages.forEach(contactErrorMessage => formattedErrorMessage +=  '<span style="padding-left: 1em;"> ' + contactErrorMessage + '</span><br/>');
        }
        if(callback) {
            callback({
                "hasError" : hasContactErrorMessages,
                "errorMessage" : formattedErrorMessage
            });
        }
    },
    // handle checkbox that updates the address
    handleCheckboxChange: function (component, event, helper) {
      var ischecked = event.getSource().get("v.checked");
      if(ischecked)
      {
        component.set("v.displayAddress", false);
      }else{
        component.set("v.displayAddress", true);
      }
  },
   onChangeDisabilityConsent : function (component, event ,helper) {
      component.set("v.accessAndEquityLoading", true);
        helper.saveApplicationDisabilityConsent(component);
      
    },

    handleActionCitizen : function(component, event, helper){
        var params = event.getParam('arguments');
        if (params) {
            var residencyStatus = params.residencyStatus;
            if(residencyStatus != 'DOM-SUN'){
                component.set("v.applicationRecord.Currently_residing_in_Malaysia__c", false);
                component.set("v.applicationRecord.Malaysia_pass_type__c", "");
                component.set("v.applicationRecord.Malaysia_pass_expiry__c", "");
            }
        }
    }

    
   

})