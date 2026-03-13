({

    /**
     * Initial loading function, parses a JSON from the apex class with the fields:
     * user: the current logged in user
     * contactId: the Id of the related contact (applicant)
     * workExperiences: the list of current work experience records added to this application, ie editable
     * historicalWorkExperiences: the list of work experience records from previous applications
     * countryOptions: a list of options to populate the Country dropdown, these are country attribute records
     *
     * @param component
     * @param event
     * @param helper
     * 
     * @revision
     *           12.04.2024 - Arnie Ug - Adding Validation Rules/RegEx to a Position, Employer, Given and Family Names fields
     */
	doInit : function(component, event, helper) {

		helper.showWorkExpSpinner(component, true);

		helper.getWorkExpAppId(component);

		helper.setFieldPatterns(component); // 12.04.2024 - Arnie Ug - setup validaiton pattern

        var appId = component.get("v.appId");
        if(!appId){
            appId = component.get("v.applicationId");
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + appId;
        }
        if(appId) {
            var action = component.get("c.getInitLoad");
            action.setParams({
                "appId": appId
            });
            action.setCallback(this, function (response) {
                //Get State
                var state = response.getState();
                if (state == "SUCCESS") {

                    var objResponse = response.getReturnValue();

                    // user
                    var objUser = objResponse.user;
                    component.set("v.user", objUser);

                    // contact/applicant
                    var contactId = objResponse.contactId;
                    component.set("v.contactId", contactId);

                    var listWorkExps = objResponse.workExperiences;
                    component.set("v.workExperiences", listWorkExps);

                    var listHistoricalWorkExps = objResponse.historicalWorkExperiences;
                    component.set("v.historicalWorkExperiences", listHistoricalWorkExps);

                    var countryOptions = objResponse.countryOptions;
                    countryOptions.unshift({"label":"choose one",
					"value":""});
                    component.set("v.countryOptions", countryOptions);

                    helper.showWorkExpSpinner(component, false);
                }
            });
            $A.enqueueAction(action);
        }
        else {
            helper.showWorkExpSpinner(component, false);
        }

	}

    /**
     * Changes the display state of the component to enter details for a new Work Exp record
     * NB, the record is NOT created yet
     * @param component
     * @param event
     * @param helper
     */
	, onClickAddNew:function(component, event, helper)
	{
		component.set("v.workExp", {});
		component.set("v.state", "EDIT");
	}

    /**
     * Retrieves the target record for editing. Apex CC returns a JSON with the following field
     * workExperiences: a list with a single element, which is the target record for editing.
     *
     * then changes the display to editing mode (ie, new mode pre-populated)
     * @param component
     * @param event
     * @param helper
     */
	, onClickEdit:function(component, event, helper)
	{
		helper.showWorkExpSpinner(component, true);
        var source = event.getSource(); // this would give that particular component
        var workExpId = source.get("v.name"); // returns the id

        var action = component.get("c.retrieveWorkExpForEdit");
        action.setParams({
            "workExpId": workExpId
        });
        action.setCallback(this, function (response) {
            //Get State
            var state = response.getState();
            if (state == "SUCCESS") {

                var objResponse = response.getReturnValue();

                var listWorkExps = objResponse.workExperiences;

                if(listWorkExps.length == 1)
				{
					var objWorkExp = listWorkExps[0];
                    component.set("v.workExp", objWorkExp);

                    // show/hide the referee panel
					if(objWorkExp.Contact_Person_First_Name__c
						|| objWorkExp.Contact_Person_Last_Name__c
						|| objWorkExp.Contact_Person_Email__c
						|| objWorkExp.Contact_Person_Phone__c
					)
					{
						component.set("v.addRef", true);
					}
                    component.set("v.state", "EDIT");
				}

                helper.showWorkExpSpinner(component, false);
            }
        });
        $A.enqueueAction(action);

	}

    /**
     * If referee details need to be added (not mandatory)
     * @param component
     * @param event
     * @param helper
     */
	, onClickAddReferee:function(component, event, helper)
	{
		component.set("v.addRef", true);
	}

    /**
     * On clicking delete, prompt the user with a confirmation dialogue. The Id of the delete target needs
     * to be stored in a temp attribute (v.idToDelete)
     * @param component
     * @param event
     * @param helper
     */
	, showConfirmDeletePopup:function(component, event, helper)
	{
        var source = event.getSource(); // this would give that particular component
        var workExId = source.get("v.name"); // returns the id
		component.set("v.idToDelete", workExId);

		component.set("v.showConfirmDelete", true);
	}

    /**
     * On confirmation of delete, apex CC function deletes the record and returns JSON similar to the initial load
     * workExperiences: the list of current work experience records added to this application, ie editable
     * historicalWorkExperiences: the list of work experience records from previous applications
     *
     * @param component
     * @param event
     * @param helper
     */
	, onClickConfirmDelete:function(component, event, helper)
	{

        var appId = component.get("v.appId");
        if(!appId){
            appId = component.get("v.applicationId");
        }
		var workExpId = component.get("v.idToDelete");

		var action = component.get("c.deleteWorkExp");
        action.setParams({
            "workExpId": workExpId,
			"appId" : appId
        });
        action.setCallback(this, function (response) {
            //Get State
            var state = response.getState();
            if (state == "SUCCESS") {

                var objResponse = response.getReturnValue();

                var listWorkExps = objResponse.workExperiences;
                component.set("v.workExperiences", listWorkExps);
                var listHistoricalWorkExps = objResponse.historicalWorkExperiences;
                component.set("v.historicalWorkExperiences", listHistoricalWorkExps);

                helper.clearWorkExpState(component);
                component.set("v.state", "START");

                helper.showWorkExpSpinner(component, false);
            }
        });
        $A.enqueueAction(action);
	}

    /**
     * close the confirmation box
     * @param component
     * @param event
     * @param helper
     */
	, onClickCancelDelete:function(component, event, helper)
	{
		helper.clearWorkExpState(component);
		component.set("v.showConfirmDelete", false);
	}

    /**
     * Attempt to save the work experience record, if there are errors, it is not saved, and an error popup is displayed.
     * If successful, refreshes the display in a similar way to the initial load
     * @param component
     * @param event
     * @param helper 
     * 
     * @revision
     *           12.04.2024 - Arnie Ug - Adding Validation Rules/RegEx to a Position, Employer, Given and Family Names fields
     */
	, onClickSave:function(component, event, helper)
    {
        var objWorkExp = component.get("v.workExp");
        
        //Validate that start date should be earlier than the end date
        var customFieldErrorList = [];

        var endDateField = component.find("endDate");
        endDateField.setCustomValidity("");
        endDateField.reportValidity();
        if(objWorkExp.Start_Date__c > objWorkExp.End_Date__c){
            var endDateMsg = "Start Date should not be later or than the End Date."
            endDateField.setCustomValidity(endDateMsg);
            endDateField.reportValidity();

            customFieldErrorList.push(endDateMsg);
        }

        var fieldsForValidationList = ["position", "employer", "givenName", "familyName"];
        var validationErrorList = helper.getValidationErrors(component, fieldsForValidationList);
        if(validationErrorList.length > 0){
            customFieldErrorList = customFieldErrorList.concat(validationErrorList);
        }
        

        if(customFieldErrorList.length > 0){
            component.set("v.saveErrors", customFieldErrorList);
            component.set("v.showErrors", true);
            return;
        }

        if (helper.isUnsafe(objWorkExp)) {
            var appErrors = ["One or more input boxes are not in the expected format."];
            component.set("v.saveErrors", appErrors);
            component.set("v.showErrors", true);
            return;
        } 

    	helper.showWorkExpSpinner(component, true);
        var appId = component.get("v.appId");
        if(!appId){
            appId = component.get("v.applicationId");
        }
        var action = component.get("c.saveWorkExperience");
        action.setParams({
            "appId" : appId,
			"workExp": objWorkExp
        });
        action.setCallback(this, function(response){
            //Get State
            var state = response.getState();
            if(state == "SUCCESS")
            {
                var objResponse = response.getReturnValue();


                var saveStatus = objResponse.saveStatus;
                if(saveStatus == 'success')
				{            
                    console.log('saveStatus Success');
					// save completed, back to start
                    var listWorkExps = objResponse.workExperiences;
                    component.set("v.workExperiences", listWorkExps);
                    var listHistoricalWorkExps = objResponse.historicalWorkExperiences;
                    component.set("v.historicalWorkExperiences", listHistoricalWorkExps);

                    helper.clearWorkExpState(component);
                    component.set("v.state", "START");
				}
				else
				{
					// show errors
					var arrErrors = objResponse.errors;
                    if(typeof objResponse.errors == 'undefined'){
                        arrErrors = objResponse.message;
                    }
					component.set("v.saveErrors", arrErrors);
					component.set("v.showErrors", true);
				}

                helper.showWorkExpSpinner(component, false);
            }
            else if (state == 'ERROR'){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error('appAddWorkExpCtller::saveWorkExperience :' + errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
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


    /**
     * cancel editing/creating of the current Work Experience record
     * @param component
     * @param event
     * @param helper
     */
    , onClickCancel:function(component, event, helper)
    {
    	// clear all
		helper.clearWorkExpState(component);

        component.set("v.state", "START");
    }

})