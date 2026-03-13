/**
 * Created by trentdelaney on 31/8/18.
 */
({
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
    }
    
    , initLoad:function(component, helper, appId)
    {
        var actionInitLoad = component.get("c.initDataLoad");
        actionInitLoad.setParams({ "applicationId":appId});
        actionInitLoad.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS')
            {   
                var objResponse = response.getReturnValue();
                var objContact = objResponse.contact;
                
                if(objResponse.previous_applications > 0)
                {
                    component.set("v.citizenshipTypeLocked", true);
                }

                // visa type options
                this.setupPicklistWithDefault(component, 'v.visaOptions', objResponse.visaOptions);

                // this should be an application__c record
                var appResponse = objResponse.application;

                component.set("v.filteredCountryOptions", objResponse.countryOptions);
                component.set("v.filteredResidencyOptions", objResponse.residencyOptions);
                component.set("v.locationOptions", objResponse.campusLocations);
                if(appResponse)
                {
                    component.set("v.app", appResponse);

                	var campusLocation = appResponse.Campus_Location__c;
                    if(!campusLocation)
                    {
                        campusLocation = '';
                    }
                    component.set("v.campusLocation", campusLocation);
                    component.set("v.studyLocationSpinner", false);
                    component.set("v.typeOfStudy", appResponse.Type_of_Study__c);
                    component.set("v.residencyStatus", appResponse.Residency_Status__c);

                    if(appResponse.Applied_For_Permanent_Residency__c == true && appResponse.Type_of_Study__c == 'Graduate Research'){
                        component.set("v.applyForResidencyToggle", true);
                    }else{
                        component.set("v.applyForResidencyToggle", false);
                    }

                    this.initCitizenshipTypeOptions(component);

                    if(appResponse.Residency_Status__c){
                        if (appResponse.Residency_Sub_status__c != '' && appResponse.Residency_Sub_status__c != undefined){
                            appResponse.Residency_Status__c = appResponse.Residency_Sub_status__c;
                            component.set("v.citizenshipType", appResponse.Residency_Sub_status__c);
                        } else {
                            component.set("v.citizenshipType", appResponse.Residency_Status__c);
                        }
                        this.setVisibilityOfCitizenshipQuestions(component);
                        this.calculateVisaVisability(component)
                    }

                }
            }
        });
        $A.enqueueAction(actionInitLoad);
    },

    setupCountries : function(component, country)
    {
        var filteredCountries = component.get("v.filteredCountryOptions");
        if(country === 'Australia'){
            this.setupPicklistWithDefault(component, "v.countryOptions", filteredCountries['Australia']);
        }else if(country === 'Indonesia'){
            this.setupPicklistWithDefault( component, "v.countryOptions", filteredCountries['Indonesia'] );
        }else if(country === 'Malaysia'){
            this.setupPicklistWithDefault( component, "v.countryOptions", filteredCountries['Malaysia'] );
        }else if(country === 'South Africa'){
            this.setupPicklistWithDefault( component, "v.countryOptions", filteredCountries['South Africa']);
        }else if(country === 'Default'){
            this.setupPicklistWithDefault(component, "v.countryOptions", filteredCountries['Default']  );
        }
    },


    setupPicklistWithDefault : function ( component, cmpName, arrOptions )
    {
        var residencyStatus = component.get("v.app.Residency_Status__c");
        var country = component.get("v.campusLocation");
        if(arrOptions[0]){
            if(arrOptions[0].label !== '-- Select One --'){
                arrOptions.unshift({
                    'label': '-- Select One --'
                    , 'value' : ' '
                });
            }
        }
        var filteredArr = arrOptions;
         if( (country =='Indonesia' && residencyStatus !='DOM-IDN') ||
             (country =='Australia' && residencyStatus !='DOM-AUS') ||
             (country =='Malaysia' && residencyStatus !='DOM-SUN') ||
             (country =='South Africa' && residencyStatus !='INT-SA')
         )
         {   //filter out country as COC when Residency status is PR or other visa type other than Citizen
            // filter out Australia  as COC when Residency status=DOM-PR or !=citizen(!=DOM-AUS)
             filteredArr = arrOptions.filter(function(value, index, arr){ 
                return value.label != country && value.value!="INTRNTNL.O";
            });
         }
        component.set(cmpName, filteredArr);
    }

    , saveStudyLocation : function (component, appId, selection) {
        
        var action = component.get("c.SaveApplicationLocation");
        action.setParams({
            "appId" : appId,
            "campusLocation" : selection
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var objResponse = response.getReturnValue();
                var compEvent = component.getEvent("mapStudyLocation");
                compEvent.setParams({"picklist":selection});
                compEvent.fire();
                component.set("v.app.Campus_Location__c", selection);
                component.set("v.app.Residency_Status__c", objResponse.application.Residency_Status__c);
                component.set("v.filteredResidencyOptions", objResponse.options);
                this.initCitizenshipTypeOptions(component);
                this.calculateVisaVisability(component);
            }
        });

        $A.enqueueAction(action);
    },

    calculateVisaVisability : function(component, event, helper)
    {
        //Intialisation
        var map = {};
        map['country'] = false;
        map['type'] = false;
        map['office'] = false;
        map['visaNumber'] = false;
        map['passportNumber'] = false;
        map['startDate'] = false;
        map['endDate'] = false;
        map['refusedEntry'] = false;
        map['studentpass'] = false;
        map['appDate'] = false;
        map['appRes'] = false;
        map['passportNumberGRT'] = false;

        var studyLocation = component.get("v.campusLocation");
        var residencyType = component.get("v.app.Residency_Status__c");
        var typeOfStudy = component.get("v.typeOfStudy");
        if(typeOfStudy != 'Graduate Research'){
            if(studyLocation === 'Malaysia'){
                if(residencyType === 'DOM-SUN.B'){
                    map['country'] = true;
                }
                if(residencyType === 'INT-SUN' || residencyType === 'INT-SUN-A'){
                    map['country'] = true;
                    map['studentpass'] = true;
                    map['refusedEntry'] = true;
                }
                if(residencyType === 'INT-SUN-P'){
                    map['country'] = true;
                    map['visaNumber'] = true;
                    map['passportNumber'] = true;
                    map['startDate'] = true;
                    map['endDate'] = true;
                    map['refusedEntry'] = true;
                }
            }

            if(studyLocation === 'Australia'){
                if(residencyType === 'INTRNTNL.A' || residencyType === 'INT-TEP'){
                    map['country'] = true;
                    map['type'] = true;
                    map['office'] = true;
                    map['visaNumber'] = true;
                    map['passportNumber'] = true;
                    map['startDate'] = true;
                    map['endDate'] = true;
                    map['refusedEntry'] = true;
                }
                if(residencyType === 'INTRNTNL.B'){
                    map['country'] = true;
                    map['refusedEntry'] = true;
                }
                if(residencyType === 'DOM-PR'){
                    map['country'] = true;
                }
            }

        //indonesia
            if(studyLocation === 'Indonesia'){
                if(residencyType === 'DOM-IDN'){
                    //nothing shown
                }
                if(residencyType === 'DOM-IDN-PR'){
                    map['country'] = true;
                }
                if(residencyType === 'INT-IDN-P'){
                    map['country'] = true;
                    map['visaNumber'] = true;
                    map['passportNumber'] = true;
                    map['startDate'] = true;
                    map['endDate'] = true;
                    map['refusedEntry'] = true;
                }
                if (residencyType === 'INT-IDN'){
                    map['country'] = true;
                    map['studentpass'] = true;
                    map['refusedEntry'] = true;
                }
            }
        }

        if(typeOfStudy == 'Graduate Research'){
            if(residencyType === 'DOM-PR'){
                map['country'] = true;
                map['passportNumberGRT'] = true;
            }
            if(residencyType === 'DOM-SUN' || residencyType === 'DOM-IDN' ||
                residencyType === 'DOM-IDN-PR'){
                map['appRes'] = true
                map['appDate'] = true;
                map['passportNumberGRT'] = true;
            }
            if(residencyType === 'INTRNTNL'){
                map['country'] = true;
                map['appRes'] = true
                map['appDate'] = true;
                map['passportNumberGRT'] = true;
            }
            
        }
        
        component.set("v.visaQuestions", map);
    }
    
    , saveCitizenshipType:function(component, citizenshipType)
    {
        var appId = component.get("v.appId");
        var action = component.get("c.SaveApplicationCitizenship");
        action.setParams({
            "applicationId":appId,
            "citizenshipCode":citizenshipType            
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var urlEvent = $A.get("e.force:refreshView");
                //urlEvent.fire();
                component.set("v.app.Citizenship_Country__c", response.getReturnValue().Citizenship_Country__c);
                component.set("v.app.Visa_Type__c", response.getReturnValue().Visa_Type__c);
                component.set("v.app.Australian_Immigration_Office_Issued__c", response.getReturnValue().Australian_Immigration_Office_Issued__c);
                component.set("v.app.Visa_Number__c", response.getReturnValue().Visa_Number__c);
                component.set("v.app.Passport_Number__c", response.getReturnValue().Passport_Number__c);
                component.set("v.app.Visa_Start_Date__c", response.getReturnValue().Visa_Start_Date__c);
                component.set("v.app.Visa_End_Date__c", response.getReturnValue().Visa_End_Date__c);
                component.set("v.app.Refused_entry_visa_to_any_country__c", response.getReturnValue().Refused_entry_visa_to_any_country__c);
                component.set("v.app.Breached_visa_condition__c", response.getReturnValue().Breached_visa_condition__c);
                component.set("v.app.Medical_health_prevent_visa__c", response.getReturnValue().Medical_health_prevent_visa__c);
                component.set("v.app.Protection_visa_in_any_country__c", response.getReturnValue().Protection_visa_in_any_country__c);
                component.set("v.app.Convicted_of_crime_offence__c", response.getReturnValue().Convicted_of_crime_offence__c);
                component.set("v.app.Student_Pass_Availability__c", response.getReturnValue().Student_Pass_Availability__c);

                this.calculateVisaVisability(component);
                this.setVisibilityOfCitizenshipQuestions(component);
                component.set("v.studyLocationSpinner", false);
                if(component.get("v.typeOfStudy") == 'Graduate Research') {
                    var cmpEvent = component.getEvent("grStepsReset");
                    cmpEvent.setParams({ "stepName" : "Personal Details" });
                    cmpEvent.fire();
                }                
            }
        });

        $A.enqueueAction(action);
    }
    
    , setVisibilityOfCitizenshipQuestions:function(component)
    {
        var showQuestions = false;
        var citizenshipType = component.get("v.app.Residency_Status__c");
        switch(citizenshipType)
        {
            case 'INTRNTNL':
                showQuestions = true;
                this.setupCountries(component, 'Australia');
                break;
            case 'INT-TEP':
                showQuestions = true;
                this.setupCountries(component, 'Australia');
                break;
            case 'INT-SUN-P':
                this.setupCountries(component, 'Malaysia');
                break;
            case 'INT-SUN':
                this.setupCountries(component, 'Malaysia');
                break;
            default:
                this.setupCountries(component, 'Default');
                break;
        }
    }

    , clearACPRecords: function(component)
    {
        //Get AppId
        var appId = component.get("v.app.Id");

        var action = component.get("c.RemoveApplicationACPs");
        action.setParams({
            "appId":appId
        });
        action.setCallback(this, function(response){

        });

        $A.enqueueAction(action);
    }

    , checkForACPs : function (component) {
        var appId = component.get("v.appId");
        var action = component.get("c.CheckACP");
        action.setParams({
            "appId" : appId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                // KL SFTM-215, comment: save previous value to map in case of any reversion after modal dialog
                if(response.getReturnValue() === true){
                    component.set("v.showConfirmCancel", true);
                } else {
                    this.saveStudyLocation(component, appId, component.get("v.campusLocation"));
                }
            }
        });
        $A.enqueueAction(action);
    }
    , checkCitizenshipType:function(component)
    {
        component.set("v.applyForResidencyToggle", false);
        component.set("v.app.Passport_Number__c", '');
        component.set("v.app.PR_Application_Date__c", '');
    }

    /***** Start: KL SFTM-216 *****/
    , checkForACPsCitizenshipType : function (component) {
        var appId = component.get("v.appId");
        var action = component.get("c.CheckACP");
        action.setParams({
            "appId" : appId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                if(response.getReturnValue() === true){
                    component.set("v.showConfirmCancelCitizenshipType", true);
                } else {
                    component.set("v.app.Residency_Status__c", component.get("v.residencyStatus"))
                    this.saveCitizenshipType(component, component.get("v.residencyStatus"));
                }
            }
        });
        $A.enqueueAction(action);
    }
    /***** End: KL SFTM-216 *****/

    , saveCitizenshipQuestions: function (component)
    {

        var application = component.get("v.app");
        var action = component.get("c.saveCitizenshipQuestions");
        action.setParams({
            "application":application
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var objResponse = response.getReturnValue();
                if(objResponse.citizenshipErrors) {
                    component.set('v.showSpinner', false);
                    component.set('v.saveErrors', objResponse.citizenshipErrors);
                    component.set('v.showErrors', true);
                }else{
                    component.set('v.showSpinner', false);
                }
            }
            else if (state === 'ERROR'){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error('ApplicationStudyLocationHelper::saveCitizenshipErrors:' + errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
    
    , initCampusLocationOptions:function(component)
    {
        // setup the campus location selection options
        var arrOptions = [
            {"value":"", "label":"choose one..."},
            {"value":"Australia", "label":"Australia"},
            {"value":"Indonesia", "label":"Indonesia"},
            {"value":"Malaysia", "label":"Malaysia"},
            {"value":"South Africa", "label":"South Africa"}
        ];
        component.set("v.locationOptions", arrOptions);
    }
    
    , initCitizenshipTypeOptions:function(component)
    {
        var campus = component.get("v.campusLocation");
        var filteredStatus = component.get("v.filteredResidencyOptions");
        var typeOfStudy = component.get("v.typeOfStudy");
        if(typeOfStudy != 'Graduate Research'){
            if(campus === 'Australia'){
                this.setupPicklistWithDefault(component, "v.residencyOptions", filteredStatus['Australia']);
            }else if(campus === 'Indonesia'){
                this.setupPicklistWithDefault(component, "v.residencyOptions", filteredStatus['Indonesia']);
            }else if(campus === 'Malaysia'){
                this.setupPicklistWithDefault(component, "v.residencyOptions", filteredStatus['Malaysia']);
            }else if(campus  === 'South Africa'){
                this.setupPicklistWithDefault(component, "v.residencyOptions", filteredStatus['South Africa']);
            }
        }else{
            this.setupPicklistWithDefault(component, "v.residencyOptions", filteredStatus['GRT']);
        }
               
        component.set("v.studyLocationSpinner", false);
    },
    isUnsafe: function(dataObject) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g;
         return XML_REGEX_PATTERN.test(JSON.stringify(dataObject));
     }
});