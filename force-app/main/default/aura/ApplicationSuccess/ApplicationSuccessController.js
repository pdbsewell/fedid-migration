({
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  initial actions on page load - get the application Id
    * @revision     
    *******************************************************************************/
    doInit : function(component, event) {
		var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var sParamId = '';
        var i;

        for (i = 0; i < sURLVariables.length; i++) {
	        sParameterName = sURLVariables[i].split('='); //to split the key from the value.
	        for(var x = 0; x < sParameterName.length; x++){
	            if(sParameterName[x] === 'appId'){
	               sParamId = sParameterName[x+1] === undefined ? 'Not found' : sParameterName[x+1];
	            }
	        }
	    }
        
        component.set("v.appId", sParamId);

        if (sParamId != '') {
	        /*******************************************************************************
	        * @author       Ant Custodio
	        * @date         3.Apr.2017         
	        * @description  retrieve the application details
	        * @revision     
	        *******************************************************************************/
	        var action_retrieveAppRecord = component.get("c.retrieveApplication");
	        action_retrieveAppRecord.setParams({ "applicationId"   : sParamId });
	        action_retrieveAppRecord.setCallback(this, function(a) {
	            var appRecord = a.getReturnValue();
	            if (appRecord.Status__c != 'Submitted' && appRecord.Status__c != 'Review' && appRecord.Status__c != 'Sent for Submission') {
	            	var address = '/applicationdetail?appId=' + a.getReturnValue();

			        var urlEvent = $A.get("e.force:navigateToURL");
			        urlEvent.setParams({
			          "url": address,
			          "isredirect" :false
			        });
			        urlEvent.fire();
	            } else {
	            	component.set("v.appRecord", a.getReturnValue());
	            }

	            component.set("v.appRecord", a.getReturnValue());
	        });
	        $A.enqueueAction(action_retrieveAppRecord);
        } else {
        	//redirect to home
        	var address = '/';
	        var urlEvent = $A.get("e.force:navigateToURL");
	        urlEvent.setParams({
	          "url": address,
	          "isredirect" :false
	        });
	        urlEvent.fire();
        }
	}
})