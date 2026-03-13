({
    doInit : function(component, event, helper) { //SFTG-2015 Send to Student button enable/disable based on Duration & ACP selection
        // Partner lands in Course Preferences page upon creation of Application
        var appId = component.get("v.recordId");
        component.set("v.openedStep",2);
        $A.enqueueAction(component.get('c.getFeatureToggle')); //calling the myapp feature toggle method to show/hide lwc component
        // Send to Student will be disabled till Duration & Course is selected
        helper.progressStatus(component, appId, 'Stay');
    },

    /**
    * @description get the feature toggle custom setting value
    * @return n/a
    **/
    getFeatureToggle : function(component) {
        var action = component.get("c.fetchMyAppFeatureToggle");

        action.setCallback(this, function(response){
            if(component.isValid() && response !== null && response.getState() == 'SUCCESS'){
                component.set("v.myAppFeatures", response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    },

    handleStepChange : function(component, event) {
        component.set("v.openedStep", event.getParam('stepNumber'));
        //scroll to top
        document.getElementById("appForm").scrollTop = 0;
        window.scroll({
            top: 0, 
            left: 0, 
            behavior: 'smooth'
        });
    },
  
    nextPage : function(component, event, helper) {
        var appId = component.get("v.recordId");

        //if personal details call server method
        /*if(component.get("v.openedStep") === 1){
            let hasPrivacyConfirmed = component.get("v.partnerPrivacyConfirmation");
            if(!hasPrivacyConfirmed){
                component.set("v.validationHeader", "Privacy Declaration");
                component.set("v.validationMessage", "You should confirm the Privacy Declaration before you are able to proceed.");
                component.set("v.validationError", true);
            }else{
                if(!component.get("v.originalPartnerPrivacyConfirmation")){
                    helper.updateApplication(component, event, helper);                    
                }else{
                    helper.progressStatus(component, appId, 'Forward');
                }
            }
        } else */
        //if(component.get("v.openedStep") === 1){ //SFTG-2015 Validation in Personal Details page will not block navigation
          //  helper.validatePersonalDetails(component, event, helper)
        //}else{
            helper.progressStatus(component, appId, 'Forward');
        //}
    },
    saveandExit : function(component, event, helper) {
        var appId = component.get("v.recordId");
        helper.savendExit(component, appId, 'Forward');
        
    },
    previousPage : function(component, event, helper) {
        var appId = component.get("v.recordId");
        helper.progressStatus(component, appId, 'Backward');
    },
    onClickCloseAlert: function(component, event, helper) {
        component.set("v.locationError", false);
        component.set("v.validationError", false);
        component.set("v.showSendToStudentConfirmation", false);
    },
    changeSection : function(component, event, helper){
        var params = event.getParam('arguments');
        if (params) {            
            var navigationComponentAura = component.find('navigationComponent');
            var navigationComponentLWC = navigationComponentAura.getElement();
            var section = params.sectionName;
            var stepMap = component.get("v.stepMap");

            switch(section) {             
                case 'Personal Details':
                    component.set("v.openedStep", 1);
                    navigationComponentLWC.checkFurthest(stepMap[2]);
                    break;
                case 'Access and Equity':
                    component.set("v.openedStep", 1);
                    navigationComponentLWC.checkFurthest(stepMap[2]);
                    break;
                case 'Study Preferences':
                    component.set("v.openedStep", 2);
                    navigationComponentLWC.checkFurthest(stepMap[3]);
                    break;
                case 'Qualifications & Work Experience':
                    component.set("v.openedStep", 3);
                    navigationComponentLWC.checkFurthest(stepMap[4]);
                    break;
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
    handleChildEvt:function(component, event, helper){
        helper.handleChildEvt(component,event,helper);
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            // record is loaded (render other component which needs record data value)
            component.set("v.originalPartnerPrivacyConfirmation", component.get("v.applicationRecord").Partner_Privacy_Confirmation__c);
            component.set("v.partnerPrivacyConfirmation", component.get("v.applicationRecord").Partner_Privacy_Confirmation__c);
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
    showSendToStudentConfirmation : function(component, event, helper) {        
        component.set("v.validationHeader", "Send Application to Student");
        component.set("v.validationMessage", "<h4>Are you sure you want to send this application to the Student?</h4><h4>You will lose update permissions on this Application once sent.</h4>");
        component.set("v.validationError", true);
        component.set("v.showSendToStudentConfirmation", true);
    },
    handleSendToStudent : function(component, event, helper) {        
        component.set("v.locationError", false);
        component.set("v.validationError", false);
        component.set("v.showSendToStudentConfirmation", false);
        helper.sendToStudent(component, event, helper);
    }, 
    onPartnerConfirmation : function(component, event, helper) {
        var checkbox = event.getSource();
        var newValue = checkbox.get("v.checked");
        component.set("v.partnerPrivacyConfirmation", newValue);
    },
    handleACPEvent : function(component, event, helper){ //SFTG-2015 Send to Student button enable/disable based on Duration & ACP selection
        var appId = component.get("v.recordId");
        component.set("v.openedStep",2);
        var eventTypeFromChild = event.getParam("eventType");
        // Handle Removing a Course
        if (eventTypeFromChild == 'RemoveACP') {
            component.set("v.sendToStudentDisabled", true);
            component.set("v.courseSelectionError", 'Please select a valid course');
        } 
        // Handle Adding a Course
        if (eventTypeFromChild == 'AddACP') {
            helper.progressStatus(component, appId, 'Stay');        
        }
        // Handle Change of Duration 
        if (eventTypeFromChild == 'Duration') {
            helper.progressStatus(component, appId, 'Stay');        
        }        
    }
})