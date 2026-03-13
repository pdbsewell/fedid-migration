({
    showCourseSearchSpinner : function(component, toShow) {
        component.set("v.showSpinner", toShow);
    }

    , showOfferingsSpinner: function(component, toShow)
    {
        component.set("v.showOfferingSpinner", toShow);
    }

    , showSearchResultsSpinner: function(component, toShow)
    {
        component.set("v.showSearchSpinner", toShow);
    }

    , getCourseSearchAppId:function(component)
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

    , storeAddedOfferingIds:function(component)
    {
        var acps = component.get("v.acps");
        var offeringIds = [];
        for(var i = 0; i < acps.length; ++i)
        {
            var acp = acps[i];
            offeringIds.push(acp.Course_Offering__c);
        }
        component.set("v.addedOfferingIds", offeringIds);

    }




    , clearCourseSearchState:function(component)
    {
        component.set("v.searchString", "");
        component.set("v.searchInlineResults", []);
        component.set("v.disableSelectOffering", true);
        component.set("v.showInlineResults", false);

        component.set("v.selectedCourseOfferings", []);
        component.set("v.selectedAreasOfStudy", []);
    }

    , makeCourseListDisplay:function(component, arrCourseCodes)
    {
        // make the selected course codes string
        var arrCourseTitles = [];
        for(var i = 0; i < arrCourseCodes.length; ++i)
        {
            var courseCode = arrCourseCodes[i];
            var sCourseName = courseCode + ' - ' + this.getCourseTitleByCode(component, courseCode);
            arrCourseTitles.push(sCourseName);
        }
        component.set("v.selectedCourseNames", arrCourseTitles);
    }

    , getCourseTitleByCode:function(component, code)
    {
        var courseCodes = component.get("v.searchInlineResults");
        var iLen = courseCodes.length;
        for(var i = 0; i < iLen; ++i)
        {
            var objCourse = courseCodes[i];
            if(objCourse.Course_Code__c == code)
            {
                return objCourse.Course_Title__c;
            }
        }

        return "";
    }

    , clearFilterArrays:function(component)
    {
        component.set("v.filterAttendanceType", []);
        component.set("v.filterLocation", []);
        component.set("v.filterCourseStart", []);
        component.set("v.filterCourseType", []);
    }

    , updateSelectedFilterOptions:function(component, changedValue, changedState, selectionArrayName)
    {
        var arrSelected = component.get(selectionArrayName);
        if(!arrSelected)
        {
            arrSelected = [];
        }
        var iIndex = arrSelected.indexOf(changedValue);

        if(changedState && iIndex < 0)
        {
            arrSelected.push(changedValue);
        }

        else if(!changedState && iIndex >= 0)
        {
            arrSelected.splice(iIndex, 1);
        }

        component.set(selectionArrayName, arrSelected);
        this.updateFilteredResults(component);
    }

    , updateFilteredResults:function(component)
    {
        this.showOfferingsSpinner(component, true);

        var addedIds = component.get("v.addedOfferingIds");

        // the course starts selected
        var courseStart = component.get("v.selectedCourseStarts");

        var arrOfferingsByCourseCode = component.get("v.offeringsByCourseCode");
        var arrFiltered = [];
        for(var i = 0; i < arrOfferingsByCourseCode.length; ++i)
        {
            var objCourseCode = arrOfferingsByCourseCode[i];
            var courseCode = objCourseCode.courseCode;
            var arrOfferings = objCourseCode.offerings;

            var offeringsFiltered = [];
            for(var j = 0; j < arrOfferings.length; ++j) {
                var offering = arrOfferings[j];

                if (courseStart.indexOf(offering.Admission_Calendar_Description__c) >= 0) {
                    offeringsFiltered.push(offering);
                }

                offering.added = false;
                if(addedIds.indexOf(offering.Id) >= 0)
                {
                    offering.added = true;
                }
            }

            // if any are left, push it to the overall filter
            if(offeringsFiltered.length > 0)
            {
                //separate course offerings by location
                let courseByLocationAndFeeTypeMap = new Map();
                offeringsFiltered.forEach(function(courseOffering) {    
                    let locationCode = courseOffering.Location_Code__c ? courseOffering.Location_Code__c : '';
                    let typeOfPlaceDescription = courseOffering.Type_of_Place_Description__c ? courseOffering.Type_of_Place_Description__c : '';
                    let attendanceTypeDescription = courseOffering.Attendance_Type_Description__c ? courseOffering.Attendance_Type_Description__c : '';
                    let attendanceModeDescription = courseOffering.Attendance_Mode_Description__c ? courseOffering.Attendance_Mode_Description__c : '';
                
                    if(!courseByLocationAndFeeTypeMap.has(locationCode + ':::' + typeOfPlaceDescription + ':::' + attendanceTypeDescription + ':::' + attendanceModeDescription)){
                        courseByLocationAndFeeTypeMap.set(locationCode + ':::' + typeOfPlaceDescription + ':::' + attendanceTypeDescription + ':::' + attendanceModeDescription, []);
                    }
                    courseByLocationAndFeeTypeMap.get(locationCode + ':::' + typeOfPlaceDescription + ':::' + attendanceTypeDescription + ':::' + attendanceModeDescription).push(courseOffering);
                });
                
                //assign objFiltered from location filtered map
                courseByLocationAndFeeTypeMap.forEach(function(values, keys) {
                    let hasUnitSetCount = 0;
                    let hasNoUnitSetCount = 0;
                    values.forEach(function(value, index, object) {
                        //check if there are discrepancy with the unit set code
                        if(value.Unit_Set_Code__c){
                            hasUnitSetCount += 1;
                        }else{
                            hasNoUnitSetCount += 1;
                        }
                    });
                    
                    let hasAtleastOneUnitSet = false;
                    values.forEach(function(value, index, object) {
                        //if atleast one course offering has a unit set code - then show the select stream
                        if(value.Unit_Set_Code__c){
                            hasAtleastOneUnitSet = true;
                        }else{
                            if(!((hasUnitSetCount != 0 && hasNoUnitSetCount == 0) || (hasUnitSetCount == 0 && hasNoUnitSetCount != 0))){
                            	object.splice(index, 1);                                
                            }
                        }
                    });
                    var objFiltered = {
                        'courseCode' : courseCode,
                        //'hasUnitSets' : objCourseCode.hasUnitSets,
                        'hasUnitSets' : hasAtleastOneUnitSet,
                        'offerings' : values
                    };
                    arrFiltered.push(objFiltered);
                });
            }
        }


        component.set("v.filteredCourseOfferings", arrFiltered);
        this.showOfferingsSpinner(component, false);
    }

    , showAreasOfStudyOfferings:function(component, courseCode, location, feeType, mode)
    {
        component.set("v.courseCodeForAreaOfStudy", courseCode);

        // copy the existing selection in case of cancel
        component.set("v.currentSelectedAreasOfStudy", component.get("v.selectedAreasOfStudy"));

        // add the list of offerings
        var arrFiltered = component.get("v.filteredCourseOfferings");
        var offeringsAoS = [];
        var courseTitle = '';
        for(var i = 0; i < arrFiltered.length; ++i)
        {
            //condition is to only process selected table row
            let locationCode = arrFiltered[i].offerings[0].Location_Code__c ? arrFiltered[i].offerings[0].Location_Code__c : '';
            if(locationCode == location){
                let typePlaceDescription = arrFiltered[i].offerings[0].Type_of_Place_Description__c ? arrFiltered[i].offerings[0].Type_of_Place_Description__c : '';
                if(typePlaceDescription == feeType){
                    let modeList = mode.split('::');
                    let attendanceType = arrFiltered[i].offerings[0].Attendance_Type_Description__c ? arrFiltered[i].offerings[0].Attendance_Type_Description__c : '';
                    let attendanceMode = arrFiltered[i].offerings[0].Attendance_Mode_Description__c ? arrFiltered[i].offerings[0].Attendance_Mode_Description__c : '';
                    if(attendanceType == modeList[0] && attendanceMode == modeList[1]){
                        var objOffering = arrFiltered[i];
                        if(objOffering.courseCode == courseCode && objOffering.hasUnitSets == true)
                        {
                            offeringsAoS = objOffering.offerings;
                            courseTitle = offeringsAoS[0].Course_Title__c;
                            break;
                        }
                    }
                }
            }
        }

        component.set("v.areaOfStudyCourse", courseCode + ' - ' + courseTitle);
        component.set("v.areasOfStudyOfferings", offeringsAoS);
        component.set("v.showAreaOfStudy", true);
    }


    , updateAreasSelected:function(component)
    {
        var arrSelectedAreas = component.get("v.selectedAreasOfStudy");

        var currentCourseCode = component.get("v.courseCodeForAreaOfStudy");
        var arrFiltered = component.get("v.filteredCourseOfferings");
        for(var i = 0; i < arrFiltered.length; ++i)
        {
            var objCourseCode = arrFiltered[i];
            var courseCode = objCourseCode.courseCode;

            if(courseCode == currentCourseCode && objCourseCode.hasUnitSets)
            {
                var arrOfferings = objCourseCode.offerings;
                var offeringsUpdated = [];

                objCourseCode.areaSelected = false;
                for(var j = 0; j < arrOfferings.length; ++j)
                {
                    var offering = arrOfferings[j];
                    offering.selected = false;

                    if(arrSelectedAreas.indexOf(offering.Id) >= 0)
                    {
                        offering.selected = true;
                        // update the checkbox
                        objCourseCode.areaSelected = true;
                    }

                    offeringsUpdated.push(offering);
                }
            }
        }
        component.set("v.filteredCourseOfferings", arrFiltered);
        //this.updateAddButton(component);

    }

    , clearAreasOfStudyForCourseCode:function(component, courseCode, location, feeType, mode)
    {
        var arrFiltered = component.get("v.filteredCourseOfferings");
        for(var i = 0; i < arrFiltered.length; ++i)
        {
            //condition is to only process selected table row
            let locationCode = arrFiltered[i].offerings[0].Location_Code__c ? arrFiltered[i].offerings[0].Location_Code__c : '';
            if(locationCode == location){
                let typePlaceDescription = arrFiltered[i].offerings[0].Type_of_Place_Description__c ? arrFiltered[i].offerings[0].Type_of_Place_Description__c : '';
                if(typePlaceDescription == feeType){      
                    let modeList = mode.split('::');
                    let attendanceType = arrFiltered[i].offerings[0].Attendance_Type_Description__c ? arrFiltered[i].offerings[0].Attendance_Type_Description__c : '';
                    let attendanceMode = arrFiltered[i].offerings[0].Attendance_Mode_Description__c ? arrFiltered[i].offerings[0].Attendance_Mode_Description__c : '';
                    if(attendanceType == modeList[0] && attendanceMode == modeList[1]){
                        var objCourseCode = arrFiltered[i];
                        if(objCourseCode.courseCode && objCourseCode.hasUnitSets)
                        {
                            var arrOfferings = objCourseCode.offerings;
                            var offeringsUpdated = [];

                            objCourseCode.areaSelected = false;

                            // set them all to false
                            for(var j = 0; j < arrOfferings.length; ++j)
                            {
                                var offering = arrOfferings[j];
                                offering.selected = false;
                                offeringsUpdated.push(offering);
                            }
                        }
                    }
                }
            }
        }
        component.set("v.filteredCourseOfferings", arrFiltered);
    }

    , selectCourseOffering:function(component, offeringId, checked)
    {

        // find index of course code
        var arrCourseOfferings = component.get("v.selectedCourseOfferings");
        if(arrCourseOfferings.length < 0)
            arrCourseOfferings = [];

        var iCourseId = arrCourseOfferings.indexOf(offeringId);

        if(checked == true && iCourseId < 0)
        {
            // add the Id
            arrCourseOfferings.push(offeringId);
        }
        else if (!checked && iCourseId >= 0)
        {
            // remove by Index
            arrCourseOfferings.splice(iCourseId, 1);
        }

        if(arrCourseOfferings.length > 0)
        {
            component.set("v.disableAddOffering", false);
        }
        else
        {
            component.set("v.disableAddOffering", true);
        }
        component.set("v.selectedCourseOfferings", arrCourseOfferings);
    }



    , reorderACP:function(component, acpId, moveUp)
    {
        this.showCourseSearchSpinner(component, true);

        var arrACPs = component.get("v.acps");
        var iIndex = -1;
        for(var i = 0; i <arrACPs.length; ++i)
        {
            if(arrACPs[i].Id == acpId)
            {
                if(moveUp)
                    iIndex = i-1;
                else
                    iIndex = i+1;
                break;
            }
        }
        component.set("v.highlightedRow", iIndex);


        var appId = component.get("v.appId");
        if(!appId){
            appId = component.get("v.applicationId");
        }
        
        var action = component.get("c.updateACPOrder");
        action.setParams({
            "acpId": acpId,
            "moveUp": moveUp,
            "appId": appId
        });
        action.setCallback(this, function (response) {
            //Get State
            var state = response.getState();
            if (state == "SUCCESS") {
                var objResponse = response.getReturnValue();

                // refresh the acp list
                component.set("v.acps", objResponse.acps);
                this.storeAddedOfferingIds(component);

                // go back to search state
                component.set("v.STATE", "SEARCH");

                this.showCourseSearchSpinner(component, false);
            }
        });
        $A.enqueueAction(action);

    },
    showCourses:function(component, event)
    {   
        component.set("v.showInlineSpinner", true);
        component.set("v.showInlineResults", true);

        // clear previous selection
        component.set('v.selectedCourseCodes', []);

        var searchString = component.get("v.searchString");
        var citizenshipType = component.get("v.citizenshipType");
        var application = component.get("v.application");
        
        if(searchString.length > 2) {
            var action = component.get("c.searchCourses");
            action.setParams({
                "searchString": searchString,
                "campusLocation": application.Campus_Location__c,
                "citizenshipType":citizenshipType,
                "studyType":application.Type_of_Study__c
            });
            action.setCallback(this, function (response) {
                //Get State
                var state = response.getState();
                if (state == "SUCCESS") {
                    var arrCourses = response.getReturnValue();
                    component.set("v.searchInlineResults", arrCourses);
                    component.set("v.showInlineResults", true);
                    component.set("v.showInlineSpinner", false);
                    // scroll to results
                    var divResults = component.find("anchorResults");
                    var element = divResults.getElement();
                    var rect = element.getBoundingClientRect();
                    //scrollTo({top: rect.top + window.scrollY, behavior: "smooth"});
                }
                else {
                    component.set("v.inlineMessage", "Error while searching");
                }
            });
            $A.enqueueAction(action);
        }
        else
        {
            component.set("v.showInlineResults", false);
            component.set("v.showInlineSpinner", false);
        }
    },
    studyDurationSave:function(component, event, helper)
    {
        var action = component.get("c.updateStudyDuration");
        var cbox1 = component.get("v.onesem");
        var duration = cbox1?'1':'2';
        var appId = component.get("v.application").Id;
        component.set("v.showSpinner", true);
        action.setParams({
            "duration": duration,
            "appId": appId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var courseEvent = component.getEvent("acpEvent");
                courseEvent.setParams({
                    "eventType" : "Duration"
                });
                courseEvent.fire();
                var arrCourses = response.getReturnValue();
            }else{
                //console.log('failure');
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    }

})