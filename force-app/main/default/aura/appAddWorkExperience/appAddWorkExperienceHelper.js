({
	
    showWorkExpSpinner : function(component, toShow) {
		component.set("v.showSpinner", toShow);
	}

    , getWorkExpAppId:function(component)
    {
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
                    return;
                }
            }
        }
    }

	, clearWorkExpState:function(component)
	{
        component.set("v.workExp", null);
        component.set("v.showErrors", false);
        component.set("v.showConfirmDelete", false);
        component.set("v.idToDelete", null);
        component.set("v.addRef", false);
	}
    , isUnsafe: function(dataObject) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g;
         return XML_REGEX_PATTERN.test(JSON.stringify(dataObject));
    }

    /**
     * setFieldPatters method
     * @author       Arnie Ug
     * @date         12.04.2024        
     * @description  Used to set regExpression patterns for front end validation
     *               Adding Validation Rules/RegEx to a Position, Employer, Given and Family Names fields
     *               Variable creation required because cmp does not allow "<" as part of the cmp attribute value AND to centralize RegExp location.
     * 
     * @param component
     */
    , setFieldPatterns:function(component){
        //
        var employmentRegExp = "[^`=~$%^\\\;:\\/\\{\\}\\|:<>]*";
        component.set("v.employmentRegExp", employmentRegExp);
        component.set("v.employmentPatterMsg", "The following special characters are not permitted: `=~$%^\\;:\/\{\}\|:<>"); //does not allow `=~$%^\;:/{}|:<>

        var refereeRegExp = "[^0-9`=~$%^\\\;:\\/\\{\\}\\|:<>!@#&*\\(\\)_+\\[\\],.\"?]*";
        component.set("v.refereeRegExp", refereeRegExp); 
        component.set("v.refereePatterMsg", "No numbers, symbols or special characters: `=~!@#$%^&*\(\)_+\[\]\\;,.\/\{\}\|:“<>?");//does not allow numbers nor \`=~!@#$%^&*()_+[]\\;,./{}|:“<>?
    }

    /**
     * getValidationErrors method
     * @author       Arnie Ug
     * @date         12.04.2024        
     * @description  use to check field validity before proceeding to save field
     * 
     * @param component
     * @param String[] lightningInputIdList
     * @returns array of failed validation messages
     */
    , getValidationErrors: function(component, lightningInputIdList){
        var validationErrors = [];

        lightningInputIdList.forEach(lightningInputId =>{
            var componentField = component.find(lightningInputId);
            if(!componentField.get("v.validity").valid){
                var errorMsg = componentField.get("v.label") + " contains an invalid input";
                validationErrors.push(errorMsg);
            }
        })

        return validationErrors;
    }
})