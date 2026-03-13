/**
 * Created by trentdelaney on 17/9/18.
 */
({
    doInit : function (component, event, helper) {
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
        }
        component.set("v.appId", sParamId);
        helper.getFullApplication(component, event, helper, sParamId);
    }

})