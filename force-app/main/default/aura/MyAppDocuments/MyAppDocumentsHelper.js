({
    retrieveContextApplicationId : function(component, event, helper) {
        //Parse the URL
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedAppId = '';
        var isReviewPage = false;
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                }
                if (sParameterName[j] === 'show') { //determine if the page is in review page
                    isReviewPage = true;
                }
            }
        }

        if (retrievedAppId != '') {
            component.set("v.applicationId", retrievedAppId);
            //redirect to the new app form url if not in review page
            if(!isReviewPage){
                window.location.href = '/admissions/s/application/' + component.get("v.applicationId");
            }
        }
    }
})