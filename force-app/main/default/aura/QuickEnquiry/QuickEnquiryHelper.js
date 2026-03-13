({
	prepopulateContact : function(component, event, helper) {
		if(component.get('v.recordId').substring(0, 3) == '003'){
    	    //Set default contact
    	    component.find('formContactId').set('v.value', component.get('v.recordId'));
    	}
	},
	defaultEnquiryMyInformation : function(component, event) {
	    var eventParams = event.getParams();
	    
	    var userEnquiryType = component.get('v.currentUser').Queue__c;
        var userDefaultEnquiryType = component.get('v.currentUser').Default_Enquiry_Record_Type__c;
        var userOrigin = component.get('v.currentUser').Enquiry_Role__c;
        var userLocation = component.get('v.currentUser').Location__c;
        var userMyInformationLastModified = component.get('v.currentUser').My_Information_LastUpdate__c;
        
        if(userDefaultEnquiryType == 'MonCon Support') {
            enquiryOrigin = 'Phone - MonCon Support';
        }
        
        if(eventParams.changedFields != null){
            if("undefined" != typeof(eventParams.changedFields['Queue__c'])){
                userEnquiryType = eventParams.changedFields.Queue__c.value;
            }
            if("undefined" != typeof(eventParams.changedFields['Enquiry_Role__c'])){
                userOrigin = eventParams.changedFields.Enquiry_Role__c.value;
            }
            if("undefined" != typeof(eventParams.changedFields['Location__c'])){
                userLocation = eventParams.changedFields.Location__c.value;
            }
            if("undefined" != typeof(eventParams.changedFields['My_Information_LastUpdate__c'])){
                userMyInformationLastModified = eventParams.changedFields.My_Information_LastUpdate__c.value;
            }
        }
        
        //Default My Information details to the enquiry form
        var today = new Date();
        var monthDigit = today.getMonth() + 1;
        if (monthDigit <= 9) {
            monthDigit = '0' + monthDigit;
        }
        
		//Default enquiry values if the my information details are populated
	    if(userLocation && userEnquiryType && userOrigin){
            //If the my information details are populated today
            if(userMyInformationLastModified == (today.getFullYear() + '-' + monthDigit + '-' + (('0' + today.getDate()).slice(-2)))){
                var enquiryEnquiryType;
                var enquiryOrigin;
                
                //Map correct values for Enquiry Type
                if(userEnquiryType == $A.get('$Label.c.UserQueue_CurrentStudent')){
                    enquiryEnquiryType = $A.get('$Label.c.Current_Course');
                }else if(userEnquiryType == $A.get('$Label.c.UserQueue_FutureStudent')){
                    enquiryEnquiryType = $A.get('$Label.c.Future_Course');
                }
                
                //Map correct values for Enquiry Origin
                if(userOrigin == $A.get('$Label.c.UserEnquiryRole_BackOffice')){
                    enquiryOrigin = $A.get('$Label.c.EnquiryOrigin_BackOfficeGeneral');
                }else if(userOrigin == $A.get('$Label.c.UserEnquiryRole_FaceToFaceOnline')){
                    enquiryOrigin = $A.get('$Label.c.EnquiryOrigin_FaceToFace');
                }else if(userOrigin == $A.get('$Label.c.UserEnquiryRole_PhoneOnline')){
                    enquiryOrigin = $A.get('$Label.c.EnquiryOrigin_Phone');
                }
            }
	    }
        
        //Default form fields
        if(enquiryOrigin){
            component.find('formOrigin').set('v.value', enquiryOrigin);
        }else{
            component.find('formOrigin').set('v.value', component.get('v.userEnquiryOrigin'));
        }
        if(enquiryEnquiryType){
            component.find('formEnquiryType').set('v.value', enquiryEnquiryType);
        }else{
            component.find('formEnquiryType').set('v.value', component.get('v.userEnquiryType'));
        }
        if(userLocation){
            component.find('formLocationCode').set('v.value', userLocation);
        }else{
            component.find('formLocationCode').set('v.value', component.get('v.userEnquiryLocation'));
        }
	}
})