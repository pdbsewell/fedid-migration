({
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  validates the form
    * @revision     
    *******************************************************************************/
    validateForm : function(component, recordToValidate) {
        var isValid = true;

        var position = component.find("position");
        if (!this.isFieldPopulated(recordToValidate.Position__c)) {
            position.set("v.errors", [{message:"Position is required"}]);
            isValid = false;
        } else {
            position.set("v.errors", null);
        }

        var employer = component.find("employer");
        if (!this.isFieldPopulated(recordToValidate.Employer_Name__c)) {
            employer.set("v.errors", [{message:"Employer is required"}]);
            isValid = false;
        } else {
            employer.set("v.errors", null);
        }

        //only validate if it has value
        if (recordToValidate.Contact_Person_Email__c != '' && recordToValidate.Contact_Person_Email__c != null) {
        	var contactPersonEmail = component.find("contactPersonEmail");
	        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
            
            if (!recordToValidate.Contact_Person_Email__c.match(regExpEmailformat)) {
	            contactPersonEmail.set("v.errors", [{message: "Please enter a valid email address"}]);
	            isValid = false;
	        } else {
	            contactPersonEmail.set("v.errors", null);
	        }
        }

        //var startDateIdError = component.find("startDateIdError");
        if (component.get("v.invalidStartDate")) {
            $A.util.addClass(component.find("startDateId"), 'dateError');
            isValid = false;
        } else if (!this.isFieldPopulated(recordToValidate.Start_Date__c)) {
            component.set("v.startdateErrorMessage", "Start Date is required");
            $A.util.addClass(component.find("startDateId"), 'dateError');
            isValid = false;
        } else {
            $A.util.removeClass(component.find("startDateId"), 'dateError');
            component.set("v.startdateErrorMessage", "");
        }

        //var endDateIdError = component.find("endDateIdError");
        if (component.get("v.invalidEndDate")) {
            $A.util.addClass(component.find("endDateId"), 'dateError');
            isValid = false;
        } else if ( recordToValidate.End_Date__c != '' && recordToValidate.End_Date__c != null && 
                    recordToValidate.Start_Date__c > recordToValidate.End_Date__c ) {
            component.set("v.enddateErrorMessage", "End Date should be greater than Start Date");
            $A.util.addClass(component.find("endDateId"), 'dateError');
            isValid = false;
        } else {
            $A.util.removeClass(component.find("endDateId"), 'dateError');
            component.set("v.enddateErrorMessage", "");
        }

        if (isValid) {
            component.set("v.hasErrors", false);
        } else {
            component.set("v.hasErrors", true);
        }
    }, 

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  creates a new record
    * @revision     
    *******************************************************************************/
    createNewRecord : function(component, recordToValidate) {
        var action_createNewRecord = component.get("c.createNewWorkExpRecord");
        action_createNewRecord.setCallback(this, function(a) {
            component.set("v.contWorkExp", a.getReturnValue());
			component.set("v.showForm", true);
        });
        //action 2, retrieve qualification list
        $A.enqueueAction(action_createNewRecord);
    },

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         10.Jul.2017         
    * @description  edit an existing work experience
    * @revision     
    *******************************************************************************/
    retrieveWorkExpToEdit : function(component) {
        var action_retrieveWorkExp = component.get("c.editWorkExpRecord");
        action_retrieveWorkExp.setParams({ "workExperienceId" : component.get("v.selRecToEditId") });
        action_retrieveWorkExp.setCallback(this, function(a) {
            var workEx = a.getReturnValue();
            component.set("v.contWorkExp", workEx);
            component.set("v.newWorkExpRecId", component.get("v.selRecToEditId"));
            component.set("v.showForm", true);
        });
        $A.enqueueAction(action_retrieveWorkExp);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         12.Apr.2017         
    * @description  retrieve the contact details
    * @revision     
    *******************************************************************************/
    retrieveWorkExpList : function (component){
        var action_retrieveWorkExpList = component.get("c.retrieveWorkExpList");
        //checks which table to display/return
        if (component.get("v.isAppComponent") == true) {
            action_retrieveWorkExpList = component.get("c.retrieveAppWorkExpProvidedList");
            action_retrieveWorkExpList.setParams({ "applicationId"   : component.get("v.appId") });
        }
        action_retrieveWorkExpList.setCallback(this, function(a) {
            component.set("v.workExpList", a.getReturnValue());
        });
        
        //Action 2, retrieve qualification list
        $A.enqueueAction(action_retrieveWorkExpList);
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
    * @author       Ant Custodio
    * @date         2.Jun.2017         
    * @description  clears all errors
    * @revision     
    *******************************************************************************/
    clearAllErrors : function (component) {
        this.clearErrors(component, "position");
        this.clearErrors(component, "employer");
        this.clearErrors(component, "contactPersonEmail");
        component.set("v.errorMessage", "");
        component.set("v.startdateErrorMessage", "");
        component.set("v.invalidStartDate", false);
        component.set("v.enddateErrorMessage", "");
        component.set("v.invalidEndDate", false);
        component.set("v.initializeStartDatePicker", true);
        component.set("v.initializeEndDatePicker", true);
        component.set("v.selectedStartDate", "");
        component.set("v.selectedEndDate", "");
        component.set("v.selRecToEditId", "");
        component.set("v.isEditWorkExperience", false);
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
    * @date         11.May.2017         
    * @description  retrieve the selected qualification
    * @revision     
    *******************************************************************************/
    retrieveSelectedQualification : function (component, workExpId){
        var action = component.get("c.editWorkExpRecord");
        action.setParams({ "workExperienceId"   : workExpId });
        action.setCallback(this, function(a) {
            component.set("v.selWorkExpToView", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi 
    * @date         17.Aug.2018
    * @description  retrieve the selected application contact id
    * @revision     
    *******************************************************************************/
   retrieveContactId : function (component){
        var action = component.get("c.retrieveContactId");
        action.setCallback(this, function(a) {
            component.set("v.contactId", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    
    createWorkExpAndRetrieveID : function (component){
        var action = component.get("c.createWorkExpAndRetrieveID");
        action.setParams({ "applicationId"   : component.get("v.appId") });
        action.setCallback(this, function(response) {
            let workExpRecordId = response.getReturnValue().split(',')[0];
            let appWorkExperienceProvidedId = response.getReturnValue().split(',')[1];
            component.set("v.newWorkExpRecId", workExpRecordId);
            component.set("v.appWorkExperienceProvidedId", appWorkExperienceProvidedId);
        });
        $A.enqueueAction(action);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  deletes the work experience record
    * @revision     
    *******************************************************************************/
    deleteWorkExperience : function (component, event, helper){             
        var selRecToDelId = component.get("v.selRecToDelId");

        /*******************************************************************************
        * @author       Ant Custodio
        * @date         12.Apr.2017         
        * @description  retrieve the contact details
        * @revision     
        *******************************************************************************/
        var action_deleteWorkExpRecord = component.get("c.deleteSelectedWorkExperience");
        
        //checks which table to display/return
        if (component.get("v.isAppComponent") == true) {
            action_deleteWorkExpRecord = component.get("c.deleteSelectedAppWorkExpProvided");
            action_deleteWorkExpRecord.setParams({ "appWorkExpProvidedId"   : selRecToDelId });
        } else {
            action_deleteWorkExpRecord.setParams({ "workExperienceId"   : selRecToDelId });
        }

        action_deleteWorkExpRecord.setCallback(this, function(a) {
            var state = a.getState();
            if (state == "ERROR") {
                var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                    
                        console.log("Error message: " + 
                                errors[0].message);
                        var splitString = errors[0].message.split(":");
                        component.set("v.errorMessage", splitString[3] + ': ' + splitString[4]);
                        window.location.hash = '#appWE_errorDiv';
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                //retrieve the work experience list
                helper.retrieveWorkExpList(component);

                //close the confirmation popup
                component.set("v.showConfirmPopup", false);
            }
        });

        //Action 1, delete the record
        $A.enqueueAction(action_deleteWorkExpRecord);
    },
})