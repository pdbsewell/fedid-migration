({
	/*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         28.May.2018         
    * @description  Inititialization
    * @revision     
    *******************************************************************************/
    doInit : function(component) {
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
        if(!sParamId){
            sParamId = component.get("v.applicationId");
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + sParamId;
        }

        component.set("v.appId", sParamId);
        
        if (sParamId !== '') {
            var action = component.get("c.retrieveApplication");
            action.setParams({'appId'   : sParamId});
	        action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var data = response.getReturnValue();

                    // Set the appRecord with the server response
                    component.set("v.application", data["application"]);
                    component.set("v.sponsorshipOptions", data['sponsor_pick']);
                }
	        });
            $A.enqueueAction(action);
        }
    },

    updateSelection :function(component, event, helper)
    {
        //Wipe the other options
        var app = component.get("v.application");
        app.Sponsor_Scholarship_organisation__c = '';
        app.Sponsor_Name__c = '';
        app.Proxy_Email_Address__c = '';
        app.Sponsor_Email_Address__c = '';
        component.set("v.application", app);

        helper.handleSponsorChange(component);
    },

    updateApplication: function(component, event, helper)
    {

        helper.handleSponsorChange(component, event, helper);
    }

    /**
     * Close the error popup
     * @param component
     * @param event
     * @param helper
     */
    , onClickCloseErrors: function(component, event, helper)
    {
        component.set("v.showErrors", false);
    }

});