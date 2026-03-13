({
    doInit : function(component, event, helper) {
        var acpId = component.get('v.recordId');
        component.set('v.acpId', acpId);
        var action = component.get("c.GetACPAlerts");
        action.setParams({"acpId": acpId});
        action.setCallback(this, function(response) {
            var objResults = response.getReturnValue()

            if(objResults != null)
            {
                for(var key in objResults)
                {
                    console.log(key + ':' + objResults[key]);
                }

                // set attributes

                // toggle alert message if any are found
                var anyAlerts = false;

                
                if(objResults.hasEncumbrances == true)
                {
                    component.set("v.hasEncumbrances", true);
                    anyAlerts = true;
                }

                if(!objResults.applicationFeePaid && objResults.applicationFeeAmt>0 )
                {
                    component.set("v.applicationFeePaid", false);
                    anyAlerts = true;
                }
                if(objResults.ageAtCourseStart < 18 && objResults.ageAtCourseStart >= 0)
                {                    
                    component.set("v.ageAtCourseStart", objResults.ageAtCourseStart);
                    component.set("v.under18AtCourseStart", true);
                    anyAlerts = true;

                }
               /* if(objResults.isUnder18AtApplication == true)
                {
                    component.set("v.isUnder18AtApplication", true);
                    anyAlerts = true;
                }
                if(objResults.hasAccessEquity == true)
                {
                    component.set("v.hasAccessEquity", true);
                    anyAlerts = true;
                }*/
               if(objResults.gteAlertSubmissionLocation == true)
                {
                    component.set("v.hasGTEAlertSubmissionLocation", true);
                    anyAlerts = true;
                }
                if(objResults.gteAlertQualification == true)
                {
                    component.set("v.hasGTEAlertQualification", true);
                    anyAlerts = true;
                }

                if(objResults.creditIntention == true)
                {
                    component.set("v.creditIntention", true)
                    anyAlerts = true;
                }

                if(objResults.admkey === true)
                {
                    component.set("v.admkey", true)
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

                if (objResults.manualAssessmentOverride == true)
                {
                    component.set("v.manualAssessmentOverride", true)
                    anyAlerts = true;
                }

                if(objResults.readmit == true){
                    component.set("v.readmit", true);
                    anyAlerts = true;
                }
                
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