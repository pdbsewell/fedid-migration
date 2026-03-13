({
    doInit : function(component, event, helper) {
        var appId = component.get("v.recordId");

        var customLabel = $A.get("$Label.c.MyAppDigitaryDocumentRequirements");
        component.set("v.customLabelDocumentsHeader", customLabel);

        var customLabelQualHeader =  $A.get("$Label.c.myAppEnglishTestQualificationsHeader");
        component.set("v.customLabelQualificationHeader", customLabelQualHeader);

        var customLabelWorkExp =  $A.get("$Label.c.myAppEnglishTestWorkExperience");
        component.set("v.customLabelWorkExperience", customLabelWorkExp);

        var appName = event.getParam('applicationName')
		var actionStudentDeclaration = component.get("c.retrieveApplication");
		actionStudentDeclaration.setParams({"applicationId" : appId});
		actionStudentDeclaration.setCallback(this, function(response) {
            var state = response.getState();
             if(state === "SUCCESS") {
                 var appRecord = response.getReturnValue();
                 component.set("v.sourcesystem", appRecord.Source_System__c);        
                 component.set("v.applicationName", JSON.stringify(appRecord.Name));                   
                 component.set("v.agentName", JSON.stringify(appRecord.agentName));    
                 $A.enqueueAction(component.get('c.getFeatureToggle')); //calling the myapp feature toggle method to show/hide lwc component        
             }
		});

		$A.enqueueAction(actionStudentDeclaration);   
        },
    handleStepChange : function(component, event) {
        component.set("v.openedStep", event.getParam('stepNumber'));
        if(component.get("v.steps") != null) {
            component.set("v.openedGRStep", component.get("v.steps")[event.getParam('stepNumber')]);
        }            
        //scroll to top
        var scrollPosTop;
        if(component.get("v.scrollPosition") != undefined) {
            document.getElementById("appForm").scrollTop = component.get("v.scrollPosition");
            scrollPosTop = component.get("v.scrollPosition");
        } else {
            document.getElementById("appForm").scrollTop = 0;
            scrollPosTop = 0;
        }
        
        window.scroll({
            top: scrollPosTop, 
            left: 0, 
            behavior: 'smooth'
        });
        component.set("v.scrollPosition", 0);
    },

    /**
    * @description get the feature toggle custom setting value
    * @return n/a
    **/
    getFeatureToggle : function(component) {
        var action = component.get("c.fetchMyAppFeatureToggle");

        action.setCallback(this, function(response){
            if(component.isValid() && response !== null && response.getState() === 'SUCCESS'){
                component.set("v.myAppFeatures", response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    },

    nextPage : function(component, event, helper) {        
        var typeOfStudy =  component.get("v.applicationRecord.Type_of_Study__c");
        let isValid = true;
        if(typeOfStudy === 'Graduate Research') {
            isValid = helper.validateGraduateResearchContactQualifications(component);
        }
        if(isValid === true) {
            component.set("v.navigationEvent", "nextPage");
            var appId = component.get("v.recordId");
            if(component.get("v.openedStep") === 2){
                helper.validatePersonalDetails(component, event, helper)
            }else if(component.get("v.openedStep") === 4 && typeOfStudy !== 'Graduate Research'){
                helper.validateAppAddQualification(component, event, helper)
            }else if(component.get("v.openedStep") === 6){
                helper.validateDocuments(component, event, helper)
            }else{
                helper.progressStatus(component, appId, 'Forward',helper);
            }
        }
    },
    saveandExit : function(component, event, helper) {
        var typeOfStudy =  component.get("v.applicationRecord.Type_of_Study__c");
        let isValid = true;
        if(typeOfStudy === 'Graduate Research') {
            isValid = helper.validateGraduateResearchContactQualifications(component);
        }
        if(isValid === true) { 
            var appId = component.get("v.recordId");
            component.set("v.navigationEvent", "saveandExit");
            helper.savendExit(component, appId, 'Forward',helper);
        }
        
    },
    previousPage : function(component, event, helper) {
        var appId = component.get("v.recordId");
        helper.progressStatus(component, appId, 'Backward',helper);
    },
    onClickCloseAlert: function(component, event, helper) {
        component.set("v.locationError", false);
        component.set("v.validationError", false);
    },
    changeSection : function(component, event, helper){
        var params = event.getParam('arguments');
        if (params) {            
            var navigationComponentAura = component.find('navigationComponent');
            var navigationComponentLWC = navigationComponentAura.getElement();
            var section = params.sectionName;
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
                            9: 'Submit',
                            10: 'Receipt'};

            switch(section) {             
                case 'Personal Details':
                    component.set("v.openedStep", 2);
                    navigationComponentLWC.checkFurthest(stepMap[2]);
                    break;
                case 'Access and Equity':
                    component.set("v.openedStep", 2);
                    navigationComponentLWC.checkFurthest(stepMap[2]);
                    break;
  				case 'Citizenship':
                        component.set("v.openedStep", 2);
                        navigationComponentLWC.checkFurthest(stepMap[2]);
                        break;
                case 'Study Preferences':
                    component.set("v.openedStep", 3);
                    navigationComponentLWC.checkFurthest(stepMap[3]);
                    break;
                case 'Qualifications & Work Experience':
                    component.set("v.openedStep", 4);
                    navigationComponentLWC.checkFurthest(stepMap[4]);
                    break;
                case 'Sponsorship':
                    component.set("v.openedStep", 5);
                    navigationComponentLWC.checkFurthest(stepMap[5]);
                    break;
                case 'Documents':
                    component.set("v.openedStep", 6);
                    navigationComponentLWC.checkFurthest(stepMap[6]);
                    break;
                case 'payment':
                    component.set("v.openedStep", 8);
                    navigationComponentLWC.checkFurthest(stepMap[8]);
                    break;
                case 'receipt':
                    component.set("v.openedStep", 10);
                    navigationComponentLWC.checkFurthest(stepMap[10]);
                    break;
            }
                
            }else{

                stepMap = { 
                            1: 'Declaration',
                            2: 'Personal Details',
                            3: 'Application Details',
                            4: 'Research Program',
                            5: 'English Proficiency',
                            6: 'Qualifications',
                            7: 'Awards, Prizes & Scholarship', 
                            8: 'Employment & Research Experience', 
                            9: 'Publications', 
                            10: 'Creative Works',
                            11: 'Music',
                            12: 'Theatre Performance',
                            13: 'Exhibitions',
                            14: 'Additional Supporting Information',
                            15: 'Agent',
                            16: 'Referees',
                            17: 'Documents',
                            18: 'Validate & Submit'};

                switch(section) {             
                    case 'Personal Details':
                        component.set("v.openedStep", 2);
                        navigationComponentLWC.checkFurthest(stepMap[2]);
                        break;
                    case 'Access and Equity':
                        component.set("v.openedStep", 2);
                        navigationComponentLWC.checkFurthest(stepMap[2]);
                        break;
                    case 'Citizenship':
                        component.set("v.openedStep", 2);
                        navigationComponentLWC.checkFurthest(stepMap[2]);
                        break;
                    case 'Application Details':
                        component.set("v.openedStep", 3);
                        navigationComponentLWC.checkFurthest(stepMap[3]);
                        break;
                    case 'Research Program':
                        component.set("v.openedStep", 4);
                        navigationComponentLWC.checkFurthest(stepMap[4]);
                        break;
                    case 'English Proficiency':
                        component.set("v.openedStep", 5);
                        navigationComponentLWC.checkFurthest(stepMap[5]);
                        break;
                    case 'Qualifications':
                        component.set("v.openedStep", 6);
                        navigationComponentLWC.checkFurthest(stepMap[6]);
                        break;
                    case 'Awards, Prizes & Scholarship':
                        component.set("v.openedStep", 7);
                        navigationComponentLWC.checkFurthest(stepMap[8]);
                        break;
                    case 'Employment & Research Experience':
                        component.set("v.openedStep", 8);
                        navigationComponentLWC.checkFurthest(stepMap[10]);
                        break;
                    case 'Publications':
                        component.set("v.openedStep", 9);
                        navigationComponentLWC.checkFurthest(stepMap[10]);
                        break;
                    case 'Creative Works':
                        component.set("v.openedStep", 10);
                        navigationComponentLWC.checkFurthest(stepMap[11]);
                        break;
                    case 'Music':
                        component.set("v.openedStep", 11);
                        navigationComponentLWC.checkFurthest(stepMap[12]);
                        break;
                    case 'Theatre Performance':
                        component.set("v.openedStep", 12);
                        navigationComponentLWC.checkFurthest(stepMap[13]);
                        break;
                    case 'Exhibitions':
                        component.set("v.openedStep", 13);
                        navigationComponentLWC.checkFurthest(stepMap[14]);
                        break;
                    case 'Additional Supporting Information':
                        component.set("v.openedStep", 14);
                        navigationComponentLWC.checkFurthest(stepMap[15]);
                        break;
                    case 'Agent':
                        component.set("v.openedStep", 15);
                        navigationComponentLWC.checkFurthest(stepMap[16]);
                        break;
                    case 'Referees':
                        component.set("v.openedStep", 16);
                        navigationComponentLWC.checkFurthest(stepMap[9]);
                        break;
                    case 'Documents':
                        component.set("v.openedStep", 17);
                        navigationComponentLWC.checkFurthest(stepMap[17]);
                        break;
                    case 'Validate & Submit':
                        component.set("v.openedStep", 18);
                        navigationComponentLWC.checkFurthest(stepMap[18]);
                        break;
                }
            }

           
        }
    },
    changeApplicationName : function(component, event, helper){     
        component.set("v.applicationName", event.getParam('applicationName'));
    },
    navigateToHomePage : function(component, event, helper){
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/",
          "isredirect" :false
        });
        urlEvent.fire();
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            // record is loaded (render other component which needs record data value)
            component.set("v.originalApplicantPrivacyConfirmation", component.get("v.applicationRecord").Applicant_Privacy_Confirmation__c);
            component.set("v.applicantPrivacyConfirmation", component.get("v.applicationRecord").Applicant_Privacy_Confirmation__c);
            let typeOfStudy = component.get("v.applicationRecord").Type_of_Study__c;
            if (typeOfStudy === 'Study Abroad' || typeOfStudy === 'Exchange'){
                component.set("v.documentsSubtitle", "To speed up processing of your application, upload your supporting evidence below. Please upload specific documents for Proof of residency and Secondary/Tertiary Qualifications, instead of using generic ‘Other Document types'");
            } 
            if(typeOfStudy == 'Graduate Research'){
                component.set("v.documentsSubtitle", "To enable us to review your application you must upload the required supporting documentation here before submitting your application. If we need additional documentation you will be contacted by email and you will be able to come back to this portal to upload it.");
            }
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    }, 
    onApplicantConfirmation : function(component, event, helper) {
        var checkbox = event.getSource();
        var newValue = checkbox.get("v.checked");
        component.set("v.applicantPrivacyConfirmation", newValue);
    },

    handleSaveSuccessEventGR: function (component, event) {
        let saveSuccess = event.getParam("saveSuccess");
        component.set("v.navigationDisabled", false);
        if(saveSuccess === true) {
            if(component.get("v.navigationEvent") === 'nextPage') {
                let newStep;
                newStep = component.get("v.openedStep") + 1; 
                component.set("v.openedStep", newStep);
                component.set("v.openedGRStep", component.get("v.steps")[newStep]);
                var navigationComponentAura = component.find('navigationComponent');
                var navigationComponentLWC = navigationComponentAura.getElement();
                var stepMap = component.get("v.steps")
                navigationComponentLWC.checkFurthest(stepMap[newStep]);
            } else {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                "url": "/",
                "isredirect" :false
                });
                urlEvent.fire();
            }
            
        }
    },
    /**
    * @description handle the reform steps event when the course is added
    * @return n/a
    **/
    handleSteps: function (component, event, helper) {
        var stepName = event.getParam('stepName');
        component.set("v.scrollPosition", window.scrollY);
        if(stepName == '' || stepName == undefined || stepName == null) {
            stepName = 'Research Program';
            component.set("v.scrollPosition", 0);
        }
        var navigationComponentAura = component.find('navigationComponent');
        var navigationComponentLWC = navigationComponentAura.getElement();
        navigationComponentLWC.callbackFromCourseToVerifySteps(stepName);
    },
    /**
    * @description handle the onloadapp event when myGRSidebar component is loaded
    *               it forms the steps object for the navigation component
    * @return n/a
    **/
    setInitSteps: function (component, event) {
        component.set("v.steps", event.getParam("stepMap"))
    },
})