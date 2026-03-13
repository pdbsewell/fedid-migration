({
    doInit : function(component, event, helper) {
        helper.showCourseSearchSpinner(component, true);
        helper.getCourseSearchAppId(component);

        var appId = component.get("v.appId");
        if(!appId){
            appId = component.get("v.applicationId");
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + appId;
        }

        if(appId) {
            var action = component.get("c.getCourseSearchInitLoad");
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

                    var contact = objResponse.contact;
                    component.set("v.contact", contact);


                    // store the citizenship type, subject to change
                    //component.set("v.citizenshipType", objUser.App_Residency_Status__c);
                    component.set("v.citizenshipType", objResponse.application.Residency_Status__c);
                    component.set("v.studyType", objResponse.application.Type_of_Study__c);
                    component.set("v.sourceSystem", objResponse.application.Source_System__c);
                    // store the application for fields, eg campus location
                    component.set("v.application", objResponse.application);
                    //disable editing if the application is nominator created
                    if(objResponse.appCreatedBy!='Monash Partner Community Login User')
                    {
                        component.set("v.createdByNominator", false);
                       // helper.fireEvt(component, event);
                    }

                    // store the current ACPs
                    var arrACPs = objResponse.acps;
                    component.set("v.acps", arrACPs);

                    // default sections open
                    var arrOpenSections = ['ACPs'];
                    if(arrACPs.length == 0)
                    {
                        arrOpenSections.push('Search');
                    }
                    component.set("v.openSectionsMain", arrOpenSections);
                    helper.storeAddedOfferingIds(component);
                    if(component.get("v.sourceSystem")== 'Partner')
                    {
                        component.set("v.disableRemoveACP", true);
                    }
                    if(component.get("v.studyType") == 'Study Abroad')
                    {
                        component.set("v.showStudyDuration",true); 
                        component.set("v.searchString", "Study Abroad");
                        component.set("v.MAApplication", true);
                        if(objResponse.application.Duration_of_Study__c=='1')
                        {
                            component.set("v.twosem",false);
                            component.set("v.onesem",true);
                        }else if(objResponse.application.Duration_of_Study__c=='2')
                        {
                            component.set("v.twosem",true);
                            component.set("v.onesem",false);
                        }
                       if(component.get("v.acps").length>0)
                            component.set("v.showUOSections",true); 
                        else
                            component.set("v.showUOSections",false);
                        
                        helper.showCourses(component, event);
                    }else if(component.get("v.studyType") == 'Exchange')
                    {
                        component.set("v.searchString", "Exchange");
                        component.set("v.showStudyDuration",true); 
                        component.set("v.MAApplication", true);
                        if(objResponse.application.Duration_of_Study__c=='1')
                        {
                            component.set("v.twosem",false);
                            component.set("v.onesem",true);
                        }else if(objResponse.application.Duration_of_Study__c=='2')
                        {
                            component.set("v.twosem",true);
                            component.set("v.onesem",false);
                        }

                        if(component.get("v.acps").length>0)
                            component.set("v.showUOSections",true); 
                        else
                            component.set("v.showUOSections",false);
                        helper.showCourses(component, event);
                    }

                    helper.showCourseSearchSpinner(component, false);
                }
            });
            $A.enqueueAction(action);
        }
        else {
            helper.showCourseSearchSpinner(component, false);
        }

    }

    , focusSearch:function(component, event, helper)
    {
        var divSearch = component.find("anchorSearch");
        var element = divSearch.getElement();
        var rect = element.getBoundingClientRect();
        //scrollTo({top: rect.top + window.scrollY, behavior: "smooth"});
        component.find("lookupField").focus();
    }

    , showSearchCourses:function(component, event, helper)
    {
        component.set("v.STATE", "SEARCH");
    }

    , onblur : function(component, event, helper)
    {
        component.set("v.showInlineResults", false);
    }

    , keyPressSearch:function(component, event, helper)
    {
        helper.showCourses(component, event);
    }

    , onChangeCourseCode:function(component, event, helper)
    {
        var checkbox = event.getSource();
        var courseCode = checkbox.get("v.value");
        var checked = checkbox.get("v.checked");

        // find index of course code
        var arrCourseCodes = component.get("v.selectedCourseCodes");
        var iCourseCode = arrCourseCodes.indexOf(courseCode);

        if(checked == true && iCourseCode < 0)
        {
            // add
            arrCourseCodes.push(courseCode);
        }
        else if (!checked && iCourseCode >= 0)
        {
            // remove
            arrCourseCodes.splice(iCourseCode, 1);
        }
        component.set("v.selectedCourseCodes", arrCourseCodes);
    }

    , searchAgain:function(component, event, helper)
    {
        helper.clearCourseSearchState(component);
        component.set("v.STATE", "SEARCH");
    }


    , searchOfferings:function(component, event, helper)
    {
        helper.showSearchResultsSpinner(component, true);

        // display the courses being searched
        var arrCourseCodes = component.get("v.selectedCourseCodes");
        helper.makeCourseListDisplay(component, arrCourseCodes);

        // citizenship filter
        var citizenshipType = component.get("v.citizenshipType");

        var application = component.get("v.application");

        // clear the search params
        helper.clearCourseSearchState(component);

        // clear the offerings filters
        component.set("v.filterCourseStart", []);

        var action = component.get("c.searchCourseOfferingsByCourseCode");
        action.setParams({
            "courseCodes": arrCourseCodes,
            "campusLocation": application.Campus_Location__c,
            "citizenshipType":citizenshipType
        });
        action.setCallback(this, function (response) {
            //Get State
            var state = response.getState();
            if (state == "SUCCESS") {
                var objResponse = response.getReturnValue();

                var arrOfferingsByCourseCode = objResponse.offeringsByCourseCode;
                component.set("v.offeringsByCourseCode", arrOfferingsByCourseCode);

                // filter options
                component.set("v.courseStartOptions", objResponse.courseStarts);
            }
            else {
                console.error('Error while searching for Course Offerings');
            }

            // switch states
            component.set("v.selectedCourseStarts", []);
            component.set("v.STATE", "COURSE_START");


            helper.showSearchResultsSpinner(component, false);
        });
        $A.enqueueAction(action);
    }

    , onUpdateCourseStart:function (component, event, helper)
    {
        var checkbox = event.getSource();
        var changedValue = checkbox.get("v.value");
        var checked = checkbox.get("v.checked");

        var arrSelected = component.get("v.selectedCourseStarts");
        if(!arrSelected)
        {
            arrSelected = [];
        }
        var iIndex = arrSelected.indexOf(changedValue);

        if(checked && iIndex < 0)
        {
            arrSelected.push(changedValue);
        }

        else if(!checked && iIndex >= 0)
        {
            arrSelected.splice(iIndex, 1);
        }

        component.set("v.selectedCourseStarts", arrSelected);
    }

    , backToCourseStarts:function(component, event, helper)
    {
        // do not reset the course start selection
        component.set("v.STATE", "COURSE_START");
    }

    , showOfferings:function(component, event, helper)
    {
        component.set("v.selectedCourseOfferings", []);
        component.set("v.selectedAreasOfStudy", []);

        helper.updateFilteredResults(component);

        // next state
        component.set("v.STATE", "COURSE_OFFERINGS");

        var action = component.get("c.PauseForScroll");
        action.setCallback(this, function (response) {
            var divTarget = component.find("anchorOfferings");
            var element = divTarget.getElement();
            var rect = element.getBoundingClientRect();
            //scrollTo({top: rect.top + window.scrollY, behavior: "smooth"});
        });
        $A.enqueueAction(action);


    }



    , onChangeAreaOfStudyParent:function (component, event, helper)
    {
        var btn = event.getSource();
        var parametersList = btn.get('v.name').split(':::');
        var courseCode = parametersList[0];
        var location = parametersList[1];
        var feeType = parametersList[2];
        var mode = parametersList[3];
        var checked = btn.get("v.checked");

        if(checked)
        {
            helper.showAreasOfStudyOfferings(component, courseCode, location, feeType, mode);
        }
        else
        {
            // clear all selections for this course code
            helper.clearAreasOfStudyForCourseCode(component, courseCode, location, feeType, mode);
        }
    }

    , onClickSelectStreams:function(component, event, helper)
    {
        var btn = event.getSource();
        var parametersList = btn.get('v.name').split(':::');
        var courseCode = parametersList[0];
        var location = parametersList[1];
        var feeType = parametersList[2];
        var mode = parametersList[3];
        helper.showAreasOfStudyOfferings(component, courseCode, location, feeType, mode);
    }

    , onChangeCourseOffering:function(component, event, helper)
    {
        var checkbox = event.getSource();
        var offeringId = checkbox.get("v.value");
        var checked = checkbox.get("v.checked");

        helper.selectCourseOffering(component, offeringId, checked);
    }

    , onChangeAreaOfStudy:function(component, event, helper)
    {
        // when selecting an area of study checkbox
        var checkbox = event.getSource();
        var offeringId = checkbox.get("v.value");
        var checked = checkbox.get("v.checked");

        var arrSelectedAreas = component.get("v.selectedAreasOfStudy");
        if(arrSelectedAreas.length < 0)
            arrSelectedAreas = [];
        var iOffering = arrSelectedAreas.indexOf(offeringId);
        if(checked && iOffering < 0)
        {
            arrSelectedAreas.push(offeringId);
        }
        else if(!checked && iOffering >= 0)
        {
            arrSelectedAreas.splice(iOffering, 1);
        }

        component.set("v.selectedAreasOfStudy", arrSelectedAreas);

    }

    , addAreasOfStudy:function(component, event, helper)
    {
        helper.updateAreasSelected(component);
        component.set("v.showAreaOfStudy", false);
    }

    , cancelAreaOfStudy:function(component, event, helper)
    {
        // revert selection to pre-opening
        component.set("v.selectedAreasOfStudy", component.get("v.currentSelectedAreasOfStudy"));
        helper.updateAreasSelected(component);
        component.set("v.showAreaOfStudy", false);
    }


    , toggleShowFilters:function(component, event, helper)
    {
        var filtersShowing = component.get("v.showFilters");
        filtersShowing = !filtersShowing;

        component.set("v.showFilters", filtersShowing);
    }

    , clearFilters:function(component, event, helper)
    {
        helper.showCourseSearchSpinner(component, true);

        helper.clearFilterArrays(component);

        var arrCheckboxes = component.find("filterCheckbox");
        if(Array.isArray(arrCheckboxes)) {
            for (var i = 0; i < arrCheckboxes.length; ++i) {
                arrCheckboxes[i].set("v.checked", false);
            }
        }
        else if(arrCheckboxes)
        {
            // there is only 1 checkbox
            arrCheckboxes.set("v.checked", false);
        }

        helper.updateFilteredResults(component);

        helper.showCourseSearchSpinner(component, false);
    }

    , onUpdateFilterLocation:function(component, event, helper)
    {
        var checkbox = event.getSource();
        var filterValue = checkbox.get("v.value");
        var checked = checkbox.get("v.checked");
        helper.updateSelectedFilterOptions(component, filterValue, checked, "v.filterLocation");

    }
    , onUpdateFilterCourseStart:function(component, event, helper)
    {
        var checkbox = event.getSource();
        var filterValue = checkbox.get("v.value");
        var checked = checkbox.get("v.checked");
        helper.updateSelectedFilterOptions(component, filterValue, checked, "v.filterCourseStart");

    }
    , onUpdateFilterAttendanceType:function(component, event, helper)
    {
        var checkbox = event.getSource();
        var filterValue = checkbox.get("v.value");
        var checked = checkbox.get("v.checked");
        helper.updateSelectedFilterOptions(component, filterValue, checked, "v.filterAttendanceType");

    }

    , onUpdateFilterCourseType:function (component, event, helper)
    {
        var checkbox = event.getSource();
        var filterValue = checkbox.get("v.value");
        var checked = checkbox.get("v.checked");
        helper.updateSelectedFilterOptions(component, filterValue, checked, "v.filterCourseType");
    }

    , addCourseOfferings:function(component, event, helper)
    {
        helper.showCourseSearchSpinner(component, true);
        var appId = component.get("v.appId");
        if(!appId){
            appId = component.get("v.applicationId");
        }

        // get all the selected Ids
        var courseOfferingIds = component.get("v.selectedCourseOfferings");
        var selectedAreas = component.get("v.selectedAreasOfStudy");
        courseOfferingIds = courseOfferingIds.concat(selectedAreas);

        var acps = component.get("v.acps");
        var acpCap = component.get("v.MAApplication")?1:5;

        if(acps.length + courseOfferingIds.length > acpCap)
        {
            // show alert box
            component.set("v.showErrorAlert", true);
            helper.showCourseSearchSpinner(component, false);
        }
        else
        {
            var action = component.get("c.addACPs");
            action.setParams({
                "courseOfferingIds":courseOfferingIds,
                "appId": appId
            });
            action.setCallback(this, function (response) {
                //Get State
                var state = response.getState();
                if (state == "SUCCESS") {                    
                    var courseEvent = component.getEvent("acpEvent");
                    courseEvent.setParams({
                        "eventType" : "AddACP" 
                    });
                    courseEvent.fire();
                    var objResponse = response.getReturnValue();

                    // refresh the acp list
                    component.set("v.acps", objResponse.acps);
                    helper.storeAddedOfferingIds(component);

                    // go back to search state
                    component.set("v.STATE", "SEARCH");

                    helper.showCourseSearchSpinner(component, false);
                }
            });
            $A.enqueueAction(action);

        }


    }

    , confirmRemoveACP:function(component, event, helper)
    {
        helper.showCourseSearchSpinner(component, true);
        var appId = component.get("v.appId");
        if(!appId){
            appId = component.get("v.applicationId");
        }
        
        // get the selected ACP Id
        var acpId = component.get("v.acpIdToRemove");

        var action = component.get("c.removeACP");
        action.setParams({
            "acpId": acpId,
            "appId": appId
        });
        action.setCallback(this, function (response) {
            //Get State
            var state = response.getState();
            if (state == "SUCCESS") {                
                var objResponse = response.getReturnValue();

                // refresh the acp list
                component.set("v.acps", objResponse.acps);
                helper.storeAddedOfferingIds(component);

                // close the modal box
                component.set("v.showRemoveACP", false);

                // go back to search state
                component.set("v.STATE", "SEARCH");

                var courseEvent = component.getEvent("acpEvent");
                courseEvent.setParams({
                    "eventType" : "RemoveACP" 
                });
                courseEvent.fire();

                helper.showCourseSearchSpinner(component, false);
            }
        });
        $A.enqueueAction(action);
    }

    , showRemovePopup:function(component, event, helper)
    {
        var acpId = event.getSource().get('v.name');
        component.set("v.acpIdToRemove", acpId);
        component.set("v.showRemoveACP", true);
    }

    , cancelRemoveACP:function(component, event, helper)
    {
        component.set("v.acpIdToRemove", null);
        component.set("v.showRemoveACP", false);
    }

    , moveACPUp:function(component, event, helper)
    {
        var acpId = event.getSource().get('v.name');
        helper.reorderACP(component, acpId, true);
    }
    , moveACPDown:function(component, event, helper)
    {
        var acpId = event.getSource().get("v.name");
        helper.reorderACP(component, acpId, false);
    }
    , closeError:function(component, event, helper)
    {
        component.set("v.showErrorAlert", false);
    },
    onChangeOneSem:function(component, event, helper)
    {
        var src = event.getSource();
        var checked = src.get("v.checked");
        if(checked)
        {
            var cbox = component.find("twosem");
            cbox.set("v.checked", false);
            component.set("v.twosem",false);
            component.set("v.onesem",true);
        }else{
            var cbox = component.find("twosem");
            cbox.set("v.checked", true);
            component.set("v.twosem",true);
            component.set("v.onesem",false);
        }
      
        helper.studyDurationSave(component, event, helper);
    },
    onChangeTwoSem:function(component, event, helper)
    {
        var src = event.getSource();
        var checked = src.get("v.checked");
        if(checked)
        {
            var cbox = component.find("onesem");
            cbox.set("v.checked", false);
            component.set("v.twosem",true);
            component.set("v.onesem",false);
        }else{
            var cbox = component.find("onesem");
            cbox.set("v.checked", true);
            component.set("v.twosem",true);
            component.set("v.onesem",false);
        }
        helper.studyDurationSave(component, event, helper);
   }
    /*
    ,clearHighlight:function(component, event, helper)
    {
        component.set("v.highlightedRow", -1);
    }
    */
})