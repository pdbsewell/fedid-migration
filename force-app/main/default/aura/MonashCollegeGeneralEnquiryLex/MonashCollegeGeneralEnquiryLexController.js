({
    doInit : function(component, event, helper) {
        //Default selected program field
        component.set('v.selectedProgram','Professional Year Program (PY)');
    },
    searchHandleKeyUp : function (component, event, helper) {
        var isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            var queryTerm = component.find('enter-search').get('v.value');
            var askMonashUrl = 'https://connect.monash.edu/s/search/All/Home/';
    
            window.open(askMonashUrl + queryTerm, '_blank');
        }
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
        component.set('v.selectedTopic', null);
        component.set('v.enquiryDescription', null);
    },
	submitEnquiry : function(component, event, helper) {
	    //Submit enquiry to backend
	    helper.saveEnquiry(component, event, helper);
	}
})