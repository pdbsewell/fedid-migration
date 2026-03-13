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
    validateFields : function(component, event, helper) {
        //Validate form values
        helper.validateValues(component, event, helper);
    },
	submitEnquiry : function(component, event, helper) {
	    //Submit enquiry to backend
	    helper.saveEnquiry(component, event, helper);
	}
})