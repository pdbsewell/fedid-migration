/**
 * Created by angelorivera on 4/8/21.
 */

({
    init: function(cmp) {
        let action = cmp.get('c.updateAssignment');
        action.setParams({
            caseUnitAttemptId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            let ret = response.getReturnValue();
            let state = response.getState();
            let title, message, type;

            if (state === "SUCCESS") {
                if(!ret.includes('Error')){
                    title = 'Success';
                    type = 'success';
                }else{
                    title = 'Error';
                    type = 'error';
                }
                message = ret;
            } else{
                title = 'Error';
                type = 'error';
                message = $A.get("$Label.c.Moodle_Integration_Status_Failed");
            }

            cmp.set("v.showSpinner",false);
            $A.get('e.force:closeQuickAction').fire();
            $A.get('e.force:refreshView').fire();

            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": title,
                "message": message,
                "type" : type
            });
            toastEvent.fire();

        });
        $A.enqueueAction(action);
    }


});