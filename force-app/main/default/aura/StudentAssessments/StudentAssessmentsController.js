/**
 * Created by angelorivera on 6/10/21.
 */

({
    init: function (component, event, helper) {
        component.set('v.assessmentColumns', [
            { label: 'Assessment Id', fieldName: 'id', type: 'text', sortable : true  },
            { label: 'Unit Offering Id', fieldName: 'unitOfferingId', type: 'text', sortable : true },
            { label: 'Type', fieldName: 'type', type: 'text', wrapText: true, sortable : true },
            { label: 'Name', fieldName: 'name', type: 'text', wrapText: true, sortable : true},
            { label: 'Due Date', fieldName: 'dueDate', type: 'text', sortable : true}
        ]);

        let action = component.get('c.retrieveAssessments');

        action.setParams({
            'caseUnitAttemptId': component.get('v.recordId')
        });

        action.setCallback(this, function (response) {
            let state = response.getState();
            let studAssessments = [];
            console.log('state: ' + state);
            console.log('response.getReturnValue: ' + JSON.stringify(response.getReturnValue()) );

            if (state === 'SUCCESS') {
                studAssessments = response.getReturnValue();
                component.set('v.studentAssessments', studAssessments);

                if(studAssessments.length < 1){
                    $A.get('e.force:closeQuickAction').fire();
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "duration": 6000,
                        "title": "Information",
                        "message": $A.get("$Label.c.Moodle_Integration_No_Assessment"),
                        "type" : "warning"
                    });
                    toastEvent.fire();
                }
            } else{
                $A.get('e.force:closeQuickAction').fire();
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "duration": 6000,
                    "title": "Error",
                    "message": "Error retrieving student Assessments from Moodle",
                    "type" : "error"
                });
                toastEvent.fire();
            }
            console.log('studAssessments:', studAssessments);
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },

    handleSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortData(component,sortBy,sortDirection);
    },

    recordUpdated: function (component, event, helper) {
        let changeType = event.getParams().changeType;

        if (changeType === 'CHANGED') {
            component.set('v.studentAssessments', []);
            let init = component.get('c.init');
            $A.enqueueAction(init);
        }
    },

    closeModal: function (component, event, helper) {
        component.set('v.isOpenCasesModalOpen', false);
        $A.get('e.force:closeQuickAction').fire();
    }
});