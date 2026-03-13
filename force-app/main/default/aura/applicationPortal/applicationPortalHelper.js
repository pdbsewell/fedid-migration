({
    incrementLoad:function(component, fnCalling)
    {
        var iToLoad = component.get('v.itemsToLoad');
        component.set('v.itemsToLoad', iToLoad + 1);
        component.set('v.showSpinner', true);
    }
    
    , finishedLoad:function(component, fnCalling)
    {
        var iToLoad = component.get('v.itemsToLoad');
        iToLoad -= 1;
        component.set('v.itemsToLoad', iToLoad);
        if(iToLoad <= 0)
        {
        	component.set('v.showSpinner', false);
            iToLoad = 0;
        }
    }
    
    , initLoad: function(component)
    {
        console.log('applicationPortalHelper:initLoad');
        
        //retrieve campus of study list        
        this.initCampusLocationOptions(component);
        
        //retrieve citizenship type list
        this.initCitizenshipTypeOptions(component);
        
        //retrieve state list
        this.retrieveYESNOPicklistValues(component.find("atsiOptions")); 
        
        //retrieve state list
        this.retrieveYESNOPicklistValues(component.find("addressType"));
                
        var objHelper = this;
        var action = component.get("c.initDataLoad");
        var appId = component.get("v.appId");
        var objParams = {"applicationId":appId};
        action.setParams(objParams);
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if(state == "SUCCESS")
            {
                var objResponse = response.getReturnValue();          
                
                // salutations
                var salutations = objResponse.salutations;
                var cmpSalutations = component.find("salutationOptions");
                
                objHelper.populatePicklist(salutations, cmpSalutations);
                
                // gender
                var genders = objResponse.genders;
                objHelper.populatePicklist(genders, component.find("GenderOptions"));
                
                // previous institutions
                var institutions = objResponse.institutions;
                objHelper.populatePicklist(institutions, component.find("previousinstitution"));
                
                // state list
                var stateList = objResponse.state_list;
                objHelper.populatePicklist(stateList, component.find("StateOptions"));
                
                // country
                var countries = objResponse.countries;
                objHelper.populatePicklist(countries, component.find("countryOptions"));
        
                var application = objResponse.application;
                if(application)
                {
                    component.set('v.campusOfStudy', application.Campus_Location__c);
                }
                
                var prevApps = objResponse.previous_applications;
                var disableEdit = false;
                if(prevApps && prevApps.length > 0)
                {
                    disableEdit = true;
                }                
                component.set("v.isDisabled", disableEdit);                    
                component.set("v.disableEditing", disableEdit);
                
                console.log('applicationPortalHelper:End InitLoad');
                
                this.finishedLoad(component, 'initLoad');
            }
        });
        
        this.incrementLoad(component, 'initLoad');
        $A.enqueueAction(action);
    }
    
    , parseApplicationIdFromUrl:function(component)
    {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        
        var appId;
        for (var i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
            //to split the key from the value.
            for (var j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') {
                    //get the app Id from the parameter
                    appId = sParameterName[j+1];
                    component.set("v.appId", appId);
                    return appId;
                }
            }
        }
        return null;
    }
    
    , populatePicklist:function(arrItems, inputSel)
    {
        var opts = [];
        opts.push({"class": "optionClass", label: "--Select--", value: ""});
        for(var i=0;i< arrItems.length;i++){
            var item = arrItems[i];
            opts.push({"class": "optionClass", label: item, value: item});
        }
        
        if(inputSel)
        	inputSel.set("v.options", opts);
        else
        {
            console.error('applicationPortalHelper:: inputSel is ' + inputSel);
        }
    }
    
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  validates the form
    * @revision     
    *******************************************************************************/
	, validateForm : function(component) {
        console.debug('applicationPortalHelper::validateForm() begin');
        
        var isValid = true;
		var arrErrors = [];

        var salutationOptions = component.find("salutationOptions");
        if (!this.isFieldPopulated(component.get("v.userRec.App_Salutation__c"))) {
            salutationOptions.set("v.errors", [{message:"Title is required"}]);
            arrErrors.push('missing salutation');
            isValid = false;
        } else {
            this.clearErrors(component, "salutationOptions");
        }

        var fName = component.get("v.userRec.FirstName");
        if (this.isFieldPopulated(fName)) {
            if (fName.length > 40) {
                fName.set("v.errors", [{message:"First Given Name is too long"}]);
                arrErrors.push('first name length');
                isValid = false;
            }
        }

        var otherName = component.get("v.userRec.Other_Given_Name__c");
        if (this.isFieldPopulated(otherName)) {
            if (otherName.length > 255) {
                otherName.set("v.errors", [{message:"Other Given Names is too long"}]);
                arrErrors.push('other name too long');
                isValid = false;
            }
        }

        var lName = component.find("lName");
        var lNameValue = component.get("v.userRec.LastName");
        if (!this.isFieldPopulated(lNameValue)) {
            lName.set("v.errors", [{message:"Family Name is required"}]);
            arrErrors.push('missing family name');
            isValid = false;
        } else if (lNameValue.length > 80) {
            lName.set("v.errors", [{message:"Family Name is too long"}]);
            arrErrors.push('family name too long');
            isValid = false;
        } else {
            this.clearErrors(component, "lName");
        }

        var prevSurname = component.get("v.userRec.App_Previous_Surname__c");
        if (this.isFieldPopulated(prevSurname)) {
            if (prevSurname.length > 100) {
                prevSurname.set("v.errors", [{message:"Previous Family Name is too long"}]);
                arrErrors.push('previous family name too long');
                isValid = false;
            }
        }

        var GenderOptions = component.find("GenderOptions");
        if (!this.isFieldPopulated(component.get("v.userRec.App_Gender__c"))) {
            GenderOptions.set("v.errors", [{message:"Gender is required"}]);
            arrErrors.push('missing gender');
            isValid = false;
        } else {
            this.clearErrors(component, "GenderOptions");
        }

        /* 2018/09/07 moved to Personal Details Page
        var campusOfStudyOptions = component.find("campusOfStudyOptions");
        if (!this.isFieldPopulated(component.get("v.campusOfStudy"))) {
            campusOfStudyOptions.set("v.errors", [{message:"Location/Campus of Study is required"}]);
            isValid = false;
        } else {
            this.clearErrors(component, "campusOfStudyOptions");
        }
        */

        //Date of Birth validation
        var regDateFormat = /^\d{4}[\-\/\s]?((((0[13578])|(1[02]))[\-\/\s]?(([0-2][0-9])|(3[01])))|(((0[469])|(11))[\-\/\s]?(([0-2][0-9])|(30)))|(02[\-\/\s]?[0-2][0-9]))$/;
        var selectedBdate = component.get("v.selectedDOB");

        
        if (!this.isFieldPopulated(selectedBdate)) {
            component.set("v.dobError", "Date of Birth is required");
            $A.util.addClass(component.find("bday"), 'dateError');
            component.set("v.invalidDate", true);
            
            arrErrors.push('missing DOB');
            isValid = false;
        } else if (!selectedBdate.match(regDateFormat)) {
            component.set("v.dobError", "Please enter a valid date (dd/mm/yyyy).");
            $A.util.addClass(component.find("bday"), 'dateError');
            component.set("v.invalidDate", true);
            arrErrors.push('invalid DOB');
            isValid = false; 
        } else if (selectedBdate != null) {
            selectedBdate = new Date(selectedBdate.split("-")[0], selectedBdate.split("-")[1]-1, selectedBdate.split("-")[2]);
            var dateNow = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());
            if(selectedBdate > dateNow){
                component.set("v.dobError", "Please check your year of birth - you have entered a future date");
                $A.util.addClass(component.find("bday"), 'dateError');
                component.set("v.invalidDate", true);
                arrErrors.push('future DOB');
                isValid = false;
            }
        } else {
            $A.util.removeClass(component.find("bday"), 'dateError');
            component.set("v.dobError", "");
            component.set("v.invalidDate", false);
        }

        //Email Validation
        var email = component.find("email");
        var emailContent = component.get("v.userRec.Email");
        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        
        
        if (!this.isFieldPopulated(emailContent)) {
            email.set("v.errors", [{message:"Email is required"}]);
            arrErrors.push('missing email');
            isValid = false;
        } else if (!emailContent.match(regExpEmailformat)) {
            email.set("v.errors", [{message: "Please enter a valid email address"}]);
            arrErrors.push('invalid email');
            isValid = false;
        } else {
            this.clearErrors(component, "email");
        }

        var mobile = component.get("v.userRec.MobilePhone");
        var workPhone = component.get("v.userRec.Phone");
        var homePhone = component.get("v.userRec.App_Home_Phone__c");
        if (this.isFieldPopulated(mobile) && mobile.toString().length > 20) {
            mobile.set("v.errors", [{message:"Mobile is too long"}]);
            arrErrors.push('mobile too long');
            isValid = false;
        }

        if (this.isFieldPopulated(workPhone) && workPhone.toString().length > 20) {
            workPhone.set("v.errors", [{message:"Work Phone is too long"}]);
            arrErrors.push('work phone too long');
            isValid = false;
        }

        if (this.isFieldPopulated(homePhone) && homePhone.toString().length > 20) {
            homePhone.set("v.errors", [{message:"Home Phone is too long"}]);
            arrErrors.push('home phone too long');
            isValid = false;
        }

        var street = component.find("street");
        var streetValue = component.get("v.userRec.Street");
        if (!this.isFieldPopulated(streetValue)) {
            street.set("v.errors", [{message:"Street Number and Street is required"}]);
            arrErrors.push('missing street number and name');
            isValid = false;
        } else if (streetValue.length > 40) {
            street.set("v.errors", [{message:"Street Number and Street is too long"}]);
            arrErrors.push('street number and name too long');
            isValid = false;
        } else {
            this.clearErrors(component, "street");
        }

        if (component.get("v.isPostalAustralia") == "Yes") {
            var city = component.find("city");
            var cityValue = component.get("v.userRec.City");
            if (!this.isFieldPopulated(cityValue)) {
                city.set("v.errors", [{message:"Suburb/Town is required"}]);
                arrErrors.push('missing suburb/town');
                isValid = false;
            } else if (cityValue.length > 40) {
                city.set("v.errors", [{message:"Suburb/Town is too long"}]);
                arrErrors.push('suburb/town too long');
                isValid = false;
            } else {
                this.clearErrors(component, "city");
            }

            var StateOptions = component.find("StateOptions");
            if (!this.isFieldPopulated(component.get("v.selectedState"))) {
                StateOptions.set("v.errors", [{message:"State is required"}]);
                arrErrors.push('missing state');
                isValid = false;
            } else {
                this.clearErrors(component, "StateOptions");
            }

            var postal = component.find("postal");
            if (!this.isFieldPopulated(component.get("v.selectedPostCode"))) {
                postal.set("v.errors", [{message:"Postal code is required"}]);
                arrErrors.push('missing post code');
                isValid = false;
            } else {
                this.clearErrors(component, "postal");
            }

        } else {
            var countryOptions = component.find("countryOptions");
            if (!this.isFieldPopulated(component.get("v.userRec.Country"))) {
                countryOptions.set("v.errors", [{message:"Country is required"}]);
                arrErrors.push('missing country');
                isValid = false;
            } else {
                this.clearErrors(component, "countryOptions");
            }

            var osStateValue = component.get("v.selectedOSstate");
            if (this.isFieldPopulated(osStateValue)) {
                if (osStateValue.length > 40) {
                    city.set("v.errors", [{message:"State/Region is too long"}]);
                    arrErrors.push('state/region too long');
                    isValid = false;
                }
            }
            var osPostalCode = component.get("v.selectedOSPostalCode");
            var ospostal = component.find("ospostal");
            if (this.isFieldPopulated(osPostalCode)) {
                if (osPostalCode.length > 10) {
                    ospostal.set("v.errors", [{message:"Postal Code is too long"}]);
                    arrErrors.push('postal code too long');
                    isValid = false;
                } else {
                    this.clearErrors(component, "ospostal");
                }
            }
        }

        var addressType = component.find("addressType");
        if (!this.isFieldPopulated(component.get("v.isPostalAustralia"))) {
            addressType.set("v.errors", [{message:"Address Type is required"}]);
            arrErrors.push('missing address type');
            isValid = false;
        } else {
            this.clearErrors(component, "addressType");
        }

        var atsiOptions = component.find("atsiOptions");
        var selectedATSI = component.get("v.selectedATSI");
        
        if (!this.isFieldPopulated(selectedATSI) && component.get("v.userRec.App_Residency_Status__c") == 'DOM-AUS') 
        {
            atsiOptions.set("v.errors", [{message:"Access and Equity Detail is required"}]);
            arrErrors.push('missing ATSI for domestic');
            isValid = false;
        } else {
            this.clearErrors(component, "atsiOptions");
        }

        if (!this.isTheApplicantDomestic(component.get("v.userRec.App_Residency_Status__c"))) {
            firstRadioButton = component.find("disabilityRadioButtonNoID");
            isFirstRadioButtonChecked = firstRadioButton.get("v.value");
            secondRadioButton = component.find("disabilityRadioButtonYesID");
            isSecondRadioButtonChecked = secondRadioButton.get("v.value");

            //set the readOnly buttons
            readOnlyNoRadioButton = component.find("rOnlyRadButNoId");
            readOnlyNoRadioButton.set("v.value", isFirstRadioButtonChecked);
            readOnlyYesRadioButton = component.find("rOnlyRadButYesId");
            readOnlyYesRadioButton.set("v.value", isSecondRadioButtonChecked);


            if(!isFirstRadioButtonChecked && !isSecondRadioButtonChecked){
                document.getElementById("disabilityErrorMessageUlId").style.display = "block";
                arrErrors.push('radio buttons error');
                isValid = false;
            } else {
                document.getElementById("disabilityErrorMessageUlId").style.display = "none";
            }
        }

        if (!this.validatePreviousStudentId(component)){
            arrErrors.push('invalid previous student id');
        	isValid = false;
        }

        if (isValid) {
        	component.set("v.hasErrors", false);
        } else {
        	component.set("v.hasErrors", true);
            
            console.error('applicationPortalHelper::form validation errors');
            for(var i = 0; i <arrErrors.length; ++i)
            {
                console.debug(i + ':' + arrErrors[i]);
            }
            console.error('applicationPortalHelper::form validation errors end');
        }
        
        console.debug('applicationPortalHelper::validateForm() end isValid='+isValid);
    },
    
    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         18/05/2018
    * @description  return true if the applicant is domestic
    * @revision     
    *******************************************************************************/
    isTheApplicantDomestic: function(citizenshipTypeCode)
    {
        console.log(citizenshipTypeCode);
        if(citizenshipTypeCode == 'INTRNTNL' || citizenshipTypeCode == 'INT-TEP')
            return false;
        return true;
    },

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  retrieve the user details
    * @revision     Ant Custodio, 5.Apr.2018 - commented out temp storing of Monash Ids
    *******************************************************************************/
	retrieveUserRecord : function(component, helper) {
        
        var objHelper = this;
        
        var action_retrieveUser = component.get("c.retrieveUserDetails");
        action_retrieveUser.setCallback(this, function(a) {
            var userRecord = a.getReturnValue();            
            component.set("v.userRec", userRecord);
            console.log('userRecord:' + userRecord);    

            //sets to edit mode if birthdate is null
            if (userRecord.App_Birthdate__c == null) {
                component.set("v.isEdit", true);
            } else {
                component.set("v.selectedDOB", userRecord.App_Birthdate__c);
                component.set("v.selectedDOB_ReadOnly", userRecord.App_Birthdate__c);
            }

            //sets the gender
            var selectedGender = '';
            if (userRecord.App_Gender__c == 'M') {
                selectedGender = 'Male';
            } else if (userRecord.App_Gender__c == 'F') {
                selectedGender = 'Female';
            } else if (userRecord.App_Gender__c == 'X') {
                selectedGender = 'Indeterminate / Intersex / Unspecified';
            }
            component.set("v.selectedGender", selectedGender);

            //sets the citizenship
            component.set("v.Citizenship", userRecord.App_Citizenship__c);
            component.set("v.CitizenshipType", userRecord.App_Residency_Status__c);            
            
            if (userRecord.App_Citizenship__c == 'INTERNATIONAL') 
            {
                component.set("v.DomesticApplicant", false);
            }   
            else if (userRecord.App_Citizenship__c == 'DOMESTIC')
            {
                component.set("v.DomesticApplicant", true);
            }
            objHelper.populateCitizenshipType(component, objHelper);

            //sets the ATSI
            var selectedATSI = '';
            if (userRecord.App_Aboriginal_or_Torres_Strait_Islander__c == 'Yes') {
                selectedATSI = 'Yes';
            } else if (userRecord.App_Aboriginal_or_Torres_Strait_Islander__c == 'No') {
                selectedATSI = 'No';
            }
            component.set("v.selectedATSI", selectedATSI);

            //set the isPostalAustralia
            var isPostalAustralia = '';
            if (userRecord.App_Address_Type__c == 'POSTAL') {
                isPostalAustralia = 'Yes';
            } else if (userRecord.App_Address_Type__c == 'OS-POSTAL') {
                isPostalAustralia = 'No';
            }
            component.set("v.isPostalAustralia", isPostalAustralia);

            //set postcode
            component.set("v.selectedPostCode", userRecord.PostalCode);

            
            if (isPostalAustralia == 'Yes') {
                //set the state
                component.set("v.selectedState", userRecord.State); 
                //set the postcode
                component.set("v.selectedPostCode", userRecord.PostalCode);
            } else if (isPostalAustralia == 'No') {
                //set the state
                component.set("v.selectedOSstate", userRecord.State); 
                //set the postcode
                component.set("v.selectedOSPostalCode", userRecord.PostalCode);
            }


            //set the disablitiy options
            //if (userRecord.App_Citizenship__c == 'INTERNATIONAL' && userRecord.App_HasDisabilities__c == 'Yes') {
            if (userRecord.App_HasDisabilities__c == 'Yes') 
            {
                component.set("v.userRec.App_HasDisabilities__c", 'Yes');
                yesRadioButton = component.find("disabilityRadioButtonYesID");
                yesRadioButton.set("v.value", true);
                noRadioButton = component.find("disabilityRadioButtonNoID");
                noRadioButton.set("v.value", false);

                //set the readOnly buttons                
                readOnlyNoRadioButton = component.find("rOnlyRadButNoId");
                readOnlyNoRadioButton.set("v.value", false);
                readOnlyYesRadioButton = component.find("rOnlyRadButYesId");
                readOnlyYesRadioButton.set("v.value", true);

            } 
            else if (userRecord.App_HasDisabilities__c == 'No') 
            {   
                component.set("v.userRec.App_HasDisabilities__c", 'No');
                yesRadioButton = component.find("disabilityRadioButtonYesID");
                yesRadioButton.set("v.value", false);
                noRadioButton = component.find("disabilityRadioButtonNoID");
                noRadioButton.set("v.value", true);
                
                //set the readOnly buttons
                readOnlyNoRadioButton = component.find("rOnlyRadButNoId");
                readOnlyNoRadioButton.set("v.value", true);
                readOnlyYesRadioButton = component.find("rOnlyRadButYesId");
                readOnlyYesRadioButton.set("v.value", false);
            }
            /*******************************************************************************
            * @author       Ant Custodio
            * @date         5.Apr.2017         
            * @description  check if the student is a previoius student
            * @revision     
            *******************************************************************************/
            if (userRecord.App_Previously_Studied_at_Monash__c) {
                // first get the div element. by using aura:id
                var changeElement = component.find("DivID");
                // by using $A.util.toggleClass add-remove slds-hide class
                $A.util.removeClass(changeElement, "slds-hide");
            }
            
            this.finishedLoad(component, 'retrieveUser');
            // removed the retrieve by name
        });
        
        this.incrementLoad(component, 'retrieveUser');
        $A.enqueueAction(action_retrieveUser);
	},
    
    retrieveCTByName:function(component)
    {
        // 2018/09/12 unused, but kept here for reference
            console.log('applicationPortalHelper:: citizenship = ' + userRecord.App_Citizenship__c);
            console.log('applicationPortalHelper:: residency = ' + userRecord.App_Residency_Status__c );
            action_retrieveCTByName = component.get("c.retrieveCitizenshipTypeByName");
            action_retrieveCTByName.setParams({ "ctName"   : userRecord.App_Residency_Status__c });
            action_retrieveCTByName.setCallback(this, function(a) {
                if (a.getReturnValue().Explanation__c != null && a.getReturnValue().Explanation__c != '') {
                    //component.set("v.campusOfStudy", a.getReturnValue().Campus_of_Study__c);
                }
                
                component.set("v.CitizenshipType", a.getReturnValue().Explanation__c);
                console.log('11111111' + a.getReturnValue().Explanation__c)
                //set the citizenship type
                console.log('equal INTERNATIONAL 53-+ ' + userRecord.App_Citizenship__c);

                if (userRecord.App_Citizenship__c == 'INTERNATIONAL') {
                    //document.getElementById("AccessAndEquityDomesticDivId").style.display = "none";
                    //document.getElementById("AccessAndEquityInternationalDivId").style.display = "block";
                    component.set("v.DomesticApplicant", false);
                } 
                
                if (userRecord.App_Citizenship__c == 'DOMESTIC'){
                    console.log('appPortalHelper::equal INTERNATIONAL 54* ' + userRecord.App_Citizenship__c);
                    component.set("v.DomesticApplicant", true);
                    //document.getElementById("AccessAndEquityDomesticDivId").style.display = "block";
                    //document.getElementById("AccessAndEquityInternationalDivId").style.display = "none";
                }

                console.log('equal INTERNATIONAL 55 ' + userRecord.App_Citizenship__c);
                component.set("v.CitizenshipType", a.getReturnValue().Explanation__c);
                //component.set("v.Citizenship", userRecord.App_Citizenship__c);


                //disable some personal details if there is already a submitted application
                var action_disableFields = component.get("c.hasSubmittedApplication");
                action_disableFields.setParams({ "contactId"   : userRecord.ContactId });
                action_disableFields.setCallback(this, function(a) {
                    component.set("v.isDisabled", a.getReturnValue());
                    
                    component.set("v.disableEditing", a.getReturnValue());
                });
                $A.enqueueAction(action_disableFields); 
            });
            $A.enqueueAction(action_retrieveCTByName);
    }, 

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  retrieve the picklist values
    * @revision     
    *******************************************************************************/
    retrieveYESNOPicklistValues : function(inputsel) {
        var opts=[];
        opts.push({"class": "optionClass", label: "--Select--", value: ""});
        opts.push({"class": "optionClass", label: "Yes", value: "Yes"});
        opts.push({"class": "optionClass", label: "No", value: "No"});
        inputsel.set("v.options", opts);
    }, 

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  retrieve the picklist values
    * @revision     
    *******************************************************************************/
	retrievePicklistValues : function(actionToRun, inputsel) {
        var opts=[];
        actionToRun.setCallback(this, function(a) {
            opts.push({"class": "optionClass", label: "--Select--", value: ""});
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputsel.set("v.options", opts);

        });
        $A.enqueueAction(actionToRun); 
	}, 

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  retrieve the picklist values
    * @revision     
    *******************************************************************************/
    retrievePicklistValuesv2 : function(actionToRun, inputsel, campusOfStudy) {
        var opts=[];
        actionToRun.setParams({ "campusOfStudy"   : campusOfStudy });
        actionToRun.setCallback(this, function(a) {
            opts.push({"class": "optionClass", label: "--Select--", value: ""});
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i].split("~")[1], value: a.getReturnValue()[i].split("~")[0]});
            }
            inputsel.set("v.options", opts);

        });
        $A.enqueueAction(actionToRun); 
    }, 

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  clears a specific field error
    * @revision     
    *******************************************************************************/
    clearErrors : function(component, auraId) {
        var foundComponent = component.find(auraId);
        if (foundComponent != null) {
            foundComponent.set("v.errors", null);
        }
    },

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         28.Mar.2018      
    * @description  is previous monash Id valid or not
    * @revision     Ant Custodio, 4/Apr/2018 - Added return statement so that it knows	
						when to return an error on the page
    *******************************************************************************/
    validatePreviousStudentId : function(component) {
        var foundComponent = component.get("v.userRec.App_Previous_Monash_ID__c");
        var isValid = true;
        
        if (foundComponent != null) {
            
            if (foundComponent.toString() == "")
            {
                component.find("studentid").set("v.errors", null);
                this.clearErrors(component, "studentid");
            }
            else if(foundComponent.toString().length != 8)
            {
                component.find("studentid").set("v.errors", [{message:"Previous Student Id is not valid. This must be an 8 digit number. If you don't remember your Id please leave this field blank."}]);
                isValid = false;
            }
            else if (isNaN(foundComponent))
            {
                component.find("studentid").set("v.errors", [{message:"Previous Student Id is not valid. This must be an 8 digit number. If you don't remember your Id please leave this field blank."}]);
                isValid = false;
            }
            else
            {
                component.find("studentid").set("v.errors", null);
                this.clearErrors(component, "studentid");
            }
        }
        console.log('isValid: ' + isValid);
        console.log('isNaN: ' + isNaN(foundComponent));
        return isValid;
    },

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  clears all form errors
    * @revision     
    *******************************************************************************/
	clearAllErrors : function(component) {
        
		this.clearErrors(component, "salutationOptions");
		this.clearErrors(component, "lName");
		this.clearErrors(component, "GenderOptions");
        this.clearErrors(component, "campusOfStudyOptions");
		//this.clearErrors(component, "bdayError");
		this.clearErrors(component, "email");
		this.clearErrors(component, "studentid");
        this.clearErrors(component, "CitizenshipTypeOptions");
        this.clearErrors(component, "street");
        this.clearErrors(component, "city");
        this.clearErrors(component, "StateOptions");
        this.clearErrors(component, "osState");
        this.clearErrors(component, "postal");
        this.clearErrors(component, "ospostal");
        this.clearErrors(component, "countryOptions");
        this.clearErrors(component, "addressType");
        this.clearErrors(component, "atsiOptions");

        component.set("v.errorMessage", "");
        component.set("v.dobError", "");
        
        $A.util.removeClass(component.find("bday"), 'dateError');
        component.set("v.initializeDatePicker", true);
	},

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         3.Apr.2017         
    * @description  saves the user reord
    * @revision     
    *******************************************************************************/
    updateUser : function (component, event, helper, goHome) {
        var action = component.get("c.updateUserRecord");
        var userRec = component.get("v.userRec");

        this.incrementLoad(component, 'updateUser');
        console.log('applicationPortalHelper::updateUser - ' + userRec);
        //console.log(userRec);
        //
        var appId = component.get("v.appId");
        action.setParams({ 
            "userRec": userRec ,
            "applicationId": appId
        });
        var mobile = component.find("mobile");
        var phone = component.find("phone");
        var homephone = component.find("homephone");
        var bday = component.find("bdayError");

        if (!component.get("v.invalidDate")) {
            var selectedBdate = component.get("v.selectedDOB");

            if (selectedBdate != null) {
                selectedBdate = new Date(selectedBdate.split("-")[0], selectedBdate.split("-")[1]-1, selectedBdate.split("-")[2]);
                var date16YearsBack = new Date(new Date().getFullYear()-16, new Date().getMonth(), new Date().getDate());
                if (selectedBdate >= date16YearsBack) {
                    if (!component.get("v.isAgeAcknowledged")) {
                        component.set("v.showAgeCheckPopup", true);
                    }
                } else {
                    component.set("v.isAgeAcknowledged", true);
                }
            } else {
                component.set("v.invalidDate", true);
            }
        } else {
            component.set("v.invalidDate", true);
        }

        // Added by Majid Reisi Dehkordi
        if (!this.validatePreviousStudentId(component)) 
        {
            console.error('applicationPortalHelper::validatePreviousStudentId failed');
        	component.set("v.hasErrors", true);
        }
        if (component.get("v.isAgeAcknowledged") || component.get("v.invalidDate")) {
            component.set("v.showAgeCheckPopup", false);            
            this.validateForm(component);
            var hasError = component.get("v.hasErrors");
            
            if(hasError)
            {
                console.error('applicationPortalHelper:: form validation errors');
            }
        
            if (    !this.isFieldPopulated(component.get("v.userRec.MobilePhone")) &&
                    !this.isFieldPopulated(component.get("v.userRec.Phone")) &&
                    !this.isFieldPopulated(component.get("v.userRec.App_Home_Phone__c")) 
                ) {
                mobile.set("v.errors", [{message:"At least 1 phone number is required"}]);
                phone.set("v.errors", [{message:"At least 1 phone number is required"}]);
                homephone.set("v.errors", [{message:"At least 1 phone number is required"}]);
                
                console.error('applicationPortalHelper::no phone number provided');
                hasError = true;
            } else {
                mobile.set("v.errors", null);
                phone.set("v.errors", null);
                homephone.set("v.errors", null);
            }
            
            if (!hasError) {
                var postal = component.find("postal");
                //only validate postcode if in Australia
                var selectedPostCode = component.get("v.selectedPostCode");
                if (component.get("v.isPostalAustralia") == "Yes") {
                    if (selectedPostCode.length == 4) {
                        
                        var postCodeCheck = component.get("c.findPostCodeNumber");
                        postCodeCheck.setParams({ "postCode" : selectedPostCode });
                    
                        postCodeCheck.setCallback(this, function(a) {
                            var state = a.getState();
                            if (state === "ERROR") {
                                var errors = a.getError();
                                if (errors) {
                                    if (errors[0] && errors[0].message) {
                                        console.log("Error message: " + 
                                                 errors[0].message);
                                        component.set("v.errorMessage", "An Unexpected error has occured. Please contact your Administrator.");
                                    }
                                } else {
                                    console.log("Unknown error");
                                }
                            } 
                            else {
                                if (!a.getReturnValue()) {
                                    postal.set("v.errors", [{message:"The Postcode entered is not a valid Australian Postcode"}]);
                                    hasError = true;
                                } else {
                                    action.setCallback(this, function(response) {
                                        var state = response.getState();
                                        // display a message to your user, prompting them to close
                                        // the action modal
                                        if(state === 'SUCCESS'){
                                            var home = component.get("v.homeRedirect");
                                            this.routeUserOnSuccess(home);
                                        }

                                        if (state === "ERROR") {
                                            var errors = response.getError();
                                            if (errors) {
                                                if (errors[0] && errors[0].message) {
                                                    console.log("Error message: " + 
                                                             errors[0].message);
                                                    component.set("v.errorMessage", "An Unexpected error has occured. Please contact your Administrator.");
                                                }
                                            } else {
                                                console.log("Unknown error");
                                            }
                                        } else {
                                            component.set("v.isEdit", false);
                                        }
                                    });
                                }
                            }
                        });
                        $A.enqueueAction(postCodeCheck);
                        
                    } else {
                        postal.set("v.errors", [{message:"The Postcode entered is not a valid Australian Postcode"}]);
                        console.error('applicationPortalHelper::invalid Aus postcode');
                        hasError = true;
                    }
                } 
                else {
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        // display a message to your user, prompting them to close
                        // the action modal
                        if(state === 'SUCCESS'){
                            var home = component.get("v.homeRedirect");
                            this.routeUserOnSuccess(home);
                        }

                        if (state === "ERROR") {
                            var errors = response.getError();
                            if (errors) {
                                if (errors[0] && errors[0].message) {
                                    console.log("Error message: " + 
                                             errors[0].message);
                                    component.set("v.errorMessage", "An Unexpected error has occured. Please contact your Administrator.");
                                }
                            } else {
                                console.log("Unknown error");
                            }
                        } else {
                            component.set("v.isEdit", false);
                        }
                    });
                }
                //console.log('applicationPortalHelper::no postal code errors');
            }

            if (!hasError) {
                if (component.get("v.isPostalAustralia") == "Yes") {
                    //set the State
                    component.set("v.userRec.State", component.get("v.selectedState"));
                    //set the PostCode
                    component.set("v.userRec.PostalCode", component.get("v.selectedPostCode"));
                } else if (component.get("v.isPostalAustralia") == "No") {
                    //set the State if overseas
                    component.set("v.userRec.State", component.get("v.selectedOSstate"));
                    //set the postcode if overseas
                    component.set("v.userRec.PostalCode", component.get("v.selectedOSPostalCode"));
                }
                //sets the birthdate
                component.set("v.userRec.App_Birthdate__c", component.get("v.selectedDOB"));
                //set the citizenship type
                this.populateCitizenshipType(component);
                //set the ATSI
                component.set("v.userRec.App_Aboriginal_or_Torres_Strait_Islander__c", component.get("v.selectedATSI"));
                component.set("v.errorMessage", '');
                component.set("v.hasErrors", false);
                $A.util.removeClass(component.find("bday"), 'dateError');
                //clear all errors
                this.clearAllErrors(component);

                $A.enqueueAction(action);

            } else {
                component.set("v.errorMessage", 'There are errors on your page. Please review your form.');
                //window.scrollTo(0, 0);
            }
        }

        this.finishedLoad(component, 'updateUser');

    },

    routeUserOnSuccess : function(goHome)
    {
        var urlEvent = $A.get("e.force:navigateToURL");
        if(goHome){
            urlEvent.setParams({
                "url": '/',
                "isredirect" :false
            });
        }else{
            urlEvent = $A.get("e.force:refreshView");
        }
        urlEvent.fire();
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         28.Apr.2017         
    * @description  clear the error on change
    * @revision     
    *******************************************************************************/
    clearError_onChange: function(component, event) {
        var eventSource = event.getSource();
        var auraId = eventSource.getLocalId();
        this.clearErrors(component, auraId);
        window.location.hash = '#'+auraId;
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         6.Jun.2017         
    * @description  validates the field if its populated
    * @revision     
    *******************************************************************************/
    isFieldPopulated: function(fieldToValidate) {
        var isValid = true;
        if (fieldToValidate == null) {
            isValid = false;
        } else {
            fieldToValidate = fieldToValidate.replace(new RegExp(' ', 'g'),"");
            if (fieldToValidate == '') {
                isValid = false;
            }
        }

        return isValid;
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         5.Apr.2017         
    * @description  remove the values when value is set to no
    * @revision     
    *******************************************************************************/
    removeValuesIfFalse: function(component) {
        var action_removeValuesIfFalse = component.get("c.removeValuesWhenUnticked");
        var userRec = component.get("v.userRec");
        action_removeValuesIfFalse.setParams({"userToUpdate": userRec});
        action_removeValuesIfFalse.setCallback(this, function(c) {
            component.set("v.userRec", c.getReturnValue());
        });
        
        $A.enqueueAction(action_removeValuesIfFalse);
    },  

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         5.Apr.2017         
    * @description  validate the date of birth
    * @revision     
    *******************************************************************************/
    validateDOB: function(component) {
        //Date of Birth validation
        var regDateFormat = /^\d{4}[\-\/\s]?((((0[13578])|(1[02]))[\-\/\s]?(([0-2][0-9])|(3[01])))|(((0[469])|(11))[\-\/\s]?(([0-2][0-9])|(30)))|(02[\-\/\s]?[0-2][0-9]))$/;
        //var regDateFormat = /^(?:(?:31(\/|-|\.)(?:0?[13578]|1[02]))\1|(?:(?:29|30)(\/|-|\.)(?:0?[1,3-9]|1[0-2])\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})$|^(?:29(\/|-|\.)0?2\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\d|2[0-8])(\/|-|\.)(?:(?:0?[1-9])|(?:1[0-2]))\4(?:(?:1[6-9]|[2-9]\d)?\d{2})$/;
        var selectedBdate = component.get("v.selectedDOB");

        $A.util.removeClass(component.find("bday"), 'dateError');
        component.set("v.dobError", "");
        component.set("v.invalidDate", false);

        if (!this.isFieldPopulated(selectedBdate)) {
            component.set("v.dobError", "Date of Birth is required");
            $A.util.addClass(component.find("bday"), 'dateError');
            component.set("v.invalidDate", true);
        } else if (!selectedBdate.match(regDateFormat)) {
            component.set("v.dobError", "Please enter a valid date (dd/mm/yyyy).");
            $A.util.addClass(component.find("bday"), 'dateError');
            component.set("v.invalidDate", true);
        } else if (selectedBdate != null) {
            selectedBdate = new Date(selectedBdate.split("-")[0], selectedBdate.split("-")[1]-1, selectedBdate.split("-")[2]);
            var dateNow = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());
            var earliestDate = new Date(new Date().getFullYear()-99, new Date().getMonth(), new Date().getDate());
        

            if(selectedBdate > dateNow){
                component.set("v.dobError", "Please check your year of birth - you have entered a future date");
                $A.util.addClass(component.find("bday"), 'dateError');
                component.set("v.invalidDate", true);
            } else if(selectedBdate <= earliestDate) {
                component.set("v.dobError", "Please check your year of birth.");
                $A.util.addClass(component.find("bday"), 'dateError');
                component.set("v.invalidDate", true);
            }
        } 
        component.set("v.isAgeAcknowledged", false);
    },  

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         6.Jun.2017         
    * @description  populates the gender field
    * @revision     
    *******************************************************************************/
    populateGender: function(component) {
        var dynamicCmp = component.find("GenderOptions");
        var selectedGender = '';

        if (dynamicCmp.get("v.value") == 'Male') {
            selectedGender = 'M';
        } else if (dynamicCmp.get("v.value") == 'Female') {
            selectedGender = 'F';
        } else if (dynamicCmp.get("v.value") == 'Indeterminate / Intersex / Unspecified') {
            selectedGender = 'X';
        }
        component.set("v.selectedGender", dynamicCmp.get("v.value"));
        component.set("v.userRec.App_Gender__c", selectedGender);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  populates citizenship type code on the backend
    * @revision     
    *******************************************************************************/
   populateCitizenshipType : function(component, helper) {
       var citizenshipType = component.get("v.CitizenshipType");
        
       var ARR_DOMESTIC_CODES = ['DOM-AUS','DOM-NZ','DOM-PR','DOM-HV'];
       var ARR_INTL_CODES = ['INTRNTNL', 'INT-TEP'];       
       if(ARR_DOMESTIC_CODES.indexOf(citizenshipType) >= 0)
       {
           component.set("v.userRec.App_Citizenship__c", 'DOMESTIC');                      
       }
       else if(ARR_INTL_CODES.indexOf(citizenshipType) >= 0)
       {
           component.set("v.userRec.App_Citizenship__c", 'INTERNATIONAL');           
       }
       else
       {
           component.set("v.userRec.App_Citizenship__c", null);	                   
       }
       
       // only show ATSI for DOM-AUS
       component.set("v.showATSI", false);
       if(citizenshipType == 'DOM-AUS')
       {
           component.set("v.showATSI", true);
       }
       else
       {
           // clear ATSI selections
           component.set("v.selectedATSI", null);
       }
       
       // this field is the code, eg DOM-AUS
       component.set("v.userRec.App_Residency_Status__c", citizenshipType);
        
        return citizenshipType;
    },

    /*******************************************************************************
    * @author       Majid Resis Dehkordi
    * @date         6.Jun.2017         
    * @description  show the right access and equity text based on being domestic or not
    * @revision     Majid Reisi Dehkordi
    *               18/05/2017 Hide the Access and Equity Details
    *               for domestics
    *******************************************************************************/
    showAndHideAccessAndEquity: function(component, helper) {

        component.set("v.showATSI", false);
        switch(helper.populateCitizenshipType(component, helper)) {
            case '':
                //document.getElementById("AccessAndEquityDomesticDivId").style.display = "none";
                //document.getElementById("AccessAndEquityInternationalDivId").style.display = "none";
                
                break;
            case 'INTRNTNL':
                //document.getElementById("AccessAndEquityDomesticDivId").style.display = "none";
                //document.getElementById("AccessAndEquityInternationalDivId").style.display = "block";
                
                break;
            case 'INT-TEP':
                //document.getElementById("AccessAndEquityDomesticDivId").style.display = "none";
                //document.getElementById("AccessAndEquityInternationalDivId").style.display = "block";
                break;
            default:
                document.getElementById("AccessAndEquityDomesticDivId").style.display = "block";
                document.getElementById("AccessAndEquityInternationalDivId").style.display = "none";
        }
        //dynamicCmp.set("v.errors", [{message:""}]);
        //dynamicCmp.set("v.errors", null);
    },


    /*******************************************************************************
    * @author       Ant Custodio
    * @date         6.Jun.2017         
    * @description  populates the gender field
    * @revision     
    *******************************************************************************/
    populateAddressType: function(component) {
        var dynamicCmp = component.find("addressType");
        component.set("v.isPostalAustralia", dynamicCmp.get("v.value"));
        if (dynamicCmp.get("v.value") == "Yes") {
            component.set("v.userRec.App_Address_Type__c", "POSTAL");
        } else if (dynamicCmp.get("v.value") == "No") {
            component.set("v.userRec.App_Address_Type__c", "OS-POSTAL");
        }
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         6.Jun.2017         
    * @description  validates the Campus of Study field
    * @revision     
    *******************************************************************************/
    validateCampusOfStudy: function(component) {
        var campus = component.get('v.campusOfStudy');
        if(campus != 'Australia')
        {
            component.set("v.disableSave", true);
        }
        else
        {
            component.set("v.disableSave", false);
        }
        /*
        var dynamicCmp = component.find("campusOfStudyOptions");
        component.set("v.campusOfStudy", dynamicCmp.get("v.value"));
        component.set("v.CitizenshipType", "");
        var ctOptions = component.find("CitizenshipTypeOptions");
        ctOptions.set("v.errors", null);
        if (dynamicCmp.get("v.value") != 'Malaysian campus' && dynamicCmp.get("v.value") != 'South African campus') {
            //retrieve citizenship list
            //helper.retrievePicklistValuesv2(component.get("c.retrieveCitizenshipTypeOptions"), component.find("CitizenshipTypeOptions"), dynamicCmp.get("v.value"));
            component.set("v.disableSave", false);
            dynamicCmp.set("v.errors", null);
            component.set("v.hideDependendPicklist", false);
        } else {
            dynamicCmp.set("v.errors", [{message:""}]);
            component.set("v.disableSave", true);
            component.set("v.hideDependendPicklist", true);
        }
        */
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         6.Jun.2017         
    * @description  populates the ATSI field
    * @revision     
    *******************************************************************************/
    populateATSI: function(component) {
        var dynamicCmp = component.find("atsiOptions");
        if (dynamicCmp.get("v.value") == "Yes") {
            component.set("v.userRec.App_Aboriginal_or_Torres_Strait_Islander__c", "Yes");
        } else if (dynamicCmp.get("v.value") == "No") {
            component.set("v.userRec.App_Aboriginal_or_Torres_Strait_Islander__c", "No");
        }
        component.set("v.selectedATSI", dynamicCmp.get("v.value"));
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         12.Jun.2017         
    * @description  disable some fields if there is at least one 
                        submitted application
    * @revision     
    *******************************************************************************/
    disableFieldsOnSubmit : function(contactIdToUse) {
        var actionToRun = component.get("c.hasSubmittedApplication");
        actionToRun.setParams({ "contactId"   : contactIdToUse });
        actionToRun.setCallback(this, function(a) {
            component.set("v.isDisabled", a.getReturnValue());
        });
        $A.enqueueAction(actionToRun); 
    } 
    
    , initCampusLocationOptions:function(component)
    {
        // setup the campus location selection options
        var arrOptions = [
            {"value":"", "label":"choose one..."},
            {"value":"Australia", "label":"Australia"},
            {"value":"Malaysia", "label":"Malaysia"},
            {"value":"South Africa", "label":"South Africa"}
        ];
        component.set("v.locationOptions", arrOptions);
    }
    
    , initCitizenshipTypeOptions:function(component)
    {   
        // setup the citizenship type options
        var arrCitizenshipTypeOptions = [
            {"value":"", "label":"choose one..."},
            {"label": 'I am an Australian citizen (with or without dual citizenship)',
             "value": 'DOM-AUS'},
            {"label": 'I am a New Zealand citizen',
             "value": 'DOM-NZ'},
            {"label": 'I hold an Australian permanent resident visa',
             "value": 'DOM-PR'},
            {"label": 'I hold an Australian permanent humanitarian visa',
             "value": 'DOM-HV'},
            {"label": 'I hold or hope to hold an international student visa',
             "value": 'INTRNTNL'},
            {"label": 'I hold a non-student temporary visa (e.g. work or spouse visa)',
             "value": 'INT-TEP'}
        ];
        component.set("v.citizenshipTypeOptions", arrCitizenshipTypeOptions);
    }
})