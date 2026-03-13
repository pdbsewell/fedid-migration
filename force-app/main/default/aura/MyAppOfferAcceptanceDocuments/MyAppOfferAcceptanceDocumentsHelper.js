({
    retrieveContextOfferId : function(component, event, helper) {
        //Parse the URL
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedOfferId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'opportunityId') { //get the app Id from the parameter
                    retrievedOfferId = sParameterName[j+1];
                }
            }
        }

        if (retrievedOfferId != '') {
            component.set("v.opportunityId", retrievedOfferId);
        }
    }
})