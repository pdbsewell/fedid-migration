({
    retrieveStudentDetails : function(component, event, helper) {
        component.set('v.showSpinner', true);

        if(component.get('v.currentEnquiry').Contact){
            //Initialize Action
            var action = component.get('c.retrieveStudentInformation');

            //Set Id of Application
            action.setParams({  strContactId : component.get('v.currentEnquiry').ContactId,
                CaseId : component.get('v.recordId') });

            // Create a callback that is executed after
            // the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var wrapperClass = response.getReturnValue();
                    var courseAttempts = wrapperClass.lstCourseAttempts;
                    var applications = wrapperClass.lstApplications;
                    var unitAttempts = wrapperClass.lstUnitAttempts;

                    //Assign result objects to attributes
                    component.set('v.studentCourseAttempts', courseAttempts);
                    component.set('v.studentApplications', applications);
                    component.set('v.studentUnitAttempts', unitAttempts);

                    //Set no course attempts found
                    component.set('v.hasNoCourseAttempts', false);
                    if(courseAttempts.length == 0){
                        component.set('v.hasNoCourseAttempts', true);
                    }
                    //Set no appications found
                    component.set('v.hasNoApplications', false);
                    if(applications.length == 0){
                        component.set('v.hasNoApplications', true);
                    }
                    //Set no unit enrolment found
                    component.set('v.hasNoUnitAttempts', false);
                    if(unitAttempts.length == 0){
                        component.set('v.hasNoUnitAttempts', true);
                    }
                }
                else if (state === 'INCOMPLETE') {
                    console.log('Incomplete: ' + JSON.stringify(response));
                }
                else if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log('Error message: ' +
                                errors[0].message);
                        }
                    } else {
                        console.log('Unknown error');
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },

    linkCourseOnCaseData : function(component, event, helper) {
        component.set('{!v.showSpinner}', true);
        //Initialize Action
        var action = component.get('c.linkCourse');
        var selectedItem = event.currentTarget;

        //Set Id of Application
        action.setParams({
            enquiryId : component.get('v.recordId'),
            courseId : selectedItem.dataset.courseid,
            courseCode : selectedItem.dataset.coursecode,
            courseAttemptId : selectedItem.dataset.courseattemptid,
            courseAttemptStatus : selectedItem.dataset.courseattemptstat
        });

        console.log('courseId : ' + selectedItem.dataset.courseid);
        console.log('courseCode : ' + selectedItem.dataset.coursecode);
        console.log('courseAttemptId : ' + selectedItem.dataset.courseattemptid);
        console.log('courseAttemptStatus : ' + selectedItem.dataset.courseattemptstat);
        // Create a callback that is executed after
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                //Show success toast
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'type': 'success',
                    'title': 'Success!',
                    'message': 'Successfully linked course attempt with course ' + selectedItem.dataset.coursecode + ' to the enquiry.'
                });
                toastEvent.fire();

                //Get course code
                component.set('v.linkedCourse', selectedItem.dataset.coursecode);

                //Refresh standard components on page
                $A.get('e.force:refreshView').fire();
            }
            else if (state === 'INCOMPLETE') {
                console.log('Incomplete: ' + JSON.stringify(response));
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' +
                            errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
            component.set('{!v.showSpinner}', false);
        });

        $A.enqueueAction(action);
    },
    unlinkCourseOnCaseData : function(component, event, helper) {
        component.set('{!v.showSpinner}', true);
        //Initialize Action
        var action = component.get('c.unlinkCourse');
        var selectedItem = event.currentTarget;

        //Set Id of Application
        action.setParams({ enquiryId : component.get('v.recordId') });

        // Create a callback that is executed after
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                //Show success toast
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'type': 'success',
                    'title': 'Success!',
                    'message': 'Successfully unlinked course attempt with course ' + selectedItem.dataset.coursecode + ' from the enquiry.'
                });
                toastEvent.fire();

                //Get course code
                component.set('v.linkedCourse', '');

                //Refresh standard components on page
                $A.get('e.force:refreshView').fire();
            }
            else if (state === 'INCOMPLETE') {
                console.log('Incomplete: ' + JSON.stringify(response));
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' +
                            errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
            component.set('{!v.showSpinner}', false);
        });

        $A.enqueueAction(action);
    },
    navigateToCourseData : function(component, event, helper) {
        // var action = component.get('c.goToCourse');
        var selectedItem = event.currentTarget;

        console.log('courseId : ' + selectedItem.dataset.courseid);
        console.log('courseCode : ' + selectedItem.dataset.coursecode);
        console.log('courseAttemptId : ' + selectedItem.dataset.courseattemptid);
        console.log('acpId : ' + selectedItem.dataset.acpid);

        var recId = '';
        if(selectedItem.dataset.courseattemptid !== undefined){
            recId = selectedItem.dataset.courseattemptid;
        }else{
            recId = selectedItem.dataset.acpid;
        }

        //Navigate to the newly created object
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId,
            "slideDevName": "related"
        });
        navEvt.fire();
    }
})