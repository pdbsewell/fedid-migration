({
    progressStatus : function(component, appId, direction) {
        //if personal details call server method
        if(component.get("v.openedStep") == 1 ){                                 
            //call save my details    
            var childCmp = component.find("childPersonalDetails");
            childCmp.saveDetailsFromPartner(function(response){
            });
                   
            var newStep = 1; // SFTG-2015 Validations will not block Page navigations
            if(direction == 'Backward'){
                newStep = component.get("v.openedStep") - 1;                
            }else if(direction == 'Forward'){
                newStep = component.get("v.openedStep") + 1;     
            }
            component.set("v.openedStep", newStep);
            
            var navigationComponentAura = component.find('navigationComponent');
            var navigationComponentLWC = navigationComponentAura.getElement();
            var stepMap = component.get("v.stepMap");
            if(navigationComponentLWC) {
                navigationComponentLWC.checkFurthest(stepMap[newStep]);
            }                        
            
            $A.enqueueAction(action);
        } else if(component.get("v.openedStep") == 2 ) {
            component.set("v.navigationDisabled", false);
            
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
                        component.set("v.durationError", 'Please specify Duration of Study');
                    }else{
                        component.set("v.durationError", '');
                    }
                        
                    var upChkAction = component.get("c.validateStudyPlans");
                    upChkAction.setParams({
                        "appId" : appId
                    });
                    upChkAction.setCallback(this, function(response){
                        var state = response.getState();
                        if(state === "SUCCESS"){
                            let objResp = response.getReturnValue();
                            if(objResp.ACPSelection && objResp.ACPSelection.length>0) {
                                component.set("v.courseSelectionError", 'Please select a valid course');
                                component.set("v.sendToStudentDisabled", true);
                            /*}else if (objResp.UnitPreferenceSelection && objResp.UnitPreferenceSelection.length>0) {
                                //component.set("v.navigationDisabled", true);
                                //component.set("v.validationError", true);
                                //component.set("v.validationHeader",'Unit Preference Selection');
                                component.set("v.courseSelectionError", objResp.UnitPreferenceSelection);
                                //component.set("v.validationMessage", objResp.UnitPreferenceSelection);
                                component.set("v.navigationDisabled", false);
                                component.set("v.sendToStudentDisabled", true);*/
                            }else {
                                component.set("v.courseSelectionError", '');
                            }
                        } else {
                            component.set("v.courseSelectionError", 'Error validating Course');
                        }
                        this.handleErrors(component);
                    }); 
                    $A.enqueueAction(upChkAction);  
                    var newStep = 2;
                    if(direction == 'Backward'){
                        newStep = component.get("v.openedStep") - 1;                
                    }else if(direction == 'Forward'){
                        newStep = component.get("v.openedStep") + 1;     
                    }
                    component.set("v.openedStep", newStep);
                    var navigationComponentAura = component.find('navigationComponent');
                    var navigationComponentLWC = navigationComponentAura.getElement();
                    var stepMap = component.get("v.stepMap");
                    if(navigationComponentLWC) {
                        navigationComponentLWC.checkFurthest(stepMap[newStep]);
                    }
                }else{
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("1 Error message: " + errors[0].message);
                        }
                    } 
                }
            });
            $A.enqueueAction(action);
        }else{
            var newStep;
            if(direction == 'Backward'){
                newStep = component.get("v.openedStep") - 1;                
            }else if(direction == 'Forward'){
                newStep = component.get("v.openedStep") + 1;     
            }
            component.set("v.openedStep", newStep);

            var navigationComponentAura = component.find('navigationComponent');
            var navigationComponentLWC = navigationComponentAura.getElement();
            var stepMap = component.get("v.stepMap");
            if(navigationComponentLWC) {
                navigationComponentLWC.checkFurthest(stepMap[newStep]);
            }
        }
    },
    savendExit : function(component, appId, direction) {
        //if personal details call server method
        if(component.get("v.openedStep") == 1 && direction == 'Forward'){
           
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
        }else{
            var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                "url": "/",
                "isredirect" :false
                });
                urlEvent.fire();
            }
    },
    handleChildEvt:function(component, event, helper){
        component.set("v.navigationDisabled", true);
        var goTo = event.getParam("status");
       
        if(goTo =='success')
        {
            component.set("v.studydurationfilled",true);
        }else{
            component.set("v.studydurationfilled",false);

        }
        component.set("v.navigationDisabled", false);
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
    sendToStudent:function(component, event, helper){   
        //disable navigation
        component.set("v.navigationDisabled", true);     
        var appId = component.get("v.recordId");

        var action = component.get("c.generateUserResetApplicationProgressStatus");
        action.setParams({
            "applicationId" : appId
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var objResponse = response.getReturnValue();
                if(objResponse.result === 'OK'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success",
                        "message": "The applicant will receive my.app welcome email to continue their application."
                    });
                    toastEvent.fire();

                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": appId
                    });
                    navEvt.fire();                  
                } else if(objResponse.status === 'ERROR') {
                    //show alert
                    var errorMessage = objResponse.message;
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Unexpected Error",
                        "message": errorMessage
                    });
                    toastEvent.fire();
                } else {                        
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
    handleErrors :function(component){ 
        // Handling of Error Messages at various stages
        var durError = component.get("v.durationError");
        var acpError = component.get("v.courseSelectionError");
        var sendError = "Duration of Study AND Course Preference needs to be selected for the Send to Student button to be enabled";
        if (durError !== '' && acpError === '') {
            component.set("v.sendToStudentErrorMessage", durError);
            component.set("v.sendToStudentDisabled", true);
        }
        if (durError === '' && acpError !== '') {
            component.set("v.sendToStudentErrorMessage", acpError);
            component.set("v.sendToStudentDisabled", true);
        }
        if (durError !== '' && acpError !== '') {
            component.set("v.sendToStudentErrorMessage", sendError);
            component.set("v.sendToStudentDisabled", true);
        }
        if (durError == '' && acpError == '') {
            component.set("v.sendToStudentErrorMessage", '');
            component.set("v.sendToStudentDisabled", false);
        }
    }
})