/**
 * Created by trentdelaney on 23/8/18.
 */
({  
    parseApplicationId: function(component)
    {
        console.log('ApplicationPathHelper:: parseApplicationId');
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedAppId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                    component.set("v.appId", retrievedAppId);
                    return retrievedAppId;
                }
            }
        }
        return null;
    }


    
    ,  initLoad:function(component)
    {   
        var subProgress = component.get('v.submissionProgress');
        console.log('ApplicationPathHelper:: subProgress:' + subProgress);
        if(!subProgress)
        {
            console.error('ApplicationPathHelper:: Check Community Page Builder settings');
            return;
        }
        
        var appId = component.get("v.appId");        
        var action = component.get("c.GetInitLoad");
        var objParams = {
            "applicationId":appId,
            "newState":subProgress
        };
        action.setParams(objParams);
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('SynchApplicationToPage state = ' + state);
            if(state === "SUCCESS")
            {
                var objResponse = response.getReturnValue();

                // list of states
                var listStates = objResponse.states;
                component.set('v.listStates', listStates);

                // furthest progress
                var furthest = objResponse.furthest;
                component.set("v.furthestStepNumber", furthest);

                this.getCurrentStepNumber(component, subProgress, listStates);
                this.getFurthestStepNumber(component, furthest, listStates);

                // application
                var application = objResponse.application;
                component.set('v.application', application);

                console.debug('ApplicationPathHelper finished initLoad');

            }
            else if (state == 'ERROR')
            {
                var errors = action.getError();
                if (errors) 
                {
                    for(var i = 0; i < errors.length; ++i)
                        console.error(errors[i]);
                }
            }
        });
        $A.enqueueAction(action);
    }

    , getCurrentStepNumber:function(component, submissionProgress, listStates)
    {
        for(var i = 0; i < listStates.length; ++i)
        {
            var state = listStates[i];
            if(state == submissionProgress)
            {
                component.set("v.currentStepNumber", i);
                return;
            }
        }
    }

    , getFurthestStepNumber:function (component, furthest, listStates)
    {
        for(var i = 0; i < listStates.length; ++i)
        {
            var state = listStates[i];
            if(state == furthest)
            {
                component.set("v.furthestStepNumber", i);
                return;
            }
        }

    }

    , navToPage:function(component, stateValue, pageName)
    {
        var listStates = component.get('v.listStates');

        var app = component.get('v.application');

        // the furthest progress
        var furthestState = app.Furthest_Progress__c;
        var iFurthest = listStates.indexOf(furthestState);

        var iTarget = listStates.indexOf(stateValue);

        console.debug('ApplicationPathHelper::navToPage:: target = ' + iTarget + ', furthest = ' + iFurthest);

        if(iTarget > iFurthest)
        {
            // not allowed to jump forward
            component.set('v.navError', true);
        }
        else {
            var urlEvent = $A.get("e.force:navigateToURL");
            var appId = component.get("v.appId");
            urlEvent.setParams({
                "url": pageName + '?appId=' + appId
            });

            urlEvent.fire();
        }
    }
})