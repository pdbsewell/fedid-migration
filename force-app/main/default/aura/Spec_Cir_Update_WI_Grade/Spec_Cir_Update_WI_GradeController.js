/**
 * Created by angelorivera on 29/9/20.
 */

({
    doInit: function(cmp) {
        cmp.set("v.showSpinnerForCaseDetails",true);
        console.log("------ Start");
        console.log("------ Case Id: " +  cmp.get("v.recordId"));
        var action = cmp.get('c.retrieveCaseDetails');
        action.setParams({
            caseId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            let caseRecord = response.getReturnValue();
            cmp.set("v.caseRec",caseRecord);

            let caseUnitAttempts = caseRecord.Case_Unit_Attempt__r;
            var state = response.getState();
            console.log("------ response value: " + caseRecord);
            console.log("------ response state: " + state);

            var title, message, type;

            if (state === "SUCCESS") {
                if(caseUnitAttempts === undefined){
                    title = 'Error!';
                    type = 'error';
                    message = $A.get("$Label.c.WIProcessAutomationNoData");

                    cmp.set("v.showSpinnerForCaseDetails",false);
                    $A.get('e.force:closeQuickAction').fire();
                    $A.get('e.force:refreshView').fire();

                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": title,
                        "message": message,
                        "type" : type
                    });
                    toastEvent.fire();
                }else{
                    cmp.set("v.showSpinnerForCaseDetails",false);
                    cmp.set("v.showModalOfDetails",true);
                }
            }
        });
        $A.enqueueAction(action);


    },

    sendCallout: function(cmp) {
        cmp.set("v.showSpinner",true);
        console.log("------ Start");
        console.log("------ Case Id: " +  cmp.get("v.recordId"));
        var action = cmp.get('c.wiProcessAutomation');
        action.setParams({
            caseId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var ret = response.getReturnValue();
            var state = response.getState();
            console.log("------ response value: " + ret);
            console.log("------ response state: " + state);

            var title, message, type;

            if (state === "SUCCESS") {
                if(!ret.includes('success')){
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
    }

});