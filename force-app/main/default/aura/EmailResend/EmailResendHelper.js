({
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         4.Apr.2018         
    * @description  retrieve the Email Message Record
    * @revision     
    *******************************************************************************/
	retrieveEmailMessageRecord : function(component) {
        var a_retrieveEmailMessageById = component.get("c.retrieveEmailMessageById");
        a_retrieveEmailMessageById.setParams({ "emlMsgId"   : component.get("v.emlMsgId") });
        a_retrieveEmailMessageById.setCallback(this, function(a) {
        	var state = a.getState();
            if (state === "ERROR") {
            	console.log('errors');
            	//TODO
            } else {
            	var emRec = a.getReturnValue();
            	//populate page variables
            	component.set("v.emlMsgRec", emRec[0]);
            	component.set("v.toAddressStr", emRec[0].ToAddress);
            	component.set("v.ccAddressStr", emRec[0].CcAddress);
            	component.set("v.bccAddressStr", emRec[0].BccAddress);
            	component.set("v.notifyAgent", emRec[0].Parent.Notify_Agent__c);
            }
        });
        $A.enqueueAction(a_retrieveEmailMessageById);
	},
	
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         12.Apr.2018         
    * @description  validates all the email addresses provided
    * @revision     
    *******************************************************************************/
    validateAllEmails: function (component) {
    	var isToValid = this.loopAndCheckEmails(component, 'txt-to');
    	var isCcValid = this.loopAndCheckEmails(component, 'txt-cc');
    	var isBccValid = this.loopAndCheckEmails(component, 'txt-bcc');
    	
    	return (isToValid && isCcValid && isBccValid);
    },
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         12.Apr.2018         
    * @description  loops into the list of email address and return errors if there's
	*					any
    * @revision     by Majid Reisi Dehkrodi 19/04/2018
	* 				check for empty string
	*				Ant Custodio, 7.May.2018 - added trim on the loop to properly
	*					validate the email address
    *******************************************************************************/
    loopAndCheckEmails : function(component, auraId) {
    	var isValid = true;
    	//check if the value is valid first before splitting
    	if (auraId) {
    		var errors = '';
    		var emailCmp = component.find(auraId);
    		var emailStr = emailCmp.get("v.value");
    		
    		//clear errors first
			emailCmp.set("v.errors", [{message: ""}]);
			
			// Added by Majid 19-07-2018
			// Check if the text box is empty
			if (auraId == "txt-to" && !emailStr) {
				errors = 'Please fill in the To field';
				isValid = false;
			}

			if (emailStr && errors == "") {
				var emlList = emailStr.split(';');
				//get the values
				for (var i=0; i < emlList.length; i++ ) {
					var emailVal = emlList[i].trim();
					if (!this.validateEmail(emailVal)) {
						isValid = false;
						if (!$A.util.isEmpty(errors)) {
							errors += ', "'+emailVal+'"';
						} else {
							errors = 'Invalid Email Address: "' + emailVal + '"';
						}
					}
				}
			}
			
			//show error on the text box if it has an error
			if (!isValid) {
				emailCmp.set("v.errors", [{message: errors}]);
			}
		}
    	return isValid;
	},
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         12.Apr.2018         
    * @description  validates the provided email address
    * @revision     
    *******************************************************************************/
    validateEmail : function(emailStr) {
    	var isValidEmail = true;
    	
    	var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;  
        
    	if(!$A.util.isEmpty(emailStr)) {   
    		if(!regExpEmailformat.test(String(emailStr).toLowerCase())){
				isValidEmail = false;
    		}
    	}
    	console.log('email to validate: ' + emailStr + '. Result: ' + isValidEmail);
    	return isValidEmail;
	},
    
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         12.Apr.2018         
    * @description  retrieve the contact qualification list
    * @revision     
    *******************************************************************************/
    wait: function (component) {
    	if (component.find("spinner")) {
    		var spinnerVar = component.find("spinner");
    		$A.util.removeClass(spinnerVar, 'hidden');
    	}
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  hide the spinner when finished loading
    * @revision     Ant Custodio - 13/02/2018 - added checking on the component
						before using it (SF-709)
    *******************************************************************************/
    waitDone: function(component) {
    	if (component.find("spinner")) {
    		var spinnerVar = component.find("spinner");
	        $A.util.addClass(spinnerVar, 'hidden');
    	}
    },
})