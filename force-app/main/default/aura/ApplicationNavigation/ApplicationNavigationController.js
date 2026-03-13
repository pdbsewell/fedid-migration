/**
 * Created by trentdelaney on 22/8/18.
 */
({
    doInit : function(component, event, helper)
    {
        //Check what nav type.
        var type = component.get("v.progressApplication");

        if(type === false){
            //Parse the URL
            var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
            var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
            var sParameterName;
            var i, j;

            console.log(sURLVariables);
            var retrievedAppId = '';
            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('='); //to split the key from the value.
                for (j = 0; j < sParameterName.length; j++) {
                    if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                        retrievedAppId = sParameterName[j+1];
                        console.log("This is the appId" + retrievedAppId);
                    }
                }
            }

            if (retrievedAppId != '') {
                component.set("v.appId", retrievedAppId);
                //redirect to the new app form url
                window.location.href = '/admissions/s/application/' + retrievedAppId;
            }
        }
    },

    nextPage : function(component, event, helper)
    {
        var page = component.get("v.nextPage");
        var appId = component.get("v.appId");
        var type = component.get("v.progressApplication");

        if(type === false){
            //Fire progression of status
            helper.progressStatus(component, page, appId, 'Forward');
        }
        else{
            helper.createApplication(component, page);
        }
    },

    previousPage : function(component, event, helper)
    {
        var page = component.get("v.previousPage");
        var appId = component.get("v.appId");

        if(page === '/'){
            helper.navigateToUrl(page)
        }
        else{
            helper.progressStatus(component, page, appId, 'Backward');
        }
    },
    
    onClickCloseAlert: function(component, event, helper) {
        component.set("v.locationError", false);
        component.set("v.validationError", false);
    }
})