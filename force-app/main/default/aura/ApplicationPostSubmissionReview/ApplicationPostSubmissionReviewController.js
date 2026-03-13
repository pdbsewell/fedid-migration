({
    doInit : function(component, event, helper) {
        //Parse the URL
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;
        
        var showTab = '';
        var appId;
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'show') { //get the app Id from the parameter
                    showTab = sParameterName[j+1];
                } else if(sParameterName[j] === 'appId') {
                    appId = sParameterName[j+1];
                    component.set("v.appId", appId);    
                }
            }
        }

        if (showTab == 'details') {
            component.set("v.openedTab", 'Details');
        }else if (showTab == 'documents') {
            component.set("v.openedTab", 'Documents');            
        }else{
            component.set("v.openedTab", 'Details');
        }

        component.set('v.instructions', 'To speed up processing of your application, the checklist items below are a guide as to which documents you need to provide.\<br\>Monash University will contact you when specific evidence or clarifications are required. Upload your documents next to the relevant item.');
        
        if(appId != null && appId != undefined) {
            var getApplication = component.get("c.retrieveApplication");
            getApplication.setParams({"applicationId" : appId});
            getApplication.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var appRecord = response.getReturnValue();
                    component.set("v.typeOfStudy", appRecord.Type_of_Study__c);         
                    $A.enqueueAction(component.get('c.getFeatureToggle')); //calling the myapp feature toggle method to show/hide lwc component        
                }
            });

            $A.enqueueAction(getApplication);  
        }
    },
    /**
    * @description get the feature toggle custom setting value
    * @return n/a
    **/
    getFeatureToggle : function(component) {
        var action = component.get("c.fetchMyAppFeatureToggle");

        action.setCallback(this, function(response){
            if(component.isValid() && response !== null && response.getState() == 'SUCCESS'){
                component.set("v.myAppFeatures", response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    }
})