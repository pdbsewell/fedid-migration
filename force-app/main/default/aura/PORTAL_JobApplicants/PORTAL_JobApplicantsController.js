({
    doInit : function(component, event, helper) {

        let jobRecId = component.get("v.jobRecId");

        var queryJobApplicants = component.get('c.SERVER_queryJobApplicants');

        queryJobApplicants.setParams({
            jobRecId: jobRecId
        });

        queryJobApplicants.setCallback(this, function(response) {

            var state = response.getState();

            console.log( (JSON.parse(JSON.stringify(response.getReturnValue()))) );

            if (state === "SUCCESS") {
                component.set('v.jobApplicantList', response.getReturnValue());
            }
            else {
                alert('Error in getting data');
            }
        });

        $A.enqueueAction(queryJobApplicants);
    }
})