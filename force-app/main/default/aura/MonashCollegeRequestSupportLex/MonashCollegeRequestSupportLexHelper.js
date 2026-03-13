({
	validateValues : function(component, event, helper) {
	    //Show loader
	    component.set('v.showSpecialConsiderationSpinner', true);
	    
	    //Retrieve values
	    var studentIdField = component.find('studentIdField');
	    var emailField = component.find('emailField');
	    var classDayField = component.find('classDayField');
	    var descriptionField = component.find('descriptionField');
        
        //Remove non numeric number on student id field
        if(component.get('v.enquiryStudentId')){
            component.set('v.enquiryStudentId', component.find('studentIdField').get('v.value').replace(/[^0-9\.]/g,''));
        }
        
        //Notify the user that the student id field needs 8 characters
        if(component.get('v.enquiryStudentId')){
            if(component.get('v.enquiryStudentId').length != 8) {
                studentIdField.setCustomValidity('Please enter your 8 digit Student Id.');
                studentIdField.reportValidity();
            }else{
                studentIdField.setCustomValidity('');
                studentIdField.reportValidity();
            }
        }
        
	    //Check contact details
	    if((studentIdField.checkValidity() && component.get('v.enquiryStudentId').length == 8) && emailField.checkValidity()){
            //Enable verify contact button
	        component.set('v.hasContactDetails', true);
	    }else{
	        //Disable verify contact button
	        component.set('v.hasContactDetails', false);
	    }
	    
	    var currentSelectedClassDay = component.get('v.selectedClassDay');
	    var classDayOptions = [];
	    //Update class day options
	    if(component.get('v.selectedProgram') == 'Global Professionals Program (GPP)'){
	        classDayOptions = [
	            {'label': 'choose the day of your current class your are enquiring about...', 'value': ''},
                {'label': 'Monday', 'value': 'Monday'},
                {'label': 'Tuesday', 'value': 'Tuesday'},
                {'label': 'Wednesday', 'value': 'Wednesday'},
                {'label': 'Thursday', 'value': 'Thursday'},
                {'label': 'Friday', 'value': 'Friday'} 
	        ];
	        if(currentSelectedClassDay == 'Saturday' || currentSelectedClassDay == 'Sunday'){
	            currentSelectedClassDay = '';
	        }
	    }else{
	        classDayOptions = [];
	        classDayOptions.push({'label': 'choose the day of your current class your are enquiring about...', 'value': ''});
            classDayOptions.push({'label': 'Monday', 'value': 'Monday'});
            classDayOptions.push({'label': 'Tuesday', 'value': 'Tuesday'});
            classDayOptions.push({'label': 'Wednesday', 'value': 'Wednesday'});
            classDayOptions.push({'label': 'Thursday', 'value': 'Thursday'});
            classDayOptions.push({'label': 'Friday', 'value': 'Friday'});
            classDayOptions.push({'label': 'Saturday', 'value': 'Saturday'});
            classDayOptions.push({'label': 'Sunday', 'value': 'Sunday'});
        }
	    component.set('v.selectedClassDay', currentSelectedClassDay);
        component.set('v.classDayOptions', classDayOptions);
	    
	    //Check form values
	    if(component.get('v.doContactExist') && 
	       component.get('v.selectedProgram') && component.get('v.selectedNotificationType') && component.get('v.enquiryDescription')){
            
            //Remove class day value when GPP is selected
            if(component.get('v.selectedProgram') == 'Global Professionals Program (GPP)'){
                component.set('v.selectedClassDay', '');
            }
            
            //Enable submit enquiry button
	        component.set('v.disableSubmit', false);
	    }else{
	        //Disable submit enquiry button
	        component.set('v.disableSubmit', true);
	    }
	    
	    //Hide loader
	    component.set('v.showSpecialConsiderationSpinner', false);
	},
	retrieveContactDetails : function(component, event, helper) {
	    //Show loader
	    component.set('v.showSpecialConsiderationSpinner', true);
	    
	    //Initialize Action
        var action = component.get('c.retrieveContact');
        
        //Set enquiry parameters
        action.setParams({ 
            studentId : component.get('v.enquiryStudentId'),
            monashEmail : component.get('v.enquiryEmail')
        });
        
        // Create a callback that is executed after the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                //Check if there is a result
                if(response.getReturnValue() != 'No Match'){
                    var callResult = response.getReturnValue();                    
                    component.set('v.doContactExist', true);
                    component.set('v.contactSearchResult', 'Success');
                    
                    component.find('programField').set('v.disabled', false);
                    component.find('notificationTypeField').set('v.disabled', false);
                    component.find('descriptionField').set('v.disabled', false);
                }else{                  
                    component.set('v.doContactExist', false);
                    component.set('v.contactSearchResult', 'No Match');
                    component.set('v.enteredStudentId', component.get('v.enquiryStudentId'));
                    component.set('v.enteredEmail', component.get('v.enquiryEmail'));
                    component.set('v.submittedEnquiryCaseNumber', '');
                    
                    component.set('v.enquiryStudentId', '');
                    component.set('v.enquiryEmail', '');
                    component.set('v.hasContactDetails', false);
                }
            }
            else if (state === 'INCOMPLETE') {
                console.log(state);
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + 
                                 errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
            
            //Hide loader
	        component.set('v.showSpecialConsiderationSpinner', false);
        });

        $A.enqueueAction(action);
	},
	saveEnquiry : function(component, helper, event) {
	    //Show loader
	    component.set('v.showSpecialConsiderationSpinner', true);
	    
		//Initialize Action
        var action = component.get('c.submitSpecialConsiderationEnquiry');
        
        //Set enquiry parameters
        action.setParams({ 
            studentId : component.get('v.enquiryStudentId'),
            monashEmail : component.get('v.enquiryEmail'),
            enquiryProgram : component.get('v.selectedProgram'),
            selectedClassDay : component.get('v.selectedClassDay'),
            selectedNotificationType : component.get('v.selectedNotificationType'), 
            otherNotificationType : component.get('v.otherNotificationType'), 
            enteredAdditionalDescription : component.get('v.enquiryDescription')
        });
        
        // Create a callback that is executed after the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                //Set enquiry case number response
                var enquiryResult = JSON.parse(response.getReturnValue());
                component.set('v.enquiryId', enquiryResult.Id);
                component.set('v.submittedEnquiryCaseNumber', enquiryResult.CaseNumber);
                
                //Disable file uploader
                component.set('v.isDisabled', true);
                
                var submitBtn = component.find('sendEnquiryBtn');
                submitBtn.set('v.disabled', true);
                $A.util.removeClass(submitBtn, 'submitBtn'); 
                
                //Upload file if there is a selected file
                if(component.get('v.fileName') != ''){
                    //Submit file to server and attach to the submitted enquiry
                    var fileUploader = component.find('fileUploader');
                    fileUploader.submitFile();
                }
                
                component.set('v.doContactExist',false);
            }
            else if (state === 'INCOMPLETE') {
                console.log(state);
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + 
                                 errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
            
            //Hide loader
	        component.set('v.showSpecialConsiderationSpinner', false);
        });

        $A.enqueueAction(action);
	}
})