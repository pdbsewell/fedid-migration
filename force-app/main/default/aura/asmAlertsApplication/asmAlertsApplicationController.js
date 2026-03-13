({
	doInit : function(component, event, helper) {
		var applicationId = component.get('v.recordId');
		component.set('v.applicationId', applicationId);
        console.log('asmAlertsApplicationController: application Id = ' + applicationId);
                
        var action = component.get("c.GetApplicationAlerts");
        action.setParams({"applicationId": applicationId});
        action.setCallback(this, function(response) {
            console.log('GetApplicationAlerts::' + response.getState());
            var objResults = response.getReturnValue();

            if(objResults != null)
            {
                /*
                console.log('GetApplicationAlerts:{');
                for(var key in objResults)
                {
                    console.log(key + ':' + objResults[key]);
                }
                console.log("}");
                */

                // set attributes

                // toggle alert message if any are found
                var anyAlerts = false;

               /* if(objResults.isUnder18AtApplication== true)
                {
                    component.set("v.isUnder18AtApplication", true);
                    anyAlerts = true;
                }*/
                
                if(objResults.hasEncumbrances == true)
                {
                    component.set("v.hasEncumbrances", true);
                    anyAlerts = true;
                }
                
                if(!objResults.applicationFeePaid && objResults.applicationFeeAmt>0)
                {
                    component.set("v.applicationFeePaid", false);
                    anyAlerts = true;
                }

               /* if(objResults.hasAccessEquity == true)
                {
                    component.set("v.hasAccessEquity", true);
                    anyAlerts = true;
                }*/
                if(objResults.gteAlertSubmissionLocation == true)
                {
                    component.set("v.gteAlertSubmissionLocation", true);
                    anyAlerts = true;
                }
                if(objResults.gteAlertQualification == true)
                {
                    component.set("v.gteAlertQualification", true);
                    anyAlerts = true;
                }
                if(objResults.creditIntention == true)
                {
                    component.set("v.creditIntention", true)
                    anyAlerts = true;
                }
                if(objResults.admkey == true){
                    component.set("v.admkey", true);
                    anyAlerts = true;
                }
                
                /*if(objResults.taskQualification == true)
                {
                    component.set("v.taskQualification", true)
                    anyAlerts = true;
                }
                
                if(objResults.taskVisa == true)
                {
                    component.set("v.taskVisa", true)
                    anyAlerts = true;
                }*/
                
              /*  var hasCitizenshipAlert = objResults.hasCitizenshipAlert;
                if(hasCitizenshipAlert == true)
                {
                    component.set("v.hasCitizenshipAlert", true);
                    anyAlerts = true;
                }*/

                component.set("v.anyAlerts", anyAlerts);
            }
            
            //Hide component spinner
            component.set('v.showComponentLoader', false);
        });

        $A.enqueueAction(action);
    },
    myAction : function(component, event, helper) {

    }
})