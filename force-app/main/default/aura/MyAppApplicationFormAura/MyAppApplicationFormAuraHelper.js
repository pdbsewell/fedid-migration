({
    progressStatus : function(component, appId, direction, helper) {
        //if personal details call server method
        if(component.get("v.openedStep") == 2 && direction == 'Forward'){
            //disable navigation
            component.set("v.navigationDisabled", true);

            component.set("v.locationError", false);
            var action = component.get("c.ProcessStatus");
            action.setParams({
                "appId" : appId,
                "direction" : direction
            });
            action.setCallback(this, function(response){
                var state = response.getState();

                if(state === "SUCCESS"){
                    var objResponse = response.getReturnValue();
                    if(objResponse.status === 'ValidationError' && objResponse.header && objResponse.message){
                        component.set("v.validationError", true);
                        component.set("v.validationHeader", objResponse.header);
                        component.set("v.validationMessage", objResponse.message);
                        
                    } else if(objResponse.status === 'Error' && objResponse.message === 'Not Australia')
                    {
                        // show alert
                        component.set("v.textType", true);
                        component.set("v.locationError", true);
                    }else if(objResponse.status === 'Error' && objResponse.message === 'Empty'){
                        component.set("v.textType", false);
                        component.set("v.locationError", true);
                    }
                    else
                    {                        
                        //call save my details    
                        var childCmp = component.find("childPersonalDetails");
                        childCmp.saveDetails(function(response){
                            var newStep;
                            if(direction == 'Backward'){
                                newStep = component.get("v.openedStep") - 1;                
                            }else if(direction == 'Forward'){
                                newStep = component.get("v.openedStep") + 1;     
                            }
                            component.set("v.openedStep", newStep);
                            if(component.get("v.steps") != null) { 
                                component.set("v.openedGRStep", component.get("v.steps")[newStep]);
                            }
                            var navigationComponentAura = component.find('navigationComponent');
                            var navigationComponentLWC = navigationComponentAura.getElement();
                            var typeOfStudy =  component.get("v.applicationRecord.Type_of_Study__c");
                            var stepMap = [];
                            if(typeOfStudy != 'Graduate Research'){
                                stepMap = { 1: 'Declaration', 
                                                2: 'Personal Details',
                                                3: 'Study Preferences',
                                                4: 'Credentials',
                                                5: 'Scholarship',
                                                6: 'Documents',
                                                7: 'Review',
                                                8: 'Application Fee',
                                                9: 'Submit'};
                            }else{
                                stepMap = component.get("v.steps")
                            }
                            navigationComponentLWC.checkFurthest(stepMap[newStep]);                        
                        });
                    }

                    //enable navigation
                    component.set("v.navigationDisabled", false);
                }
            });

            $A.enqueueAction(action);
        } else if(component.get("v.openedStep") == 3 && direction == 'Forward') {
            var navigationComponentAura = component.find('navigationComponent');
            var navigationComponentLWC = navigationComponentAura.getElement();
            var stepMap = component.get("v.steps")
            if(component.get("v.applicationRecord.Type_of_Study__c") == 'Graduate Research'){
                component.set("v.navigationDisabled", true);
                let newStep;
                if(direction == 'Backward') {
                    newStep = component.get("v.openedStep") - 1; 
                    component.set("v.openedStep", newStep);
                    if(component.get("v.steps") != null) { 
                        component.set("v.openedGRStep", component.get("v.steps")[newStep]);
                    }  
                    navigationComponentLWC.checkFurthest(stepMap[newStep]);               
                }else if(direction == 'Forward') {
                    if(helper.checkIfHasACP(component)){
                        component.set("v.navigationDisabled", false);
                        let newStep = component.get("v.openedStep") + 1; 
                        component.set("v.openedStep", newStep);
                        if(component.get("v.steps") != null) {
                            component.set("v.openedGRStep", component.get("v.steps")[newStep]);
                            navigationComponentLWC.checkFurthest(stepMap[newStep]);
                        }
                    }else{
                        helper.validateAndSaveMyGRAppAddCourse(component);
                    }  
                }

            }else{
            
                //disable navigation
                component.set("v.navigationDisabled", true);

                var action = component.get("c.isValidDurationStudy");
                action.setParams({
                    "appId" : appId,
                });
                action.setCallback(this, function(response){
                    var state = response.getState();
                    if(state === "SUCCESS"){
                        var objResponse = response.getReturnValue();
                        if(objResponse) {
                            component.set("v.studydurationfilled", true);
                        }

                        if(!component.get("v.studydurationfilled")){
                            component.set("v.navigationDisabled", true);
                            component.set("v.validationError", true);
                            component.set("v.validationHeader",'Duration of Study');
                            component.set("v.validationMessage", 'Please specify Duration of Study');
                            component.set("v.navigationDisabled", false);
                        }else{
                            //disable navigation
                            component.set("v.navigationDisabled", true);

                            var upChkAction = component.get("c.validateStudyPlans");
                            upChkAction.setParams({
                                "appId" : appId
                            });
                            upChkAction.setCallback(this, function(response){
                                var state = response.getState();
                                if(state === "SUCCESS"){
                                    let objResp = response.getReturnValue();
                                    if(objResp.UnitPreferenceSelection && objResp.UnitPreferenceSelection.length>0)
                                    {
                                        component.set("v.navigationDisabled", true);
                                        component.set("v.validationError", true);
                                        component.set("v.validationHeader",'Unit Preference Selection');
                                        component.set("v.validationMessage", objResp.UnitPreferenceSelection);
                                        component.set("v.navigationDisabled", false);
                                    } else if (objResp.ACPSelection && objResp.ACPSelection.length > 0) { //SFTG-2544 Added to mandate ACP selection by the Applicant
                                        component.set("v.navigationDisabled", true);
                                        component.set("v.validationError", true);
                                        component.set("v.validationHeader", 'Course Preference Selection');
                                        component.set("v.validationMessage", objResp.ACPSelection);
                                        component.set("v.navigationDisabled", false);
                                    }else{
                                        var newStep;
                                        if(direction == 'Backward'){
                                            newStep = component.get("v.openedStep") - 1;                
                                        }else if(direction == 'Forward'){
                                            newStep = component.get("v.openedStep") + 1;     
                                        }
                                        component.set("v.openedStep", newStep);
                                        if(component.get("v.steps") != null) { 
                                            component.set("v.openedGRStep", component.get("v.steps")[newStep]);
                                        }
                                        var navigationComponentAura = component.find('navigationComponent');
                                        var navigationComponentLWC = navigationComponentAura.getElement();
                                        var typeOfStudy =  component.get("v.applicationRecord.Type_of_Study__c");
                                        var stepMap = [];
                                        if(typeOfStudy != 'Graduate Research'){
                                            stepMap = { 1: 'Declaration', 
                                                            2: 'Personal Details',
                                                            3: 'Study Preferences',
                                                            4: 'Credentials',
                                                            5: 'Scholarship',
                                                            6: 'Documents',
                                                            7: 'Review',
                                                            8: 'Application Fee',
                                                            9: 'Submit'};
                                        }else{
                                            stepMap = component.get("v.steps")
                                        }
                                        navigationComponentLWC.checkFurthest(stepMap[newStep]);
                                    }
                                }
                                //enable navigation
                                component.set("v.navigationDisabled", false);
                            }); 
                            $A.enqueueAction(upChkAction);  
                        }
                    }else{
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                // do nothing
                            }
                        } 
                    }
                    //enable navigation
                    component.set("v.navigationDisabled", false);
                });
               
            }
            $A.enqueueAction(action);
          
        } else if(component.get("v.openedStep") == 5 && 
        component.get("v.applicationRecord.Type_of_Study__c") == 'Graduate Research') {
            let newStep;
            if(direction == 'Backward') {
                newStep = component.get("v.openedStep") - 1; 
                component.set("v.openedStep", newStep);
                if(component.get("v.steps") != null) {
                    component.set("v.openedGRStep", component.get("v.steps")[newStep]);
                }                

                var navigationComponentAura = component.find('navigationComponent');
                var navigationComponentLWC = navigationComponentAura.getElement();
                
                var stepMap = component.get("v.steps")
                navigationComponentLWC.checkFurthest(stepMap[newStep]);               
            } else if(direction === 'Forward') {
                helper.validateAndSaveMyGRAppEnglishProficiency(component);  
            }
        } else if(component.get("v.openedGRStep") == 'Agent' && 
        component.get("v.applicationRecord.Type_of_Study__c") == 'Graduate Research') {
            let newStep;
            if(direction == 'Backward') {
                newStep = component.get("v.openedStep") - 1; 
                component.set("v.openedStep", newStep);

                var navigationComponentAura = component.find('navigationComponent');
                var navigationComponentLWC = navigationComponentAura.getElement();
                var stepMap = component.get("v.steps")
                navigationComponentLWC.checkFurthest(stepMap[newStep]);               
            } else if(direction === 'Forward') {
                if(helper.validateAndSaveAgent(component)) {
                    let newStep = component.get("v.openedStep") + 1; 
                    component.set("v.openedStep", newStep);
                    if(component.get("v.steps") != null) {
                        component.set("v.openedGRStep", component.get("v.steps")[newStep]);
                    }
                }  
            }
        }
        else if(component.get("v.openedStep") == 4 && 
            component.get("v.applicationRecord.Type_of_Study__c") == 'Graduate Research') {
            let newStep;
            let isValid = true;
            let myGRAppResearchProgramComponent = component.find('myGRResearchProgram');
            let myGRAppResearchProgramLWC = myGRAppResearchProgramComponent.getElement(); 
            if(direction == 'Backward') {
                newStep = component.get("v.openedStep") - 1; 
                component.set("v.openedStep", newStep);
                if(component.get("v.steps") != null) { 
                    component.set("v.openedGRStep", component.get("v.steps")[newStep]);
                }                
                var navigationComponentAura = component.find('navigationComponent');
                var navigationComponentLWC = navigationComponentAura.getElement();
                var stepMap = component.get("v.steps")
                navigationComponentLWC.checkFurthest(stepMap[newStep]);               
            }else if(direction == 'Forward') {
                helper.validateAndSaveMyGRResearchProgram(component);
            }
        
        }else{  
            var newStep;
            if(direction == 'Backward'){
                newStep = component.get("v.openedStep") - 1;                
            }else if(direction == 'Forward'){
                newStep = component.get("v.openedStep") + 1;     
            }
            component.set("v.openedStep", newStep);
            if(component.get("v.steps") != null) { 
                component.set("v.openedGRStep", component.get("v.steps")[newStep]);
            }

            var navigationComponentAura = component.find('navigationComponent');
            var navigationComponentLWC = navigationComponentAura.getElement();
            if(component.get("v.applicationRecord.Type_of_Study__c") != 'Graduate Research'){
                var stepMap = { 1: 'Declaration', 
                                2: 'Personal Details',
                                3: 'Study Preferences',
                                4: 'Credentials',
                                5: 'Scholarship',
                                6: 'Documents',
                                7: 'Review',
                                8: 'Application Fee',
                                9: 'Submit'};
            }else{
                var stepMap = component.get("v.steps")
            }
            navigationComponentLWC.checkFurthest(stepMap[newStep]);
        }
    },

     savendExit : function(component, appId, direction, helper) {
        //if personal details call server method
        if(component.get("v.openedStep") == 2 && direction == 'Forward'){
           
            //disable navigation
            component.set("v.navigationDisabled", true);
            component.set("v.locationError", false);
            var action = component.get("c.ProcessStatus");
            action.setParams({
                "appId" : appId,
                "direction" : direction
            });

            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === "SUCCESS"){
                    var objResponse = response.getReturnValue();
                    if(objResponse.status === 'ValidationError' && objResponse.header && objResponse.message){
                        component.set("v.validationError", true);
                        component.set("v.validationHeader", objResponse.header);
                        component.set("v.validationMessage", objResponse.message);
                        
                    } else if(objResponse.status === 'Error' && objResponse.message === 'Not Australia')
                    {
                        // show alert
                        component.set("v.textType", true);
                        component.set("v.locationError", true);
                    }else if(objResponse.status === 'Error' && objResponse.message === 'Empty'){
                        component.set("v.textType", false);
                        component.set("v.locationError", true);
                    }
                    else
                    {                        
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": "/",
                            "isredirect" :false
                            });
                        urlEvent.fire();
                    }

                                
                    //enable navigation
                    component.set("v.navigationDisabled", false);
                }
            });
            $A.enqueueAction(action);
        } else if(component.get("v.applicationRecord.Type_of_Study__c") === 'Graduate Research' && 
            component.get("v.openedStep") === 5) {
            helper.validateAndSaveMyGRAppEnglishProficiency(component);  
        } else if(component.get("v.applicationRecord.Type_of_Study__c") === 'Graduate Research' && 
            component.get("v.openedGRStep") == 'Agent') {
            helper.validateAndSaveAgent(component);  
        } else if(component.get("v.applicationRecord.Type_of_Study__c") === 'Graduate Research' && 
            component.get("v.openedStep") === 4) {
            helper.validateAndSaveMyGRResearchProgram(component);   
            var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                "url": "/",
                "isredirect" :false
                });
            urlEvent.fire();
            
        }else if(component.get("v.applicationRecord.Type_of_Study__c") === 'Graduate Research' && 
        component.get("v.openedStep") === 3){
            if(helper.checkIfHasACP(component)){
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                "url": "/",
                "isredirect" :false
                });
                urlEvent.fire();
            }else{
            helper.validateAndSaveMyGRAppAddCourse(component);
            }  
        }else{
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
            "url": "/",
            "isredirect" :false
            });
            urlEvent.fire();
        }
    },
  
    validatePersonalDetails : function(component, event, helper){
        var appId = component.get("v.recordId");
        let hasMissingFields = true;

        //check if the personal details component has missing fields
        var childCmp = component.find("childPersonalDetails");
        childCmp.validateAllFields(function(result){   
            let hasError = result.hasError;
            let errorMessage = result.errorMessage;
            if(hasError){
                component.set("v.validationError", true);
                component.set("v.validationHeader", 'Missing Required Fields');
                component.set("v.validationMessage", errorMessage);
            }else{
                helper.progressStatus(component, appId, 'Forward');
            }
        });

        return hasMissingFields;
    },
    validateAppAddQualification : function(component, event, helper){
        var appId = component.get("v.recordId");
        let hasMissingFields = true;

        //check if the personal details component has missing fields
        //var childCmp = component.find("childAppAddQualification1");
        var isEducationHistoryLWCEnglish = component.get("v.myAppFeatures.English_Verification__c");
        var isCoursework = component.get("v.applicationRecord.Type_of_Study__c");
        var childCmp;
        if(isEducationHistoryLWCEnglish && isCoursework === 'Coursework'){
                childCmp = component.find("childAppAddQualificationNewLWC");
            }else{
            childCmp = component.find("childAppAddQualificationLWC");
            }

        childCmp.validateFields(function(result){  
            let hasError = result.hasError;
            let errorMessage = result.errorMessage;
            if(hasError){
                component.set("v.validationError", true);
                component.set("v.validationHeader", 'Missing Required Fields');
                component.set("v.validationMessage", errorMessage);
            }else{
                helper.progressStatus(component, appId, 'Forward');
            }
        });

        return hasMissingFields;
    },
    validateDocuments : function(component, event, helper){
        var appId = component.get("v.recordId");
        let hasMissingFields = true;
        //check if the applicant has uploaded the following mandatory documents
        // 1. Proof of Residency / Passport MUST be uploaded
        // 2. Educational History entries MUST have document uploaded

        var action = component.get("c.validateApplicantDocuments");
        action.setParams({
            "applicationId": appId,
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var objResponse = response.getReturnValue();
                if (objResponse.status === 'ValidationError' && objResponse.header && objResponse.message) {
                    component.set("v.validationError", true);
                    component.set("v.validationHeader", objResponse.header);
                    component.set("v.validationMessage", objResponse.message);
                } else {
                    helper.progressStatus(component, appId, 'Forward');
                } 
                //enable navigation
                component.set("v.navigationDisabled", false);
            }
        });
        $A.enqueueAction(action);
        return hasMissingFields;
    },
    updateApplication:function(component, event, helper){
        //disable navigation
        component.set("v.navigationDisabled", true);     
        var appId = component.get("v.recordId"); 
        var partnerPrivacyConfirmation = component.get("v.partnerPrivacyConfirmation");

        var action = component.get("c.updateApplicationRecord");
        action.setParams({
            "recordJSON" : JSON.stringify({
                "Id" : appId,
                "Partner_Privacy_Confirmation__c" : partnerPrivacyConfirmation
            }),

        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var objResponse = response.getReturnValue();
                if(objResponse.RESULT === 'SUCCESS'){
                    
                    helper.progressStatus(component, appId, 'Forward');

                } else if(objResponse.RESULT === 'ERROR') {
                    //show alert
                    var errorMessage = objResponse.MESSAGE;
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Unexpected Error",
                        "message": errorMessage
                    });
                    toastEvent.fire();
                }
                
                //enable navigation
                component.set("v.navigationDisabled", false);
            }
        });
        $A.enqueueAction(action);
    },

    validateAndSaveMyGRAppEnglishProficiency: function(component){ 
        let myGRAPPEnglishProficiencyComponent = component.find('myGRAPPEnglishProficiency');
        let myGRAPPEnglishProficiencyLWC = myGRAPPEnglishProficiencyComponent.getElement(); 
        let isValid = myGRAPPEnglishProficiencyLWC.checkValidity();
        if(isValid === true) {
            myGRAPPEnglishProficiencyLWC.saveEnglishProficiencyQualification();
        }  
    },

    validateAndSaveMyGRResearchProgram: function(component){ 
        let myGRResearchComponent = component.find('myGRResearchProgram');
        let myGRResearchProgramLWC = myGRResearchComponent.getElement(); 
        let isValid = myGRResearchComponent.checkValidity();
        if(isValid === true) {
            myGRResearchProgramLWC.saveResearchProgram();
        }  
    },

    validateAndSaveMyGRAppAddCourse: function(component){ 
        let myGRAppAddCourseComponent = component.find('myGRAppAddCourse');
        let myGRAppAddCourseLWC = myGRAppAddCourseComponent.getElement(); 
        let isValid = myGRAppAddCourseComponent.checkValidity();
        if(isValid === true){
            myGRAppAddCourseLWC.addCourseOfferings();
        }else{
            component.set("v.navigationDisabled", false);
        }
    },

    checkIfHasACP: function(component){ 
        let myGRAppAddCourseComponent = component.find('myGRAppAddCourse');
        let myGRAppAddCourseLWC = myGRAppAddCourseComponent.getElement(); 
        let isValid = myGRAppAddCourseComponent.checkIfHasACPS();
        return isValid;
    },

    validateAndSaveAgent: function(component){ 
        let myGRAgent = component.find('myGRAPPAgent');
        component.set("v.navigationDisabled", true);
        
        if(!myGRAgent.handleUpdate()){
            component.set("v.navigationDisabled", false);
            return false
        }
        component.set("v.navigationDisabled", false);
    },

    validateGraduateResearchContactQualifications : function(component) {
        let componentName;
        let activeStep = component.get("v.openedGRStep");
        let isValid = true;
        switch(activeStep) {
            case 'Awards, Prizes & Scholarship':
                componentName = 'myGRAppAddAwardsAndScholarships';
                break;
            case 'Employment & Research Experience':
                componentName = 'myGRAppEmploymentExperience';
                break;
            case 'Publications':
                componentName = 'myGRAppAddPublications';
                break;
            case 'Creative Works':
                componentName = 'myGRAppAddCreativeWorks';
                break;
            case 'Music':
                componentName = 'myGRAppAddMusic';
                break;
            case 'Theatre Performance':
                componentName = 'myGRAppAddTheatrePerformance';
                break;
            case 'Exhibitions':
                componentName = 'myGRAppAddExhibitions';
                break;
            case 'Additional Supporting Information':
                componentName = 'myGRAppMiscellaneousItems';
                break;
            case 'Referees':
                componentName = 'myGRAppAddReferee';
                break;
            case 'Qualifications':
                componentName='myGRAppAddQualification';
                break;
            case 'Documents':
                componentName='myDocuments';
                break;    
        }
        try{
            if(componentName) {
                let componentInstance = component.find(componentName);
                let componentLWC = componentInstance.getElement(); 
                isValid = componentLWC.validateDeclaration();
            }
        }
        catch(error){

        }
        return isValid;
    },
})