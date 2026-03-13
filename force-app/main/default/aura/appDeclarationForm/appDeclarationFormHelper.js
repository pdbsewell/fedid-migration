({
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         21.Jun.2017
    * @description  redirects the users to the given URL
    * @revision
    *******************************************************************************/
    gotoURL : function(address) {
    	var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": address,
          "isredirect" :false
        });
        urlEvent.fire();
    },

    navigateBack : function (component, appId) {
        var parentComponent = component.get("v.parent");
        parentComponent.changeSection('payment');

        /*var action = component.get("c.ProcessStatus");
        action.setParams({
            "appId" : appId,
            "direction" : "Backward"
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                //Successfully navigated
                this.gotoURL('/payment?appId=' + appId);
            }
        });

        $A.enqueueAction(action);*/
    },

    showErrors:function(component, arrErrors, appRecordId)
    {
        var iLen = arrErrors.length;

        var TOO_MANY_ERRORS = ['Multiple errors in this section'];

        var arrErrorItems = [];
        for(var i = 0; i < iLen; ++i)
        {
            var tupleError = arrErrors[i];

            var section = tupleError.section;
            var sectionLabel = tupleError.label;
            var errors = tupleError.errors;
            // truncate if more than 3
            if(errors.length > 3)
            {
                tupleError.errors = TOO_MANY_ERRORS;
            }


            var sectionUrl = '/';
            switch(section)
            {
                case 'online_credit':
                    sectionUrl = 'applicationsuccess';
                    break;
                case 'course_preference':
                    sectionUrl = 'course-selection';
                    break;
                case 'qualifications':
                    sectionUrl = 'qualifications-work-experience';
                    break;
                case 'contact':
                case 'citizenship':
                case 'under_18':
                    sectionUrl = 'personal-details';
                    break;
                case 'sponsorship':
                    sectionUrl = 'external-scholarship';
                    break;
                case 'payment':
                   sectionUrl = 'payment';
                   break;
            }
            sectionUrl += '?appId=' + appRecordId;
            tupleError.url = sectionUrl;
            arrErrorItems.push(tupleError);
        }
        component.set("v.listErrorItems", arrErrorItems);
    }

})