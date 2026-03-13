/**
 * Created by smen0015 on 20/06/2018.
 */
({
    retrieveCOInfoJS : function(component){

            var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
            var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
            var sParameterName;
            var windowLoc = window.location.pathname;
            var coName = '';
            for (var i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('='); //to split the key from the value.
                for (var j = 0; j < sParameterName.length; j++) {
                    if (sParameterName[j] === 'coName') { //get the course code from the parameter
                        coName = sParameterName[j+1];
                    }
                }
            }
            console.log('coName=='+coName);
            // Retrieve Course Offerings
            var action_courseOffering = component.get("c.getCOByName");
            action_courseOffering.setParams({ "coName"   : coName });
            console.log('setting params ***');
            action_courseOffering.setCallback(this, function(a) {
                console.log('bhoom ***');
                var cos = a.getReturnValue();
                console.log('bhoom ***'+cos);
                component.set("v.courseOffering", cos);
            });
            $A.enqueueAction(action_courseOffering);
    }
})