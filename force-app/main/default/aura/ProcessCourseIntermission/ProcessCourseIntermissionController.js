/**
 * Created by angelorivera on 5/5/21.
 */

({

    init: function(cmp) {
        var action = cmp.get('c.doInit');
        action.setParams({
            caseId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            let dataWrapper = response.getReturnValue();
            var state = response.getState();

            if (state === "SUCCESS") {
                if(dataWrapper.mapCourseCodes  === undefined){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": 'Error!',
                        "message": 'Error retrieving data.',
                        "type" : 'error'
                    });
                    toastEvent.fire();
                }else{
                    cmp.set("v.validEmail", dataWrapper.bValidContactEmail);
                    var courseCode = [];
                    for(var sub in dataWrapper.mapCourseCodes){
                        courseCode.push({key: sub, value: dataWrapper.mapCourseCodes[sub]});
                    }
                    var calendarCode = [];
                    for(var cal in dataWrapper.m_calendarOptions){
                        calendarCode.push({key: cal, value: dataWrapper.m_calendarOptions[cal]});
                    }
                    cmp.set("v.secondaryReasonList",dataWrapper.secondaryReason);
                    cmp.set("v.courseCodeList", courseCode);
                    cmp.set("v.calendarValueList", calendarCode);
                    cmp.set("v.isEsos", Boolean(dataWrapper.bIsESOS));
                    cmp.set("v.personId", dataWrapper.personId);
                }
            }
        });
        $A.enqueueAction(action);
    },

    sendCallout: function(cmp, event, helper) {
        console.log("------ Sending Callout...");
		var endDate;
        if(cmp.get("v.selectedCalendar")){
            endDate = cmp.get("v.selectedCalendar")
        }else{
            endDate = cmp.get("v.endDate");
        }
        let formattedEndDate = helper.formatDate(endDate);
        var formattedStartDate = helper.formatDate(cmp.get("v.startDate"));
        var secondaryReasonFreeText = cmp.get("v.secondaryReasonFreeText");
        var enrolmentException = '';

        if(cmp.get("v.enrolmentExceptions_acadYear") === '' || cmp.get("v.enrolmentExceptions_acadYear") === undefined || cmp.get("v.enrolmentExceptions_acadYear") === null){
            enrolmentException = '';
        }else{
            enrolmentException = cmp.get("v.enrolmentExceptions_acadYear") + '|' + cmp.get("v.enrolmentExceptions_minValue") + '|'+ cmp.get("v.enrolmentExceptions_maxValue");
        }
        // Check if the text is populated if reason is OTHER
        if(cmp.get("v.secondaryReason") === 'Other' &&  (secondaryReasonFreeText === '' || secondaryReasonFreeText === null  || secondaryReasonFreeText === undefined)){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"title": 'Error!', "message": 'Please enter a description',"type" : 'error'});
            toastEvent.fire();
            return;
        }
        
        //Check if the Start date is greated than the End date 
		if(helper.processDates(formattedStartDate) >= helper.processDates(formattedEndDate)){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"title": 'Error!', "message": 'The start date must be before the \'Return Semester\' date',"type" : 'error'});
            toastEvent.fire();
            return;
        }
        
        // Get the Course Code and Description
        let courseCodeList = cmp.get("v.courseCodeList");
        let courseCodeKey;
        let courseCode = cmp.get("v.courseCode");
        courseCodeList.forEach((courseCodeIter) => {
            if(courseCodeIter.value == courseCode){
            	courseCodeKey = courseCodeIter.key;
        	}
        });
        
        if(courseCodeKey === '' || courseCodeKey === null  || courseCodeKey === undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"title": 'Error!', "message": 'Please enter a course',"type" : 'error'});
            toastEvent.fire();
            return;
        }
		
		cmp.set("v.showForm",false);
        cmp.set("v.showSpinner",true);
        
        var action = cmp.get('c.processCourseInformation');
        action.setParams({
            caseId : cmp.get("v.recordId"),
            courseCode : cmp.get("v.courseCode"),
            startDate : formattedStartDate,
            endDate : formattedEndDate,
            enrolmentExceptions : enrolmentException,
            secondaryReason : cmp.get("v.secondaryReason"),
            secondaryReasonFreeText : cmp.get("v.secondaryReasonFreeText"),
    		courseCodeKey : courseCodeKey
        });

        action.setCallback(this, function(response) {
            var ret = response.getReturnValue();
            var state = response.getState();

            var title, message, type;

            if (state === "SUCCESS") {
                if(!ret.includes('processing')){
                    title = 'Error!';
                    type = 'error';
                }else{
                    title = 'Success!';
                    type = 'success';
                }
                message = ret;

                cmp.set("v.showSpinner",false);
                $A.get('e.force:closeQuickAction').fire();
                $A.get('e.force:refreshView').fire();

                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": title,
                    "message": message,
                    "type" : type
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    handleChangeCourse : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },
    handleChangeStartDate : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },
    handleChangeEndDate : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },
    handleChangeSecondaryReason : function (component, event, helper){
        helper.validateForm(component, event, helper);
    }, 
    handleChangeSecondaryReasonFreeText : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },
    handleChangeException : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },
    handleCalendarChangeCourse : function (component, event, helper) {
        helper.validateForm(component, event, helper);
    },
    handleChangeEndDate : function (component, event, helper) {
        helper.validateForm(component, event, helper);
    },
    onChangeEnableDatePicker : function (component, event, helper) {
        if(component.get("v.enableDatePicker")){
            component.set("v.enableDatePicker", false);
        }else{
            component.set("v.enableDatePicker", true);
        }
        component.set("v.endDate", "");
        component.set("v.selectedCalendar", "");
        helper.validateForm(component, event, helper);
    }

});