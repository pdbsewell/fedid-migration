({
	prepopulateContact : function(component, event, helper) {
		if(component.get('v.recordId').substring(0, 3) == '003'){
    	    //Set default contact
    	    component.find('formContactId').set('v.value', component.get('v.recordId'));
    	}
	},
	
})