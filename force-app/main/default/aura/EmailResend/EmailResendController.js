({
	/*******************************************************************************
	* @author		Ant Custodio
	* @date         4.Apr.2018
	* @description  method called on initialise of the component
	* @revision     
	*******************************************************************************/
	doInit : function(component, event, helper) {
		//retrieves the email message record and sets it to {!v.emlMsgRec}
		helper.retrieveEmailMessageRecord(component);
   	},
   	
   	/*******************************************************************************
	* @author		Ant Custodio
	* @date         4.Apr.2018
	* @description  resends the email
	* @revision     
	*******************************************************************************/
	resendEmail : function(component, event, helper) {
		helper.wait(component);
		//validate all emails first before continuing
		if (helper.validateAllEmails(component)) {
			var emlMsgRec = component.get("v.emlMsgRec");
			var toAddresss = component.get("v.toAddressStr");
			var ccAddress = component.get("v.ccAddressStr");
			var bccAddress = component.get("v.bccAddressStr");
			var notifyAgentCheck = component.get("v.notifyAgent");
			
	        var a_resend = component.get("c.sendToProvidedEmailAddresses");
	        a_resend.setParams({"emlMsgId": emlMsgRec.Id,
	    	          			"toAddresses" : toAddresss,
	    	          			"ccAddresses" : ccAddress,
	    	          			"bccAddresses" : bccAddress,
	    	          			"notifyAgent" : notifyAgentCheck,
	    	          			"overrideRecipients" : true });
	    	          			
	        a_resend.setCallback(this, function(response){
	            var returnVal = response.getReturnValue();
	            if(returnVal){
	                alert('The Email has been sent successfully.');
	                window.close();
	            } else {
	            	alert('Email sending failed. Please contact the administrator.');
	            	window.close();
	            }
	            helper.waitDone(component);
	        });
	
	        $A.enqueueAction(a_resend);
		} else {
			//TODO
			console.log('validate failed');
			helper.waitDone(component);
		}
		
   	},
   	
   	/*******************************************************************************
	* @author		Ant Custodio
	* @date         4.Apr.2018
	* @description  closes the window
	* @revision     
	*******************************************************************************/
	cancel : function(component, event, helper) {
		window.close();
   	},
   	
   	/*******************************************************************************
	* @author		Ant Custodio
	* @date         12.Apr.2018
	* @description  copies the checkbox value to notifyAgent variable
	* @revision     
	*******************************************************************************/
	change_notifyAgent : function(component, event, helper) {
		var source = event.getSource();
        var notifyAgentVal = source.get("v.value");
		component.set("v.notifyAgent", notifyAgentVal);
   	},
})