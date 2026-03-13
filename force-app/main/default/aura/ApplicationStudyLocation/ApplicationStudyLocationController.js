/**
 * Created by trentdelaney on 31/8/18.
 */
({
    doInit : function(component, event, helper) {
        // app Id
        var applicationId = helper.parseApplicationId(component);
        if(!applicationId){
            applicationId = component.get("v.applicationId");
        }
        // campus location
        //helper.initCampusLocationOptions(component);

        if (applicationId != '') {
            component.set("v.appId", applicationId);
            helper.initLoad(component, helper, applicationId);
        }
        var studyLocation = component.get("{!v.campusLocation}");

        if (studyLocation != null || studyLocation != '')
        {
            component.set("{!v.campusLocation}", '');
        }
        component.set('v.todaysDate', new Date().toISOString().split('T')[0]);
    }

    , onChangeVisaType:function(component, event, helper)
    {
        var app = component.get("v.app");
        var visaType = app.Visa_Type__c;
        if(visaType)
        {
            component.set("v.visaTypeRequired", true);
        }
        else {
            component.set("v.visaTypeRequired", false);
        }
    }
    
    , setCitizenshipType : function (component, event, helper) {
        component.set("v.studyLocationSpinner", true);        
        var parentComponent = component.get("v.parent");
        parentComponent.changeResidencyStatus(component.get("v.residencyStatus"));
        parentComponent.handleActionCitizen(component.get("v.residencyStatus"));
        

        /***** Start: KL SFTM-216 *****/
        var prevValMap = component.get("v.picklistPrevValues");
        prevValMap["Citizenship Type"] = component.get("v.app.Residency_Status__c");
        helper.checkCitizenshipType(component);
        helper.checkForACPsCitizenshipType(component);
        
        /***** End: KL SFTM-216 *****/
    }

    , onClickSaveCitizenship : function(component, event, helper)
    {
        var params = event.getParam('arguments');
        var callback;
        if (params) {
            callback = params.callback;
        }

   
        var application = component.get("v.app");

        if (helper.isUnsafe(application)) {
            var appErrors = ["One or more input boxes are not in the expected format."];
            component.set("v.saveErrors", appErrors);
            component.set("v.showErrors", true);
            return;
        } 
       
        component.set('v.showSpinner', true);
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

                    //proceed next page
                    if (callback) {
                        callback(objResponse);
                    }
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

    , onClickCloseAlert:function(component, event, helper)
    {
        component.set("v.showErrors", false);
    }

    , closeConfirmCancel:function(component)
    {
        component.set("v.campusLocation", component.get("v.picklistPrevValues")["Study Location"]);
        component.set("v.showConfirmCancel", false);
    }

    , confirmCancel:function(component, event, helper)
    {
        var appId = component.get("v.appId");
        component.set("v.showConfirmCancel", false);
        //Remove ACPs
        var selectedCountry = component.get("v.campusLocation");
        helper.clearACPRecords(component);
        helper.saveStudyLocation(component, appId, selectedCountry);
    }

    /***** Start: KL SFTM-216 *****/
    , closeConfirmCancelCitizenshipType:function(component)
    {
        var lastValue = component.get("v.picklistPrevValues")['Citizenship Type'];
        var citizenshipTypeDropDown = component.find("v.selectCitizenshipType");
        
		component.set("v.residencyStatus", lastValue);
		component.set("v.showConfirmCancelCitizenshipType", false);
        component.set("v.studyLocationSpinner", false);

    }

    , confirmCancelCitizenshipType:function(component, event, helper)
    {
        var appId = component.get("v.appId");
        component.set("v.showConfirmCancelCitizenshipType", false);
        //Remove ACPs
        helper.clearACPRecords(component);
        component.set("v.app.Residency_Status__c", component.get("v.residencyStatus"));
        helper.saveCitizenshipType(component, component.get("v.app.Residency_Status__c"));
    }
    ,handleCheckPermanentResidencyApplication : function (component, event, helper) {
        if(component.find("applyForPermanentResidencyToggle")){
            if(component.find("applyForPermanentResidencyToggle").get("v.checked")){
                component.set("v.applyForResidencyToggle", true);
                component.set("v.app.Applied_For_Permanent_Residency__c", true);
                console.log('toggle '+ component.get("v.app.Applied_For_Permanent_Residency__c"));
                //helper.checkPreviousMonashId(component, event);
            }else{
                component.set("v.applyForResidencyToggle", false);
                component.set("v.app.Applied_For_Permanent_Residency__c", false);

            }
        }

    }

    /***** End: KL SFTM-216 *****/
    , validatePRDateField : function (component, event, helper) {
        if(component.get("v.visaQuestions.appDate ") && component.get("v.applyForResidencyToggle")){
            var applicationPRDate = component.find("datePRApplication");
            var isValid = applicationPRDate.checkValidity();
            if(!isValid){
                applicationPRDate.reportValidity();
                applicationPRDate.setCustomvalidity('Please enter date prior to today');
            }
        }
    }

})