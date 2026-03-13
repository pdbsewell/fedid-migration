({
    doInit : function(component, event, helper) {
        //Default selected program field
        component.set('v.selectedProgram','Professional Year Program (PY)');
        //Add personal leave note
        component.set('v.personalLeaveNote', 'Please provide doctor\'s certificate for leave regarding medical or heath issues');
    },
    verifyHandleKeyUp : function (component, event, helper) {
        var isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            if(component.get('v.hasContactDetails')){
                //Validate contact details
                helper.retrieveContactDetails(component, event, helper);
            }
        }
    },
    validateFields : function(component, event, helper) {
        //Validate form values
        helper.validateValues(component, event, helper);
    },
    validateContactDetails : function(component, event, helper) {
        //Validate contact details
        helper.retrieveContactDetails(component, event, helper);
    },
    resetContactDetails : function(component, event, helper) {
        //Remove contact record
        component.set('v.doContactExist', false);
        component.set('v.contactId', null);
        component.set('v.enquiryStudentId', null);
        component.set('v.enquiryEmail', null);
        component.set('v.hasContactDetails', false);
        component.set('v.selectedProgram', null);
        component.set('v.selectedClassDay', null);
        component.set('v.enquiryDescription', null);
        component.set('v.selectedNotificationType', null);
        component.set('v.selectedReasonChange', null);
        component.set('v.otherReasonChange', null);
        
        var departureDateField = component.find('departureDateField');
        var returnDateField = component.find('returnDateField');
        
        departureDateField.set('v.value','');
        returnDateField.set('v.value','');
        
        departureDateField.setCustomValidity('');
        departureDateField.reportValidity();
        returnDateField.setCustomValidity('');
        returnDateField.reportValidity();
        
        component.set('v.hasPageError', false);
    },
	submitEnquiry : function(component, event, helper) {
	    //Submit enquiry to backend
	    helper.saveEnquiry(component, event, helper);
	}
})