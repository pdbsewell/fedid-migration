({
    setStateTo : function(component, sState) {
        var currState = component.get('v.state');

        switch (sState) {
            case 'START':

                // close confirm modals
                component.set('v.showConfirmDelete', false);

                // going back to start state, reload
                if(currState != 'START')
                {
                    // clear everything
                    this.clearComponentAttributes(component);

                    // reload the attached qualifications (historical list will not change)
                    this.loadDraftQualifications(component);
                }
                break;

            case 'FORM_DETAILS':
                this.clearSaveErrors(component);
                break;
            default:
                break;

        }
	    console.debug('appAddQualHelper::setStateTo:' + sState);
		component.set('v.state', sState);
	},

    clearScore : function(component){
        component.set('v.qualEnglishGPAResult', null);
        component.set('v.qualEnglishTestScoreReading', null);
        component.set('v.qualEnglishTestScoreListening', null);
        component.set('v.qualEnglishTestScoreWriting', null);
        component.set('v.qualEnglishTestScoreSpeaking', null);
        component.set('v.qualEnglishTestDateCompleted', null);
        component.set('v.qualEnglishTestDateExpected', null);
        component.set('v.qualEnglishComments', null);
    },

	incrementItemsToLoadCounter:function(component, calledBy)
    {
        var iCount = component.get('v.itemsToLoad');
        iCount++;
        component.set('v.itemsToLoad', iCount);
        //console.debug('INCREMENT::items to load = ' + iCount + ' from ' + calledBy);
        if(iCount > 0)
        {
            this.showSpinner(component, true);
        }
    }


	, itemFinishedLoading:function(component, calledBy)
    {
        var iCount = component.get('v.itemsToLoad');
        iCount --;
        component.set('v.itemsToLoad', iCount);

        //console.debug('LOADED::items to load = ' + iCount + ' from ' + calledBy);
        if(iCount == 0)
        {
            this.showSpinner(component, false);
        }
    }

	, showSpinner : function(component, toShow)
    {
        component.set('v.showSpinner', toShow);
    }

	, loadUserAndQualifications: function(component)
    {
        var appId = this.parseApplicationIdFromUrl(component);
        if(!appId){
            appId = component.get("v.applicationId");
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + appId;
        }
        if(!appId)
        {
            console.error('appAddQualificationHelper::loadUserAndQualification:: no app Id');
            return;
        }
     
        var objHelper = this;
        
        var action = component.get("c.getCurrentUserAndQualifications");   
        var applicationId = component.get('v.applicationId');
        action.setParams({
            'applicationId': applicationId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var objResponse = response.getReturnValue();

                //Retrieve student status and set current / previous notification message
                if(objResponse.STUDENT_STATUS === 'CurrentMatch'){
                    component.set("v.currentPreviousNotification", "As you are a current Monash student, you only need to inform us of any non-Monash qualifications that you are currently undertaking.")                    
                }else if(objResponse.STUDENT_STATUS === 'PreviousMatch'){
                    component.set("v.currentPreviousNotification", "As you are a past Monash student, you only need to inform us of qualifications obtained since last studying at Monash.")         
                }

                // get the user info
                component.set("v.userInfo", objResponse.user);
                
                this.debugObject(component, objResponse, 'getCurrentUserAndQualifications');

                // get the editable/deletable qualifications
                var arrDraftQualifications = objResponse['draft_qualifications'];
                component.set("v.qualListDraft", arrDraftQualifications );


                //this.debugArray(component, arrDraftQualifications, 'getCurrentUserAndQualifications::drafts');

                // get the static ones
                var arrHistoricalQualifications = objResponse['historical_qualifications'];
                component.set("v.qualListHistorical", arrHistoricalQualifications);

                var listInstitutions = objResponse['draft_institutions'];
                component.set("v.institutionList", listInstitutions);
                
                // credit intention
                var application = objResponse.application;
                component.set("v.creditIntention",application.Credit_Intention__c);
                if(application.AgentName__c){
                    component.set("v.institutionName", application.AgentName__c);
                }else{
                    component.set("v.institutionName", application.Partner_Name__c);
                }
                objHelper.showHideCreditIntention(component);
                
                // add application study type
                component.set("v.studyType", application.Type_of_Study__c);
                component.set("v.agencyId", application.Agent__c);
                component.set("v.agencyName", application.AgentName__c);             
                component.set("v.applicantId", objResponse.APPLICANT); 
                component.set("v.isApplicationCreatedByPartner", objResponse.ApplicationCreatedByProfile.toLowerCase().includes('partner'));      
                component.set("v.accountPartnerRecordTypeId", objResponse.ACCOUNT_PARTNER_RECORDTYPE_ID); 
                component.set("v.showInstitutionSpinner", false);

                // english language proficiency             
                component.set("v.englishLanguageProficiency", application.English_Language_Proficiency__c);

                // institution options
                let resultInstitutionOptions = objResponse.PARTNER_ACCOUNTS;
                let institutionOptions = component.get("v.institutionOptions");
                if(resultInstitutionOptions){
                    resultInstitutionOptions.forEach(function(institutionOption) {
                        institutionOptions.push({ 
                            label: institutionOption, 
                            value: institutionOption
                        }); 
                    });
                }
                component.set("v.institutionOptions", institutionOptions);
                
                this.itemFinishedLoading(component, 'loadUserAndQualifications');
            }
            else if (state == 'ERROR'){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error('appAddQualificationHelper::getCurrentUserAndQualifications:' + errors[0].message);
                    }
                }
            }
        });

        this.incrementItemsToLoadCounter(component, 'loadUserAndQualifications');
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
                    component.set("v.applicationId", appId);
                    return appId;
                }
            }
        }
        
        return null;
    }

    , loadDraftQualifications:function(component)
    {
        var action = component.get("c.getDraftQualifications");
        
        var objHelper = this;
        //var objUser = component.get('v.userInfo');
        action.setParams({
            applicationId: component.get('v.applicationId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var objResponse = response.getReturnValue();

                // set the response
                var arrDraftQualifications = objResponse['draft_qualifications'];
                component.set("v.qualListDraft", arrDraftQualifications );

                var listInstitutions = objResponse['draft_institutions'];
                component.set("v.institutionList", listInstitutions);
                
                objHelper.showHideCreditIntention(component);
            }
            this.itemFinishedLoading(component, 'loadAppQualifications');
        });

        this.incrementItemsToLoadCounter(component, 'loadAppQualifications');
        $A.enqueueAction(action);
    }


	, loadPicklistOptions : function (component, actionName, optionAttributeName, insertDefault, mapAttrName)
    {
        var action = component.get(actionName);
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {

                //store the return response from server (List<Map<String, String>>)
                var arrResponse = response.getReturnValue();
                // add a default blank
                var arrOptions = [];
                if(insertDefault)
                {
                    arrOptions.push({
                        value:''
                        , label:'-- Select --'
                    });
                }

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
                this.itemFinishedLoading(component, 'loadPicklistOptions');
            }
        });

        this.incrementItemsToLoadCounter(component, 'loadPicklistOptions');
        $A.enqueueAction(action);
    }

    , storeValueLabelMap : function(component, arrOptions, mapAttrName)
    {
        var mapObj = {};
        var iLen = arrOptions.length;
        for(var i = 0; i < iLen; ++i)
        {
            var objOption = arrOptions[i];
            // there may be a blank value
            if(objOption.value) {
                mapObj[objOption.value] = objOption.label;
            }
        }
        component.set(mapAttrName, mapObj);
    }

    , populateYearPicklist: function (component, attributeName, earliestYear, latestYear, isAscending, placeHolder)
    {
        var arrOptions = [];
        arrOptions.push({
            value:''
            , label:placeHolder
        });

        if(isAscending)
        {
            for(var iYear = earliestYear; iYear <= latestYear; ++iYear)
            {
                arrOptions.push({
                    value:iYear
                    , label:iYear
                });
            }
        }
        else
        {
            for(var iYear = latestYear; iYear >= earliestYear; --iYear)
            {
                arrOptions.push({
                    value:iYear
                    , label:iYear
                });
            }
        }
        component.set(attributeName, arrOptions);
    }


    , saveCurrentQualification: function (component)
    {
        // clear previous save errors
        component.set("v.saveErrors", []);
        
        // get the record type
        var recTypeId = component.get('v.selectedQualRecordTypeId');

        // get the attributes relevant to this record type
        var objContactQualification = this.populateContactQualificationForSave(recTypeId, component);


        // check for errors
        var arrErrors = component.get("v.saveErrors");
        if(arrErrors.length > 0)
        {
            for(var i = 0; i < arrErrors.length; ++i)
            {
                console.log(i + ":" + arrErrors[i]);
            }
            console.log("]");
            
            component.set("v.showErrors", true);
        }
        else
        {
            // apex action
            var action = component.get("c.upsertQualificationToContact");
            // get the contact Id
            var objUser = component.get('v.userInfo');
            var objParams = {
                'contactId':component.get('v.applicantId')
                , 'applicationId':component.get('v.applicationId')
                , 'contactQualification':objContactQualification
            };    
            this.debugObject(component, objParams, 'saveCurrentQualification');
            // pass to controller
            action.setParams(objParams);
            action.setCallback(this, function(response) {
                console.debug('appAddQualificationHelper::UpsertQualification:response = ' + response.getState());
                if (response.getState() == "SUCCESS") {
    
                    //store the return response from server (List<Map<String, String>>)
                    var objResponse = response.getReturnValue();
                    this.debugObject(component, objResponse, 'UpsertQualification');
                }
    
                this.itemFinishedLoading(component, 'saveCurrentQualification');
    
                // back to original state
                this.setStateTo(component, 'START');
    
            });
            this.incrementItemsToLoadCounter(component, 'saveCurrentQualification');
            $A.enqueueAction(action);   
        }
    }

    , populateContactQualificationForSave: function(recTypeId, component)
    {
        var objCQ = component.get('v.contactQualification');
        if(!objCQ)
        {
            // saving a new record
            objCQ = {};
            objCQ.RecordTypeId = recTypeId;
        }
        else
        {
            //updating a record
        }

        var objUser = component.get('v.userInfo');
        objCQ.Contact__c = component.get('v.applicantId');

        // get the corresponding recTypeName
        var recTypeMap = component.get('v.qualRecordTypeMap');
        var recTypeName = recTypeMap[recTypeId]

        if(recTypeName == 'Tertiary Education')
        {
            this.populateContactQualificationTertiarySave(component, objCQ);
        }
        else if(recTypeName == 'Secondary Education')
        {
            this.populateContactQualificationSecondarySave(component, objCQ);
        }
        else if(recTypeName == 'English Test')
        {
            this.populateContactQualificationEnglishSave(component, objCQ);
        }
        else if(recTypeName == 'Other Qualification')
        {
            this.populateContactQualificationAdmissionsSave(component, objCQ);
        }
        else
        {
            console.error('appAddQualificationHelper:: record type ' + recTypeName + ' not found');
        }

        this.debugObject(component, objCQ, 'populateContactQualificationForSave');

        // set it back into the page level
        component.set('v.contactQualification', objCQ);
        return objCQ;
    }, isUnsafe: function(dataObject) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g;
         return XML_REGEX_PATTERN.test(JSON.stringify(dataObject));
    }, populateContactQualificationTertiarySave:function(component, objCQ)
    {
        var arrSaveErrors = [];        
        
        // country/state
        var country = component.get('v.qualTertiaryCountryId');
        if(!country)
        {
            arrSaveErrors.push('Country');
        }
        objCQ.Qualification_Country__c = country;


        var tertiaryState = component.get('v.qualTertiaryState');
        var tertiaryStateProvince = component.get('v.qualTertiaryStateProvince');
        if(tertiaryState)
            objCQ.State__c = tertiaryState;
        else if(tertiaryStateProvince)
            objCQ.State_Province__c = tertiaryStateProvince;

        // name of qualification - always free text for tertiary
        var qualName = component.get('v.qualTertiaryName');
        objCQ.Other_Qualification__c = qualName;
        if(!qualName)
        {
            arrSaveErrors.push('Qualification Type');
        }

        // awarding body
        var qualTertiaryAwardingBodyOther = component.get('v.qualTertiaryAwardingBodyOther');
            var objInstitution = component.get('v.objTertiaryAwardingBody');
        if(qualTertiaryAwardingBodyOther)
        {
            // free text version
            objCQ.Other_Institution__c = component.get('v.qualTertiaryAwardingBodyOther');
            objCQ.Institution_Name__c = null;
            objCQ.Institution_Code__c = null;
        }
        else if(objInstitution)
        {
            objCQ.Institution_Name__c = objInstitution.Institution_Name__c;
            objCQ.Institution_Code__c = objInstitution.Institution_Code__c;
            objCQ.Other_Institution__c = null;
        }
        else
        {
            arrSaveErrors.push('Awarding Body or Institution');
        }

        // years of enrolment
        var firstYear = component.get('v.qualTertiaryFirstYearEnrolled');
        objCQ.First_Year_Enrolled__c = firstYear;
        if(!firstYear || !this.isInputValid(component, "inputQualTertiaryFirstYearEnrolment") )
        {            
            arrSaveErrors.push('First year enrolled');
        }
        
        var lastYear = component.get('v.qualTertiaryLastYearEnrolled');
        objCQ.Last_Year_Enrolled__c = lastYear;
        if(!lastYear || !this.isInputValid(component, "inputQualTertiaryLastYearEnrolment"))
        {
            arrSaveErrors.push('Last year enrolled');
        }
        
        if(firstYear > lastYear)
        {
            arrSaveErrors.push('Last year enrolled must be later than your first');
        }

        // level of completion - using integrated field 'Status__c'
        var levelOfCompletion = component.get('v.qualTertiaryLevelOfCompletion');        
        objCQ.Status__c = levelOfCompletion;
        if(!levelOfCompletion)
        {
            arrSaveErrors.push('Level of Completion')
        }

        // is it english only
        objCQ.Instruction_in_English__c = component.get('v.qualTertiaryEnglishOnly');
        // comments
        objCQ.Other_Qualification_Comments__c = component.get('v.qualTertiaryComments');
        // score
        objCQ.Score__c = component.get('v.qualTertiaryGPAResult');
        
        if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');
        
        component.set('v.saveErrors', arrSaveErrors);
        return objCQ;
    }

    , populateContactQualificationSecondarySave:function(component, objCQ)
    {
        var arrSaveErrors = [];

        // country/state
        var country = component.get('v.qualSecondaryCountryId');
        if(!country)
        {
            arrSaveErrors.push('Country');
        }
        objCQ.Qualification_Country__c = country;

        var secondaryState = component.get('v.qualSecondaryState');
        var secondaryStateProvince = component.get('v.qualSecondaryStateProvince');
        if(secondaryState)
            objCQ.State__c = secondaryState;
        else if(secondaryStateProvince)
            objCQ.State_Province__c = secondaryStateProvince;

		var countryName = component.get('v.qualSecondaryCountry');        
        if(!secondaryState && countryName == 'Australia')
        {
            arrSaveErrors.push('State');
        }
        else if(!secondaryStateProvince
                && (countryName == 'China (excludes SARs and Taiwan)' || countryName =='India'))
        {
            arrSaveErrors.push('State/Province');
        }

        // name of qualification
        var qualSecondaryTypeOther = component.get('v.qualSecondaryTypeOther');
        var qualSecondaryId = component.get('v.qualSecondaryTypeId');
        if(qualSecondaryTypeOther) {
            objCQ.Other_Qualification__c = component.get('v.qualSecondaryTypeOther');
            objCQ.Qualification__c = null;
        }
        else if(qualSecondaryId){
            objCQ.Qualification__c = qualSecondaryId;
            objCQ.Other_Qualification__c = null;
        }
        else
        {
            arrSaveErrors.push('Qualification Name');
        }
        

        // school
        var qualSecondarySchoolOther = component.get('v.qualSecondarySchoolOther');
        var objSecondarySchool = component.get('v.objSecondarySchool');
        if(qualSecondarySchoolOther) {
            // free text
            objCQ.Other_Institution__c = component.get('v.qualSecondarySchoolOther');

            // clear the search version
            objCQ.Institution_Code__c = null;
            objCQ.Institution_Name__c = null;
        }
        else if(objSecondarySchool)
        {
            // store the values from the sObject
            objCQ.Institution_Name__c = objSecondarySchool.Institution_Name__c;
            objCQ.Institution_Code__c = objSecondarySchool.Institution_Code__c;

            objCQ.Other_Institution__c = null;
        }
        else if(!qualSecondarySchoolOther && !objSecondarySchool)
        {
            arrSaveErrors.push('School/Institution');
        }

        // completed / expected

        var isComplete = component.get('v.qualSecondaryCompleted');
        if(isComplete)
        {
            var yearCompleted = component.get('v.qualSecondaryYearCompleted');
            
            if(!yearCompleted || !this.isInputValid(component, "inputQualSecondaryYearCompleted"))
            {
                arrSaveErrors.push('Year of completion');
            }

            //Set completion year
            var yearCompletionCurrentDate = new Date();
            yearCompletionCurrentDate.setFullYear(parseInt(yearCompleted));

            //Set current year
            var currentDate = new Date();

            //Compare years
            if(yearCompletionCurrentDate > currentDate){
                arrSaveErrors.push('Completion Year must be less than or equal to the Current Year');
            }

            objCQ.Year_of_Completion__c = yearCompleted;
            objCQ.Expected_date_of_completion__c = null;
        }
        else
        {
            objCQ.Year_of_Completion__c = null;

            // validate that it is not a date in the past
            var dateExpected = component.get('v.qualSecondaryDateExpected');
            if(!dateExpected)
            {
                arrSaveErrors.push('Expected date of completion');
            }
            else if(!this.isExpectedDateValid(component, dateExpected))
            {
                this.addErrorMessageExpectedDatePast(arrSaveErrors);
            }
            else
            {
                objCQ.Expected_date_of_completion__c = dateExpected;
            }
        }
        
        // comments
        objCQ.Other_Qualification_Comments__c = component.get('v.qualSecondaryComments');

        // score, always 0
        //objCQ.Score__c = component.get('v.qualSecondaryScore');
        objCQ.Score__c = "0";

        // is it english only
        objCQ.Instruction_in_English__c = component.get('v.qualSecondaryEnglishOnly');
         if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');
        component.set('v.saveErrors', arrSaveErrors);
        return objCQ;
    }


    , addErrorMessageExpectedDatePast:function(arrSaveErrors)
    {
        arrSaveErrors.push('Expected Date of Completion is in the past');
    }

    /**
     * Corresponding load from draft for SECONDARY
     * @param component
     * @param objCQ
     */
    , loadDraftSecondary:function(component, objCQ)
    {
        var mapCountry = component.get('v.countryMap');
        // country/state
        component.set('v.qualSecondaryCountryId', objCQ.Qualification_Country__c);

        var countryName = mapCountry[objCQ.Qualification_Country__c];
        component.set('v.qualSecondaryCountry', countryName);

        if(objCQ.State_Province__c)
            component.set('v.qualSecondaryStateProvince', objCQ.State_Province__c);
        else if(objCQ.State__c)
            component.set('v.qualSecondaryState', objCQ.State__c);

        // name of qualification
        if(objCQ.Other_Qualification__c )
        {
            component.set('v.tabIdSecondaryType', 'SEC_QUAL_NAME_MANUAL');
            component.set('v.qualSecondaryTypeOther', objCQ.Other_Qualification__c);
        }
        else
        {
            component.set('v.tabIdSecondaryType', 'SEC_QUAL_NAME_SEARCH');

            if(objCQ.Qualification__c) {
                // from drop down
                component.set('v.qualSecondaryTypeId', objCQ.Qualification__c);

                var cmpSearchQualification;
                if (countryName == 'Australia')
                    cmpSearchQualification = component.find('searchSecondaryAusQualification');
                else
                    cmpSearchQualification = component.find('searchSecondaryIntlQualification');
                
                if(cmpSearchQualification)
                	cmpSearchQualification.prePopulate();
            }
        }

        // secondary school
        if(objCQ.Other_Institution__c)
        {
            component.set('v.tabIdSecondarySchool', 'AUS_SEC_MANUAL');
            component.set('v.qualSecondarySchoolOther', objCQ.Other_Institution__c);
        }
        else if(objCQ.Institution_Code__c && objCQ.Institution_Name__c)
        {
            component.set('v.tabIdSecondarySchool', 'AUS_SEC_SEARCH');

            var objSecondarySchool = this.lookupInstitution(component, objCQ);
            component.set('v.qualSecondarySchool', objSecondarySchool.Id);
            component.set('v.objSecondarySchool', objSecondarySchool);

            // prepopulate the search dropdown
            var cmpSearchSecondary = component.find('searchSecondarySchool');
            if(cmpSearchSecondary)
            	cmpSearchSecondary.prePopulate();
        }
        else
        {
        }

        // years of enrolment
        var secondaryYearCompleted = objCQ.Year_of_Completion__c;
        if(secondaryYearCompleted)
        {
            component.set('v.qualSecondaryCompleted', true);
            component.set('v.qualSecondaryDateExpected', null);
            component.set('v.qualSecondaryYearCompleted', secondaryYearCompleted);

        }
        else
        {
            component.set('v.qualSecondaryCompleted', false);
            component.set('v.qualSecondaryDateExpected', objCQ.Expected_date_of_completion__c);
            component.set('v.qualSecondaryYearCompleted', null);
        }

        // comments
        component.set('v.qualSecondaryComments', objCQ.Other_Qualification_Comments__c);
        
        // level of completion
        component.set('v.qualSecondaryScore', objCQ.Score__c);
        // is it english only
        component.set('v.qualSecondaryEnglishOnly', objCQ.Instruction_in_English__c);

    }


    , deleteContactQualification:function(component)
    {
        var action = component.get('c.deleteContactAndAppQualification');

        var objParams = {
            'contactQualificationId': component.get('v.qualIdToDelete')
            , 'applicationId':component.get('v.applicationId')
        };

        // pass to controller
        action.setParams(objParams);
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.debug('appAddQualificationHelper::deleteContactQualification state = ' + state);
            if (state == "SUCCESS") {

                //store the return response from server (List<Map<String, String>>)
                var objResponse = response.getReturnValue();
                this.debugObject(component, objResponse, 'deleteContactQualification');
                
                // check if we need to clear and hide the credit intention
                var application = objResponse.application;
                component.set("v.creditIntention",application.Credit_Intention__c);
            }
            else if (state == 'ERROR'){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error('appAddQualificationHelper::deleteContactQualification ' + errors[0].message);
                    }
                }
            }

            this.itemFinishedLoading(component, 'deleteContactQualification');

            // back to original state
            this.setStateTo(component, 'START');
        });

        this.incrementItemsToLoadCounter(component, 'deleteContactQualification');
        $A.enqueueAction(action);
    }

    , loadDraftQualificationIntoForm:function(component, contactQualificationId)
    {
        // populate the fields from an existing draft qualification
        var qualListDraft = component.get('v.qualListDraft');
        var objCQ;

        for(var i = 0; i < qualListDraft.length; ++i)
        {
            var conQual = qualListDraft[i];
            if(conQual.Id == contactQualificationId)
            {
                objCQ = conQual;
                break;
            }
        }
        if(objCQ)
        {
            // set the page attribute
            component.set('v.contactQualification', objCQ);

            var recTypeName = objCQ.RecordType.Name;
            component.set('v.selectedQualRecordTypeId', objCQ.RecordTypeId);
            component.set('v.selectedQualTypeName', recTypeName);

            if(recTypeName == 'Tertiary Education')
            {
                this.loadDraftTertiary(component, objCQ);
            }
            else if(recTypeName == 'Secondary Education')
            {
                this.loadDraftSecondary(component, objCQ);
            }
            else if(recTypeName == 'English Test')
            {
                this.loadDraftEnglish(component, objCQ);

            }
            else if(recTypeName == 'Other Qualification')
            {
                this.loadDraftAdmissions(component, objCQ);
            }
            else
            {
                console.error('appAddQualificationHelper:: record type ' + recTypeName + ' not found');
            }
        }
        else
        {
            console.error('appAddqualificationHelper::loadDraftQualification - could not find draft record ' + contactQualificationId);
        }
    }

    , loadDraftTertiary:function(component, objCQ)
    {
        var mapCountry = component.get('v.countryMap');
        // country/state
        component.set('v.qualTertiaryCountryId', objCQ.Qualification_Country__c);
        
        this.getcountryname(component);

        /* 2018/09/03 DEPRECATED
        if(objCQ.State_Province__c)
            component.set('v.qualTertiaryState',objCQ.State_Province__c);
        else
            component.set('v.qualTertiaryState', objCQ.State__c );
            */

        // name of qualification - always free text for tertiary
        component.set('v.qualTertiaryName', objCQ.Other_Qualification__c);

        // awarding body
        if(objCQ.Other_Institution__c)
        {
            // switch the tab first, because it will clear the values
            component.set('v.tabIdTertiaryAwardingBody', 'AUS_TER_MANUAL');
            component.set('v.qualTertiaryAwardingBodyOther', objCQ.Other_Institution__c);
        }
        else
        {
            // switch the tab first, because it will clear the values
            component.set('v.tabIdTertiaryAwardingBody', 'AUS_TER_SEARCH');

            if(objCQ.Institution_Code__c) {
                var objTertiaryBody = this.lookupInstitution(component, objCQ);
                component.set('v.qualTertiaryAwardingBody', objTertiaryBody.Id);
                component.set('v.objTertiaryAwardingBody', objTertiaryBody);

                // prepopulate the search dropdown
                var cmpSearchTertiary = component.find('searchTertiaryAwardingBody');
                cmpSearchTertiary.prePopulate();
            }
        }

        // years of enrolment
        component.set('v.qualTertiaryFirstYearEnrolled', objCQ.First_Year_Enrolled__c);
        component.set('v.qualTertiaryLastYearEnrolled', objCQ.Last_Year_Enrolled__c);

        // level of completion - using integrated field 'Status__c'
        component.set('v.qualTertiaryLevelOfCompletion', objCQ.Status__c);        

        // is it english only
        component.set('v.qualTertiaryEnglishOnly', objCQ.Instruction_in_English__c);

        // comments
        component.set('v.qualTertiaryComments', objCQ.Other_Qualification_Comments__c);
        
        // score
        component.set('v.qualTertiaryGPAResult', objCQ.Score__c);
    }

    , loadDraftEnglish:function (component, objCQ)
    {
        component.set('v.qualEnglishTestId', objCQ.Qualification__c );
        var qualification = objCQ.Qualification__r;
        if (qualification) {
            component.set('v.qualEnglishTestName', qualification.Qualification_Name__c);
        }

        var isComplete = objCQ.isTestCompleted__c;
        component.set('v.qualEnglishCompleted', isComplete);
        
        
        // if completed or expecting completion
        var dateAchieved = objCQ.Date_Achieved__c;
        if(isComplete) {
            component.set('v.qualEnglishTestDateCompleted', objCQ.Date_Achieved__c);            
        }
        else {
            component.set('v.qualEnglishTestDateExpected', objCQ.Expected_date_of_completion__c);
        }

        // comments
        component.set('v.qualEnglishComments', objCQ.Other_Qualification_Comments__c);        
        
        component.set('v.qualEnglishGPAResult', objCQ.Score__c);
        component.set('v.qualEnglishTestScoreListening', objCQ.Listening__c);
        component.set('v.qualEnglishTestScoreReading', objCQ.Reading__c);
        component.set('v.qualEnglishTestScoreSpeaking', objCQ.Speaking__c);
        component.set('v.qualEnglishTestScoreWriting', objCQ.Writing__c);
    }

    , lookupInstitution:function(component, objCQ)
    {
        var institutionCode = objCQ.Institution_Code__c;
        var institutionName = objCQ.Institution_Name__c;

        var institutionList = component.get('v.institutionList');
        for( var i = 0; i < institutionList.length; ++i)
        {
            var objInstitution = institutionList[i];
            if(objInstitution.Institution_Code__c == institutionCode && objInstitution.Institution_Name__c == institutionName)
            {
                return objInstitution;
            }
        }
        return null;
    }

    , populateContactQualificationEnglishSave:function(component, objCQ)
    {
        var arrSaveErrors = [];
        var englishTestType = component.get('v.qualEnglishTestId');

        if(!englishTestType)
        {
            arrSaveErrors.push('English Test Type');
        }    
        objCQ.Qualification__c = englishTestType;

        var isComplete = component.get('v.qualEnglishCompleted');
        objCQ.isTestCompleted__c = isComplete;
        if(isComplete) 
        {
            var dateAchieved = component.get('v.qualEnglishTestDateCompleted');

            if(!dateAchieved)
            {
                arrSaveErrors.push('Date Achieved');
            }
            else if(!this.isCompletedDateValid(component, dateAchieved))
            {
                arrSaveErrors.push('Date Achieved is invalid');
            }
            else
            {
                objCQ.Date_Achieved__c = dateAchieved;
            }
            objCQ.Expected_date_of_completion__c = null;


            this.validateEnglishScores(component, objCQ, arrSaveErrors);
        }
        else
        {
            var dateExpected = component.get('v.qualEnglishTestDateExpected');
            if(!dateExpected)
            {
                arrSaveErrors.push('Expected Date of Completion');
            }
            else if(this.isDatePast(dateExpected))
            {
                this.addErrorMessageExpectedDatePast(arrSaveErrors);
            }
            else
            {
                objCQ.Expected_date_of_completion__c = dateExpected;
            }
            objCQ.Date_Achieved__c = null;

            // all scores to be sending 0
            objCQ.Score__c = "0";
            objCQ.Listening__c = "0";
            objCQ.Writing__c = "0";
            objCQ.Speaking__c = "0";
            objCQ.Reading__c = "0";
        }

        
        // comments
        objCQ.Other_Qualification_Comments__c = component.get('v.qualEnglishComments');
        if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');
        component.set('v.saveErrors', arrSaveErrors);
    }

    , validateEnglishScores:function(component, objCQ, arrSaveErrors)
    {
        if(this.isInputValid(component, 'inputQualEnglishGPAResult'))
        {
            objCQ.Score__c = component.get('v.qualEnglishGPAResult');
        }
        else
        {
            arrSaveErrors.push('English Score/Result - Incorrect format or missing information');
        }

        if(this.isInputValid(component, 'inputQualEnglishListeningScore'))
        {
            objCQ.Listening__c = component.get('v.qualEnglishTestScoreListening');
        }
        else
        {
            arrSaveErrors.push('English Listening Score');
        }

        // Reading
        if(this.isInputValid(component, 'inputQualEnglishReadingScore'))
        {
            objCQ.Reading__c = component.get('v.qualEnglishTestScoreReading');
        }
        else
        {
            arrSaveErrors.push('English Reading Score');
        }

        // speaking
        if(this.isInputValid(component, 'inputQualEnglishSpeakingScore'))
        {
            objCQ.Speaking__c = component.get('v.qualEnglishTestScoreSpeaking');
        }
        else
        {
            arrSaveErrors.push('English Speaking Score');
        }

        // writing
        if(this.isInputValid(component, 'inputQualEnglishWritingScore'))
        {
            objCQ.Writing__c = component.get('v.qualEnglishTestScoreWriting');
        }
        else
        {
            arrSaveErrors.push('English Writing Score is not valid');
        }
    }

    , isCompletedDateValid:function(component, dateString)
    {
        var dateToday = new Date();
        var dateValue = new Date(dateString);
        if(dateValue > dateToday)
            return false;
        return true;
    }

    , isExpectedDateValid:function(component, dateString)
    {
        var dateToday = new Date();
        var dateValue = new Date(dateString);
        if(dateValue < dateToday)
            return false;
        return true;
    }

    , isInputValid:function(component, cmpAuraId)
    {
        // expected/completed dates
        var cmpInput = component.find(cmpAuraId);
        if(cmpInput != null){
            var valid = cmpInput.get('v.validity').valid;
            return valid;
        }
        return true;

    }
    
    , loadDraftAdmissions:function(component, objCQ)
    {
        component.set('v.qualAdmissionsName', objCQ.Other_Qualification__c);
        component.set('v.qualAdmissionsGPAResult', objCQ.Score__c);


        var isCompleted = objCQ.isTestCompleted__c;
        component.set('v.qualAdmissionsCompleted', isCompleted);

        // if completed or expecting completion
        if(isCompleted)
        {
            var dateAchieved = objCQ.Date_Achieved__c;
            component.set('v.qualAdmissionsDateCompleted', objCQ.Date_Achieved__c);
        }
        else
        {
            component.set('v.qualAdmissionsDateExpected', objCQ.Expected_date_of_completion__c);
        }
        component.set('v.qualAdmissionsComments', objCQ.Other_Qualification_Comments__c);
    }
    
    , populateContactQualificationAdmissionsSave:function(component, objCQ)
    {   
        var arrSaveErrors = [];
        
        var qualName = component.get('v.qualAdmissionsName');
        objCQ.Other_Qualification__c = qualName;
        if(!qualName)
        {
            arrSaveErrors.push('Qualification Name');
        }        
        
        objCQ.Score__c = component.get('v.qualAdmissionsGPAResult');
        
        var isComplete = component.get('v.qualAdmissionsCompleted');
        objCQ.isTestCompleted__c = isComplete;
        if(isComplete) 
        {
            var dateAchieved = component.get('v.qualAdmissionsDateCompleted');            
            objCQ.Date_Achieved__c = dateAchieved;
            if(!dateAchieved || !this.isCompletedDateValid(component, dateAchieved))
            {
                arrSaveErrors.push('Date Achieved');
            }
            objCQ.Expected_date_of_completion__c = null;
        }
        else
        {
            var dateExpected = component.get('v.qualAdmissionsDateExpected');
            objCQ.Expected_date_of_completion__c = dateExpected;
            if(!dateExpected || !this.isExpectedDateValid(component, dateExpected))
            {
                arrSaveErrors.push('Expected Date of Completion');
            }
            objCQ.Date_Achieved__c = null;
        }        
            objCQ.Other_Qualification_Comments__c = component.get('v.qualAdmissionsComments');
            if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');
            component.set("v.saveErrors", arrSaveErrors);
    }

    , reverseLookupFromMap:function(component, mapAttrName, searchField, searchValue)
    {
        var mapLookup = component.get(mapAttrName);
        for(var key in mapLookup)
        {
            var obj = mapLookup[key];
            if(obj[searchField] == searchValue)
                return obj;
        }
        // error, not found
        console.error('appAddQualifcationHelper:: ' + searchField + '=' + searchValue+ ', not found');
    }

    /**
     * Lookup the Institution Id from loading
     * @param component
     * @param mapAttrName
     * @param institutionName
     * @param institutionCode
     * @returns {string}
     */
    , reverseLookupInstitutionId:function(component, mapAttrName, institutionName, institutionCode)
    {
        var mapInstitutions = component.get(mapAttrName);

        for(var instId in mapInstitutions)
        {
            var objInstitute = mapInstitutions[instId];
            if(objInstitute.Institution_Name__c == institutionName &&
            objInstitute.Institution_Code__c == institutionCode)
            {
                return instId;
            }
        }

        // if you got here, not found
        console.error('appAddQualifcationHelper:: id for ' + institutionName + ', ' + institutionCode + ', not found');
    }


    /**
     * Clear ALL qualification attributes
     * @param component
     */
    , clearComponentAttributes:function(component)
    {
        // clear to-save variable
        component.set('v.contactQualification', null);

        // not editing
        component.set('v.editingDraft', false);

        // record type
        component.set('v.selectedQualRecordTypeId', null);
        component.set('v.qualTertiaryCountryId', null);
        component.set('v.qualTertiaryCountry', null);
        component.set('v.qualSecondaryCountryId', null);
        component.set('v.qualSecondaryCountry', null);
        component.set('v.qualTertiaryState', null);
        component.set('v.qualSecondaryState', null);

        component.set('v.qualTertiaryName', null);

        component.set('v.tabIdSecondaryType', 'SEC_QUAL_NAME_SEARCH');
        component.set('v.qualSecondaryTypeId', null);
        component.set('v.qualSecondaryTypeOther', null);
        component.set('v.qualAdmissionsName', null);
        component.set('v.qualEnglishTestId', null);
        component.set('v.qualEnglishTestName', null);

        component.set('v.tabIdTertiaryAwardingBody', 'AUS_TER_SEARCH');
        component.set('v.qualTertiaryAwardingBody', null);
        component.set('v.qualTertiaryAwardingBodyOther', null);
        component.set('v.objTertiaryAwardingBody', null);

        component.set('v.currentInstitution', null);        
        component.set('v.mapCurrentInstitutions', null);

        component.set('v.tabIdSecondarySchool', 'AUS_SEC_SEARCH');
        component.set('v.qualSecondarySchool', null);
        component.set('v.qualSecondarySchoolOther', null);
        component.set('v.objSecondarySchool', null);


        component.set('v.qualTertiaryLevelOfCompletion', null);
        component.set('v.qualTertiaryFirstYearEnrolled', null);
        component.set('v.qualTertiaryLastYearEnrolled', null);
        component.set('v.qualTertiaryComments', null);

        component.set('v.qualSecondaryCompleted', null);
        component.set('v.qualSecondaryYearCompleted', null);
        component.set('v.qualSecondaryDateExpected', null);
        component.set('v.qualSecondaryComments', null);
        
        component.set('v.errorMsgSecondaryDateExpected', false);
        //this.clearComponentErrorMessageByName(component, 'inputQualSecondaryDateExpected');

        component.set('v.qualAdmissionsCompleted', null);
        component.set('v.qualAdmissionsDateExpected', null);
        component.set('v.qualAdmissionsDateCompleted', null);
        component.set('v.qualEnglishCompleted', null);
        component.set('v.qualEnglishTestDateCompleted', null);
        component.set('v.qualEnglishTestDateExpected', null);
        component.set('v.errorMsgEnglishTestDateExpected', false);
        //this.clearComponentErrorMessageByName(component, 'inputQualEnglishTestDateExpected');

        //Clears English Score
        this.clearScore(component);
        
        component.set('v.qualAdmissionsComments', null);

        component.set('v.qualTertiaryEnglishOnly', null);
        component.set('v.qualSecondaryEnglishOnly', null);
        component.set('v.qualSecondaryScore', null);
        component.set('v.qualTertiaryGPAResult', null);
        
        var cmpSearchAusQualification = component.find('searchSecondaryAusQualification');
        if(cmpSearchAusQualification)
            cmpSearchAusQualification.clearValues();
        
        var cmpSearchIntlQualification = component.find('searchSecondaryIntlQualification');
        if(cmpSearchIntlQualification)
            cmpSearchIntlQualification.clearValues();
        
        var cmpSearchTerAwardingBody = component.find('searchTertiaryAwardingBody');
        if(cmpSearchTerAwardingBody)
            cmpSearchTerAwardingBody.clearValues();

        var cmpSearchSecSchool = component.find('searchSecondarySchool');
        if(cmpSearchSecSchool)
            cmpSearchSecSchool.clearValues();
    }

    , formatDateString: function(aDate)
    {
        var dd = aDate.getDate();
        var mm = aDate.getMonth() + 1; //January is 0!
        var yyyy = aDate.getFullYear();
        // if date is less then 10, then append 0 before date
        if(dd < 10){
            dd = '0' + dd;
        }
        // if month is less then 10, then append 0 before date
        if(mm < 10){
            mm = '0' + mm;
        }

        var sFormattedDate = yyyy+'-'+mm+'-'+dd;
        return sFormattedDate;
    }

    , isDatePast:function(aDate)
    {
        if(!aDate) {
            // early out, no error
            return false;
        }

        var today = new Date();
        var todayFormattedDate = this.formatDateString(today);
        
        if(aDate < todayFormattedDate)
        {
            console.error(aDate + " < " + todayFormattedDate);
            return true;
        }
        return false;
    }
    
    , debugObject:function(component,objDebug, functionName)
    {
        if(component.get('v.DEBUGGING') == true)
        {
            console.debug(functionName + ':object {');
            for(var k in objDebug)
            {
                console.debug(k + ' : ' + objDebug[k]);
            }
            console.debug('}');
        }
    }
    , debugArray:function(component, arr, functionName)
    {
        if(component.get('v.DEBUGGING') == true)
        {
            console.debug(functionName + ' array :')

            var iLen = arr.length;
            for(var i = 0; i < iLen; ++i)
            {
                var objDebug = arr[i];
                if(objDebug instanceof Object)
                {
                    this.debugObject(component, objDebug, functionName + '[' + i + ']');
                }
                else
                    console.debug('[' + i + ']:' + arr[i]);
            }
            //console.debug(']');
        }
    }

    , clearSaveErrors:function(component)
    {
        component.set('v.showErrors', false);
        component.set('v.saveErrors', []);
    }
    
    , showHideCreditIntention:function(component)
    {
        var qualsHistorical = component.get("v.qualListHistorical");
        
        var showCredit = false;
        for(var i = 0; i < qualsHistorical.length; ++i)
        {
            var objCQ = qualsHistorical[i];

            var recType = objCQ.RecordType;
            if(recType && recType.Name == 'Tertiary Education')
            {
                showCredit = true;
                break;
            }
        }
        
        if(!showCredit)
        {
            var qualsDraft = component.get("v.qualListDraft");
            // loop through drafts
        	for(var i = 0; i < qualsDraft.length; ++i)
            {
                var objCQ = qualsDraft[i];

                var recType = objCQ.RecordType;
                if(recType && recType.Name == 'Tertiary Education')
                {
                    showCredit = true;
                    break;
                }
            }
        }
        
        component.set("v.showCreditIntention", showCredit);
    }
    
    , saveCreditIntention:function(component)
    {
        var creditIntent = component.get("v.creditIntention");
        var appId = component.get("v.applicationId");
        
        var action = component.get("c.saveCreditIntention");
        action.setParams({
            "applicationId":appId,
            "creditIntent":creditIntent
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS')
            {
                var objResponse = response.getReturnValue(); 
            }
        });
        $A.enqueueAction(action);
    },
    saveApplication : function(component, callback) {
        try{
            // start loading
            component.set('v.showSpinner', true);

            // construct application record
            let applicationRecord = {
                Id : component.get("v.applicationId"), 
                English_Language_Proficiency__c : component.get("v.englishLanguageProficiency"),
                Partner_Name__c : component.get("v.institutionName")
            }
            console.log(applicationRecord);
            var action = component.get("c.updateApplication");
            action.setParams({
                "application" : JSON.stringify(applicationRecord)
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state == 'SUCCESS'){
                    var objResponse = response.getReturnValue(); 
                }
                // end loading
                component.set('v.showSpinner', false);            

                if(callback) {
                    callback({
                        "hasError" : false, 
                        "errorMessage" : ""
                    });
                }
            });
            $A.enqueueAction(action);
        }catch(ex){
            console.log(ex);
        }
    },
    getcountryname:  function(component) {
            var selectedId = component.get('v.qualTertiaryCountryId');
            var action = component.get("c.getCountryNameById");
            //set the params for the action
            var objParams = {
                'countryId': selectedId,
                'format': 'Country__c'
            };    

            // pass to controller
            action.setParams(objParams);
            try{
                action.setCallback(this, function(response) {
                    if (response.getState() == "SUCCESS") {
                        // response from server 
                        var objResponse = response.getReturnValue();
                        //set qualTertiaryCountry with the response
                        component.set('v.qualTertiaryCountry',objResponse );
                        console.log('***'+ component.get('v.qualTertiaryCountry'));
                    }
                });
                $A.enqueueAction(action); 
           }catch(ex){
                console.log(ex);
           } 
        }
})