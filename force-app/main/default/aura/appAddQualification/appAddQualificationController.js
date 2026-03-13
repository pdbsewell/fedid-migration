({
	doInit : function(component, event, helper)
    {
        console.debug('appAddQualificationController::doInit');

        component.set('v.saveErrors', []);
        
        var msInADay = 24 * 60 * 60 * 1000;
        
        var dateToday = new Date();        
        //var dateOffset = new Date(dateToday.getTime() - (msInADay));
        var sDateToday = helper.formatDateString(dateToday);
        component.set('v.EARLIEST_EXPECTED_DATE', sDateToday);        

        // today + 100 days
        var dateMax = new Date(dateToday.getTime() + (1 * msInADay));
        var sDateMax = helper.formatDateString(dateMax);
        
        console.log('min = ' + sDateToday + ', max = ' + sDateMax);
        component.set('v.LATEST_COMPLETED_DATE', sDateMax);

        component.set('v.itemsToLoad', 0);

        //helper.showSpinner(component, true);
        // initial load
        helper.loadUserAndQualifications(component);

        // populate year dropdowns
        var dateNow = new Date();
        var yearNow = dateNow.getFullYear();
        var yearsToDisplay = 15;
        helper.populateYearPicklist(component, 'v.yearCompletedOptions',
            yearNow - yearsToDisplay, yearNow + yearsToDisplay,
            true, '--Select--');

        helper.populateYearPicklist(component, 'v.firstYearEnrolmentOptions',
            yearNow - yearsToDisplay, yearNow + yearsToDisplay,
            true, '--Select--');

        // load Qualification type options
        helper.loadPicklistOptions(component, 'c.getQualificationRecordTypeOptions', 'v.qualRecordTypes', true, 'v.qualRecordTypeMap');

        // load English Test (Admission Tests in Callista) options
        helper.loadPicklistOptions(component, 'c.getAdmissionTestOptions', 'v.englishTestOptions', true, 'v.qualEnglishTestTypeMap');
        // countries
        helper.loadPicklistOptions(component, 'c.getCountryAttributes', 'v.countryOptions', true, 'v.countryMap');
        // australian states
        helper.loadPicklistOptions(component, 'c.getAusStateOptions', 'v.ausStateOptions', true, null);
        // completion statuses
        helper.loadPicklistOptions(component, 'c.getCompletionStatusOptions', 'v.completionLevelOptions', true, null);
    },


    onClickAddNew: function(component, event, helper)
    {
        helper.setStateTo(component, 'SELECT_TYPE');
	},

    onClickSave: function(component, event, helper)
    {
        //helper.setStateTo(component, 'SAVING');
        helper.saveCurrentQualification(component);
    },

    onClickCancel: function(component, event, helper)
    {
        // TODO - clear all attributes
        helper.clearComponentAttributes(component);
        helper.setStateTo(component, 'START');
    },

    onClickDelete: function(component, event, helper)
    {
        // aura id is unavailable for dynamic components, need to hack with button name
        var buttonName = event.getSource().get('v.name');
        console.debug('clicked delete for :' + buttonName);
        component.set('v.qualIdToDelete', buttonName);

        component.set('v.showConfirmDelete', true);
    },

    onClickConfirmDelete:function(component, event, helper)
    {
        component.set('v.showConfirmDelete', false);
        helper.setStateTo(component, 'DELETING');
        helper.showSpinner(component, true);

        // DELETE and wait for setstate to clear
        helper.deleteContactQualification(component);
    },

    onClickCancelDelete:function(component, event, helper)
    {
        // clear temp variable
        component.set('v.qualIdToDelete', null);

        // close confirm box
        component.set('v.showConfirmDelete', false);
    },

    onClickEdit: function(component, event, helper)
    {
        // get the qualification record Id
        var qualificationId = event.getSource().get('v.name');

        component.set('v.editingDraft', true);
        // populate the form
        helper.loadDraftQualificationIntoForm(component, qualificationId);

        // show the form
        helper.setStateTo(component, 'FORM_DETAILS');
    },

    /* TODO - next phase implementation for viewing historical qualifications
    onClickView: function(component, event, helper)
    {
        // get the qualification record Id
        var qualificationId = event.getSource().get('v.name');
    },
    */

    onSelectQualificationType: function(component, event, helper)
    {
        // clear to-save variable
        component.set('v.contactQualification', null);
        
        // update the qualification readable name
        var qualTypeId = component.get('v.selectedQualRecordTypeId');
        var qualRecordTypeMap = component.get('v.qualRecordTypeMap');
        component.set('v.selectedQualTypeName', qualRecordTypeMap[qualTypeId]);
        console.debug('appAddQualificationCtller:: selectedQualTypeName = ' + component.get('v.selectedQualTypeName'));

        helper.setStateTo(component, 'FORM_DETAILS');
    },

    onSelectTertiaryCountry: function(component, event, helper)
    {
      
        // set the name attribute via the map
        var countryMap = component.get('v.countryMap');

        var selectedId = component.get('v.qualTertiaryCountryId');
        helper.getcountryname(component);
       
        var countryName = countryMap[selectedId]
        // Instruction in English Only needs to be set for Australia
        if(countryName == 'Australia')
        {
            component.set("v.qualTertiaryEnglishOnly", true);
        }
    },

    onSelectSecondaryCountry: function(component, event, helper)
    {
        // selected the country for Secondary
        // set the name attribute via the map
        var countryMap = component.get('v.countryMap');
        var selectedId = component.get('v.qualSecondaryCountryId');
        var countryName = countryMap[selectedId];
        component.set('v.qualSecondaryCountry', countryName);
        if(countryName == 'Australia')
        {
            component.set("v.qualSecondaryEnglishOnly", true);
        }
    },

    toggleComplete : function(component, event, helper){
        helper.clearScore(component);
    },

    onSelectEnglishTestType:function(component, event, helper)
    {
        // set the name attribute via the map
        var engTestMap = component.get('v.qualEnglishTestTypeMap');

        var selectedId = component.get('v.qualEnglishTestId');
        component.set('v.qualEnglishTestName', engTestMap[selectedId]);
        helper.clearScore(component);
    },

    onTabSelectQualification:function(component, event, helper)
    {
        // clear all qualification name values
        component.set('v.qualSecondaryTypeId', null);
        component.set('v.qualSecondaryTypeOther', null);


        var cmpSearchAusQualification = component.find('searchSecondaryAusQualification');
        if(cmpSearchAusQualification)
            cmpSearchAusQualification.clearValues();
        var cmpSearchIntlQualification = component.find('searchSecondaryIntlQualification');
        if(cmpSearchIntlQualification)
            cmpSearchIntlQualification.clearValues();
    },

    onTabSelectInstitution:function(component, event, helper)
    {
        component.set('v.qualSecondarySchoolOther', null);
        component.set('v.qualSecondarySchool', null);
        component.set('v.objSecondarySchool', null);

        component.set('v.qualTertiaryAwardingBody', null);
        component.set('v.qualTertiaryAwardingBodyOther', null);
        component.set('v.objTertiaryAwardingBody', null);
        
        var cmpSearchTerAwardingBody = component.find('searchTertiaryAwardingBody');
        if(cmpSearchTerAwardingBody)
            cmpSearchTerAwardingBody.clearValues();

        var cmpSearchSecSchool = component.find('searchSecondarySchool');
        if(cmpSearchSecSchool)
            cmpSearchSecSchool.clearValues();
    },

    onChangeSecondaryDateExpected:function(component, event, helper)
    {
        
        return;
        /* removed, using out of the box functionality to limit the date input
        var cmp = event.getSource();
        var dateSelected = component.get('v.qualSecondaryDateExpected');
        if(helper.isDatePast(dateSelected))
        {
            component.set('v.errorMsgSecondaryDateExpected', true);
        }
        else
        {
            component.set('v.errorMsgSecondaryDateExpected', false);
        }
        */
    }

    , onChangeEnglishExpected:function(component, event, helper)
    {
        /*
        var cmp = event.getSource();
        var dateSelected = component.get('v.qualEnglishTestDateExpected');
        if(helper.isDatePast(dateSelected))
        {
            component.set('v.errorMsgEnglishTestDateExpected', true);
        }
        else
        {
            component.set('v.errorMsgEnglishTestDateExpected', false);
        }
        */
    }

    , onSearchSelectSecondaryQualification:function(component, event, helper)
    {
        var objSelected = event.getParam('sObject');
        //unused
        //component.set('v.objSecondaryQualification', objSelected);
    }
    , onSearchSelectSecondarySchool:function(component, event, helper)
    {
        var objSelected = event.getParam('sObject');
        //console.log('objSelected = ' + objSelected);
        component.set('v.objSecondarySchool', objSelected);
    }

    , onSearchSelectTertiaryAwardingBody:function(component, event, helper)
    {
        var objSelected = event.getParam('sObject');
        //console.log('objSelected = ' + objSelected);
        component.set('v.objTertiaryAwardingBody', objSelected);
    }

    , onClickCloseAlert:function(component, event, helper)
    {
        helper.clearSaveErrors(component);
    }
    
    , onChangeCreditIntention:function(component, event, helper)
    {
        // update the application credit intention state
    	helper.saveCreditIntention(component);
    }

    , onChangeEnglishLanguageProficiency:function(component, event, helper)
    {
        // update the application's english language proficiency field
    	helper.saveApplication(component);
    }

    , onToggleAdmissionsCompleted:function(component, event, helper)
    {
        console.log('on toggle admissions completed');

        var isCompleted = component.get('v.qualAdmissionsCompleted');
        var cmp = component.find("testDate");


        var msInADay = 24 * 60 * 60 * 1000;

        var dateToday = new Date();
        var sDateToday = helper.formatDateString(dateToday);

        // today + 100 days
        var dateMax = new Date(dateToday.getTime() + (1 * msInADay));
        var sDateMax = helper.formatDateString(dateMax);

        if(isCompleted)
        {
            cmp.set('v.min', '');
            cmp.set('v.max', sDateToday);
        }
        else
        {
            cmp.set('v.min', sDateToday);
            cmp.set('v.max', '');
        }
    },
    onSelectCompletionLevel  : function(component, event, helper) {
    },
    validateFields : function(component, event, helper){
        var params = event.getParam('arguments');
        var callback;
        if (params) {
            callback = params.callback;
        }

        let englishLanguageProficiency = component.get("v.englishLanguageProficiency");
        let missingRequiredError = 'Please ensure that the following fields are completed:<br/>';
        let hasMissingRequiredField = false;

        // english language proficiency
        if(englishLanguageProficiency === '' || !englishLanguageProficiency){
            hasMissingRequiredField = true;
            missingRequiredError = missingRequiredError + '<span style="padding-left: 1em;">• English Language Proficiency</span><br/>';
            
            //scroll to top
            document.getElementById("englishLanguageProficiency").scrollTop = 0;
            window.scroll({
                top: 0, 
                left: 0, 
                behavior: 'smooth'
            });
        }
        // current institution must be filled for Study Abroad and Exchange applications
        let currentInstitution = component.get("v.institutionName");
        let studyType = component.get("v.studyType");
        if ((studyType === 'Study Abroad' || studyType === 'Exchange' ) && ( currentInstitution === '' || !currentInstitution )) {
            hasMissingRequiredField = true;
            missingRequiredError = missingRequiredError + '<span style="padding-left: 1em;">• Current Institution</span><br/>';

            //scroll to top
            document.getElementById("currentInstitution").scrollTop = 0;
            window.scroll({
                top: 0,
                left: 0,
                behavior: 'smooth'
            });
        }

        // Tertiary Qualification is Mandatory
        if (studyType === 'Study Abroad' || studyType === 'Exchange') {
            let tertiaryQualification = false;
            // check Contact's existing Qualifications (from previous applications)
            let qualifications = component.get("v.qualListHistorical");
            if (qualifications !== null && qualifications !== undefined && qualifications.length > 0 && qualifications.find(qual => qual.RecordType.Name === 'Tertiary Education')) {
                tertiaryQualification = true;
            }
            // check Qualifications in the current application
            if (!tertiaryQualification){
                qualifications = component.get("v.qualListDraft");
                if (qualifications !== null && qualifications !== undefined && qualifications.length >0 && qualifications.find(qual => qual.RecordType.Name === 'Tertiary Education')) {
                    tertiaryQualification = true;
                }
            }
            if (!tertiaryQualification) {
                hasMissingRequiredField = true;
                missingRequiredError = missingRequiredError + '<span style="padding-left: 1em;">• Tertiary Qualification / Post Secondary</span><br/>';

                //scroll to top
                document.getElementById("qualifications").scrollTop = 0;
                window.scroll({
                    top: 0,
                    left: 0,
                    behavior: 'smooth'
                });
            }
        }

        // save application changes
        if(!hasMissingRequiredField){
            helper.saveApplication(component, callback);
        }else{
            if(callback) {
                callback({
                    "hasError" : hasMissingRequiredField, 
                    "errorMessage" : missingRequiredError
                });
            }
        }

        component.set('v.hasSavedSection', true);
    },
    handleInstitutionChange : function(component, event, helper) {
        // set selected current institution
        if(event.ap.target === 'institution'){
            component.set('v.institutionName', event.ap.value);
        }else{
            component.set('v.institutionName', '');
        }
        console.log(JSON.stringify(event));
    },
    handleInstitutionKeyUp : function(component, event, helper) {
        // set selected current institution
        if(event.ap.target === 'institution'){
            component.set('v.institutionName', event.ap.value);
        }
    },
})