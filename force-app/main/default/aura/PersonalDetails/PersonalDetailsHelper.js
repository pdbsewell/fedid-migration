/**
 * Created by trentdelaney on 3/10/18.
 */
({
    savePersonalDetails : function (component, contact) {

        var action = component.get("c.SavePersonalDetails"); 
        //Clean previous monash id when previously studied at monash is set to false
        if(!contact.Previously_Studied_at_Monash__c){
            contact.Previous_Monash_ID__c = '';
        }

        //check previous name validation
        if(!this.checkPreviousNameFieldValidation(component, contact)) {
            return;
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

        // handling mobile phone no.
        this.buildContactMobileNumber(component, contact);
	
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
                        this.routeUserOnSuccess(component.get("v.isRedirect"));
                    }
                }
            }
        });

        $A.enqueueAction(action);
    },

    validatePhone : function(component) {
        if(component.get("v.contactRecord.Phone") !== "" && component.get("v.contactRecord.MobilePhone") === ""){
            component.set("v.phoneMandatoryMobile", false);
            component.set("v.phoneMandatoryHome", true);
        }
        else if(component.get("v.contactRecord.MobilePhone") !== "" && component.get("v.contactRecord.Phone") === ""){
            component.set("v.phoneMandatoryHome", false);
            component.set("v.phoneMandatoryMobile", true);
        }
    },

    parseApplicationId:function(component)
    {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedAppId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j + 1];
                    return retrievedAppId;
                }
            }
        }
    },

    saveApplication : function(component){

        var application = component.get("v.applicationRecord");

        //Update the disability field on the Application
        var action = component.get("c.UpdateApplication");
        action.setParams({
            appId : application.Id,
            hasDisabilities : application.HasDisabilities__c
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.accessAndEquityLoading", false);
            }
        });
        
        $A.enqueueAction(action);
    },

    saveExistingAusDisabilitySupport : function(component){
        //Retrieve application record
        var application = component.get("v.applicationRecord");

        //Update the Existing Aus Disability Support field on the Application
        var action = component.get("c.updateExistingAusDisabilitySupport");
        action.setParams({
            appId : application.Id,
            existingAusDisabilitySupport : application.Existing_Aus_disability_support__c
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.accessAndEquityLoading", false);
            }
        });

        $A.enqueueAction(action);
    },

    getPicklistValues : function(component)
    {
        var action = component.get("c.GetPicklistValues");
        action.setParams({
            "objectName" : "Contact",
            "fieldName" : "Citizenship_Type_Description__c"
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.citizenshipValues", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    routeUserOnSuccess : function(goHome)
    {
        var urlEvent = $A.get("e.force:navigateToURL");
        if(goHome){
            urlEvent.setParams({
                "url": '/',
                "isredirect" :false
            });
            urlEvent.fire();

        }else{
            window.location.reload()
        }
    },

    populateOptions : function(component){
        var options = [
            {value: "Yes", label:"Yes"},
            {value: "No", label:"No"}
        ];
        component.set("v.items", options);
    },

    populatePronoun : function (component) {
        
        var action = component.get("c.GetPicklistValues");
        action.setParams({
            "objectName" : "Contact",
            "fieldName" : "Pronouns_V2__c"
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                var arrResponse = response.getReturnValue();
                 var arrOptions = [];
                     arrOptions.push({
                         value:''
                         , label:'-- Select --'
                     });
                     for (var i in arrResponse){
                        arrOptions.push({
                            label: arrResponse[i],
                            value: arrResponse[i]
                        });
                     }
      
                 component.set("v.pronounOptions", arrOptions);
            }
        });
        $A.enqueueAction(action);
        
        
    },

    populatePreviousInstitution : function (component) {
        
        var action = component.get("c.GetPicklistValues");
        action.setParams({
            "objectName" : "Contact",
            "fieldName" : "Previous_Monash_Institution__c"
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                var arrResponse = response.getReturnValue();
                 var arrOptions = [];
                     arrOptions.push({
                         value:''
                         , label:'-- Select --'
                     });
                     for (var i in arrResponse){
                        arrOptions.push({
                            label: arrResponse[i],
                            value: arrResponse[i]
                        });
                     }
      
                 component.set("v.institutionOptions", arrOptions);
            }
        });
        $A.enqueueAction(action);
        
        
    },


    populateTitles : function (component) {
        var options = [
            {value: "", label:"Choose one..."},
            {value: "Mr", label: "Mr"},
            {value: "Mrs", label:"Mrs"},
            {value: "Miss", label:"Miss"},
            {value: "Ms", label:"Ms"},
            {value: "Mx", label:"Mx"},
            {value: "Dr", label:"Dr"},
            {value: "Prof", label:"Prof"}
        ];
        component.set("v.titleOptions", options);
    },


    populatePreviousInstitutions : function (component) {
        var options = [
            {value: "", label:"Choose one..."},
            {value: "Caulfield/Chisholm Institute of Technology (before 1990)", label: "Caulfield/Chisholm Institute of Technology (before 1990)"},
            {value: "Gippsland Institute of Advanced Education(before 1991)", label:"Gippsland Institute of Advanced Education(before 1991)"},
            {value: "Monash University", label:"Monash University"},
            {value: "Monash University (including Monash College and MUFY)", label:"Monash University (including Monash College and MUFY)"},
            {value: "Victorian College of Pharmacy (before 1992)", label:"Victorian College of Pharmacy (before 1992)"}
          
        ];
        component.set("v.previousInstitution",  options);
    },

    getContactFieldValidationErrorMessages : function(component, contactRecord, appRecord) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g;
        let isMononymousName = component.get("v.isMononymousName");
        var validationErrors = [];
        var sourcesystem = component.get("v.sourcesystem");
          if(sourcesystem!='AgentPortal')
        {
            if(!contactRecord.Country_Of_Birth__c || contactRecord.Country_Of_Birth__c=='choose one...' )   
            validationErrors.push('Country of birth is required');
        }
         if(sourcesystem=='AgentPortal' )
        {
            if(!contactRecord.CountryOfBirth__c)
              validationErrors.push('Country of birth is required');
        }

        if(appRecord && appRecord.Type_of_Study__c == 'Graduate Research'){
            if(component.get("v.previousMonashStaffIdToggle") && (contactRecord.Monash_Staff_ID__c == '' || contactRecord.Monash_Staff_ID__c == null || contactRecord.Monash_Staff_ID__c == undefined)){
                validationErrors.push ('Monash Staff Id is required');
            }
            if((appRecord.Malaysian_NRIC_Passport__c == '' || appRecord.Malaysian_NRIC_Passport__c == undefined || appRecord.Malaysian_NRIC_Passport__c.trim().length === 0) && appRecord.Campus_Location__c == 'Malaysia'){
                validationErrors.push ('Malaysian NRIC Passport is required');
            }

            if(appRecord.Currently_residing_in_Malaysia__c == true){
                if(appRecord.Malaysia_pass_expiry__c == null || appRecord.Malaysia_pass_expiry__c == '' || appRecord.Malaysia_pass_expiry__c == undefined){
                    validationErrors.push ('Malaysia Pass Expiry is required');
                }
                if(appRecord.Malaysia_pass_type__c == '' || appRecord.Malaysia_pass_type__c == null || appRecord.Malaysia_pass_type__c == undefined){
                    validationErrors.push ('Malaysia Pass Type is required');
                }
            }
        }

        //return no errors if the form is locked - to accomodate applications from other sources
        if (component.get("v.formLocked")) return validationErrors;
        //check first name
        if (contactRecord.First_Name__c && contactRecord.First_Name__c.trim()) {
            if (XML_REGEX_PATTERN.test(contactRecord.First_Name__c)) validationErrors.push('Legal given name(s) is not in the expected format.');
        } else {
            if (!isMononymousName) {
                validationErrors.push('Legal given name(s) is required');
            }
        }
        //check family name
        if (contactRecord.Last_Name__c && contactRecord.Last_Name__c.trim()){
            if (XML_REGEX_PATTERN.test(contactRecord.Last_Name__c)) validationErrors.push('Legal last name is not in the expected format.');
        } else {
            if (isMononymousName) {
                validationErrors.push('Legal name (Mononymous) is required');
            } else {
                validationErrors.push('Legal last name is required');
            }
        }
        //check birthdate
        if(contactRecord.Birthdate) {
            if (XML_REGEX_PATTERN.test(contactRecord.Birthdate)) validationErrors.push('Birthdate is not in the expected format.');
        } else {
            validationErrors.push('Birthdate is required');
        }

        //check gender
        if(contactRecord.Gender__c){
            if (XML_REGEX_PATTERN.test(contactRecord.Gender__c)) validationErrors.push('Gender is not in the expected format.');
            if (contactRecord.Gender__c === 'U') validationErrors.push('Gender is required');
        } else {
             validationErrors.push('Gender is required');
        }
     
        //check country
        if(contactRecord.MailingCountry){
            if (XML_REGEX_PATTERN.test(contactRecord.MailingCountry) ) validationErrors.push('Address: Country is not in the expected format.');
        } else {
            validationErrors.push('Address: Country is required');
        }
        //check street
       if(contactRecord.MailingStreet) {
            if (XML_REGEX_PATTERN.test(contactRecord.MailingStreet) ) validationErrors.push('Address: Street is not in the expected format.');
        } else {
            validationErrors.push('Address: Street is required');
        }

        //additional required fields for Australia
        //check city if country is australia
        if(contactRecord.MailingCity){
            if (XML_REGEX_PATTERN.test(contactRecord.MailingCity) ) validationErrors.push('Address: City is not in the expected format.');
        } else {
           if(contactRecord.MailingCountry === 'Australia') validationErrors.push('Address: City is required');
        }
        //check state if country is australia
        if(contactRecord.MailingState){
            if (XML_REGEX_PATTERN.test(contactRecord.MailingState) ) validationErrors.push('Address: State is not in the expected format.');
        } else {
           if(contactRecord.MailingCountry === 'Australia') validationErrors.push('Address: State is required');
        }
        //check post code if country is australia
        if(contactRecord.MailingPostalCode){
            if (XML_REGEX_PATTERN.test(contactRecord.MailingPostalCode)) validationErrors.push('Address: Post Code is not in the expected format.');
        } else {
            if(contactRecord.MailingCountry === 'Australia')  validationErrors.push('Address: Post Code is required');
        }

        //check email
        if(contactRecord.Personal_Email__c){
            if (XML_REGEX_PATTERN.test(contactRecord.Personal_Email__c)) validationErrors.push('Email is not in the expected format.');
        } else {
            validationErrors.push('Email is required');
        }

        //check home phone or mobile phone
        if(contactRecord.HomePhone || contactRecord.MobilePhone) {
            if (contactRecord.HomePhone) {
                if (XML_REGEX_PATTERN.test(contactRecord.HomePhone)) validationErrors.push('Phone is not in the expected format.');
            }
            if (contactRecord.MobilePhone) {
                if (XML_REGEX_PATTERN.test(contactRecord.MobilePhone) ) validationErrors.push('MobilePhone is not in the expected format.');
            }
           
        } else {
             validationErrors.push ('Home Phone or Mobile Phone is required');
        }

        return validationErrors;
    },
    checkPreviousMonashId : function (component, event) {
        let previousMonashIdValue = component.get("v.enteredPreviousMonashId");
        if(previousMonashIdValue){
            //Default invalid
            component.set("v.existingPreviousMonashLengthValid", false);
            
            if(previousMonashIdValue.trim().length === 8){
                
                //Check check sum
                let checkSumResult = (11 - ((previousMonashIdValue.charAt(0)*8) + (previousMonashIdValue.charAt(1)*7) + (previousMonashIdValue.charAt(2)*6) + (previousMonashIdValue.charAt(3)*5) + (previousMonashIdValue.charAt(4)*4) + (previousMonashIdValue.charAt(5)*3) + (previousMonashIdValue.charAt(6)*2)) % 11);
                //If resulting value is 11 change it to 0
                if(Math.abs(checkSumResult) === 11){
                    checkSumResult = 0;
                }
                if(checkSumResult == previousMonashIdValue.charAt(7)){                   
                    //Set valid if length is 8
                    component.set("v.existingPreviousMonashLengthValid", true);

                    //Query matching contact records
                    if(!component.get("v.existingPreviousMonashResults")){

                        //Check if birthdate is populated
                        if(component.get('v.contactRecord').Birthdate){
                            //Start finding contact - disable previous monash id field
                            component.set("v.existingPreviousMonashResults", true);
                            //Reset find match status
                            component.set("v.findPreviousMonashStatus", null);      

                            //Call logic to find matching contact record with same person id and birthdate
                            var action = component.get("c.findMatchingStudent");
                            action.setParams({
                                "previousMonashId" : component.get('v.contactRecord').Previous_Monash_ID__c,
                                "applicantBirthDate" : component.get('v.contactRecord').Birthdate
                            });
                            action.setCallback(this, function(response){
                                var state = response.getState();
                                if(state === "SUCCESS"){
                                    var result = response.getReturnValue();
                                    
                                    //Set find match status
                                    component.set("v.findPreviousMonashStatus", result);   

                                    //Stop finding contact - Enable previous monash id field
                                    component.set("v.existingPreviousMonashResults", false);
                                }
                            });

                            $A.enqueueAction(action);
                        }

                    }
                    
                }
            }
        }
    },
     // build Contact Mailing address from Experian cmp response
    buildContactMailingAddress : function(component, contact)
    {
        let addressSearchComp = component.find("expAddress");
        if(addressSearchComp){
            let address = addressSearchComp.getAddress();
            contact.MailingCountry = address.splitRecord.country;
            contact.MailingState = address.splitRecord.region;
            contact.MailingCity = address.splitRecord.locality;
            contact.MailingPostalCode = address.splitRecord.postal_code;
            contact.MailingStreet = address.splitRecord.address_line_full;
            contact.Mailing_Address_Verification_Status__c = address.confidence;
            contact.Mailing_Address_Verification_Source__c = 'Experian';
            contact.Mailing_Address_DPID__c = address.dpId;
        }

    },
    // build full address from Contact fields to display on the UI 
     buildFullAddress: function(component, contact)
    {
        component.set("v.fullAddress", this.handleNull(contact));
        var country = contact.MailingCountry;
        if(!component.get("v.formLocked"))
        {
            if ( (country == 'Australia' && contact.MailingStreet && contact.MailingCity && contact.MailingPostalCode && contact.MailingState) ||
            (country != 'Australia' && contact.MailingStreet))
            {
                component.set("v.displayAddress", true);
            }
        }else {
            component.set("v.displayAddress", true);
        }
        
    }, 
    //Handle null on the fields
    handleNull: function(contact)
    { 
       var arr = [];
       contact.MailingStreet? arr.push(contact.MailingStreet) : '';
       contact.MailingCity? arr.push(contact.MailingCity) : '';
       contact.MailingState? arr.push(contact.MailingState) : '';
       contact.MailingCountry? arr.push(contact.MailingCountry) : '';
       contact.MailingPostalCode? arr.push(contact.MailingPostalCode) : '';
       return  arr.join(', ');
    },

    buildContactMobileNumber : function(component, contact) {
        // handle mobile phone numbers
        let mobileSearchCmp = component.find("phoneNumberSearch");
        if (mobileSearchCmp) {
            let validatedNumberDetails = mobileSearchCmp.getPhoneNumberValidationResult();
            if (validatedNumberDetails.unicrm_formatted_phone_number) {
                component.set("v.mobilePhoneNumber", validatedNumberDetails.unicrm_formatted_phone_number);
            }
        } 
        if (component.get("v.mobilePhoneNumber")){
            contact.MobilePhone = component.get("v.mobilePhoneNumber");
        } else {
            contact.MobilePhone = component.get("v.mfaVerifiedPhoneNumber");
        }
        
    },
    loadPicklistOptions : function (component, actionName, optionAttributeName, insertDefault, mapAttrName)
    {
        	var action1 = component.get("c.getCountryAttributes");
        	action1.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                //store the return response from server (List<Map<String, String>>)
                var arrResponse = response.getReturnValue();
                // add a default blank
                var arrOptions = [];
               

                var iLen = arrResponse.length;
                for(var i = 0; i < iLen; ++i)
                {
                    var mapOption = arrResponse[i];
                    arrOptions.push(mapOption);
                }

                // if required, store an (id:label) map for lookups later
                if(mapAttrName)
                {
                    this.storeValueLabelMap (component, arrOptions, mapAttrName);
                }
                component.set(optionAttributeName, arrOptions);
                //this.itemFinishedLoading(component, 'loadPicklistOptions');
            }
        });
         $A.enqueueAction(action1);
       
    },
    storeValueLabelMap : function(component, arrOptions, mapAttrName)
    {
        var mapObj = {};
        var iLen = arrOptions.length;
        for(var i = 0; i < iLen; ++i)
        {
            var objOption = arrOptions[i];
            // there may be a blank value
            //if(objOption.value) {
                mapObj[objOption.value] = objOption.label;
            //}
        }
        component.set(mapAttrName, mapObj);
    },
    saveApplicationDisabilityConsent : function(component, checked){
        //Retrieve application record
        var application = component.get("v.applicationRecord");
        //Update the Existing Aus Disability Support field on the Application
        var action = component.get("c.saveApplicationDisabilityConsent");
        action.setParams({
            appId : application.Id,
            disabilityConsent : application.Disability_Opt_In__c
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.accessAndEquityLoading", false);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    saveMalaysiaDetails : function(component, checked){

        //Retrieve application record
        var application = component.get("v.applicationRecord");

        //check if malaysia GRT Application
        if(application.Type_of_Study__c == 'Graduate Research' && application.Campus_Location__c == 'Malaysia'){
        var action = component.get("c.saveApplicationMalaysianDetails");
        action.setParams({
            appId : application.Id,
            malaysianPassport : application.Malaysian_NRIC_Passport__c != '' ? application.Malaysian_NRIC_Passport__c : null,
            residingMalaysia: application.Currently_residing_in_Malaysia__c,
            passExpiry: application.Malaysia_pass_expiry__c != '' ? application.Malaysia_pass_expiry__c : null,
            passType: application.Malaysia_pass_type__c != '' ? application.Malaysia_pass_type__c : null
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                //component.set("v.accessAndEquityLoading", false);
            }
        });
 
    $A.enqueueAction(action);
        }
    },
    
    populateMalaysiaPassType : function (component) {
        var options = [
            {value: "", label:"Choose one..."},
            {value: "STUDENT", label:"Student"},
            {value: "TOURIST", label:"Tourist / Social Dependant"},
            {value: "OTHER-MPT", label:"Other"}
        ];
        component.set("v.malaysianType",  options);
    },

    checkPreviousNameFieldValidation : function (component, contact) {
        var previousNameCheckbox = component.get("v.previousNameExist");
        if(previousNameCheckbox) {
            var isMononymousName = component.find("mononymousMameCheckbox").get("v.checked")
            if (!contact.Previous_Surname__c && isMononymousName) {
                var previousNameField = component.find("previousName");
                previousNameField.setCustomValidity("Please enter your Previous Name");
                previousNameField.reportValidity();
                component.set('v.showDetailsSpinner', false);
                return false;
            }
        } else {
            contact.Previous_Surname__c = '';
            contact.Previous_Firstname__c = '';
        }
        return true;
    },
    
    checkSSOLogin : function(component){

        let contact = component.get("v.contactRecord");

        var action = component.get("c.isSSOUser");
        action.setParams({
            contactId : contact.Id
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === "SUCCESS") 
            {
                let retVal = response.getReturnValue();
                component.set("v.isSSOUser", retVal);
                if(component.get("v.formLocked") === false) {
                    component.set("v.formLocked", retVal);
                }
            }
        });
 
        $A.enqueueAction(action);
    }
})