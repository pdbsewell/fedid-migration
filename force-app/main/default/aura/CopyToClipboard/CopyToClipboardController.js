({
    init: function (component, event, helper) {
        let action = component.get("c.getRecordDetails");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            
            if (state === "SUCCESS") {
                let returnValue = JSON.parse(response.getReturnValue());
                
                let unit = returnValue.Unit_Code__c;
                if(returnValue.Unit_Attempt__c !== undefined) {
                    unit = returnValue.Unit_Attempt__r.Title__c + " (" + returnValue.Unit_Attempt__r.Unit_Code__c + ")";
                }
                
                let data = "Unit: " + unit;
                data += "\n" + "Assessment Name: " + returnValue.Assessment_Name__c;
                data += "\n" + "Assessment Type: " + returnValue.Assessment_Type__c;
                data += "\n" + "Assessment Due Date (Original): " + helper.formatDate(returnValue.Assessment_Due_Date_Original__c);
                if(returnValue.Assessment_Due_Date_Effective__c !== undefined) {
                    data += "\n" + "Assessment Due Date (Current): " + helper.formatDate(returnValue.Assessment_Due_Date_Effective__c);
                }
                if(returnValue.Assessment_Due_Date_New__c !== undefined) {
                    data += "\n" + "Assessment Due Date (New): " + helper.formatDate(returnValue.Assessment_Due_Date_New__c);
                }
                
                var copyTextInput = document.getElementById("copyTextInput");
                copyTextInput.value = data;
                copyTextInput.select();
                copyTextInput.setSelectionRange(0, 99999);
                document.execCommand("copy");
                copyTextInput.value = "";
                
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "The requested data has been copied to your clipboard.",
                    "type": "success"
                });
                toastEvent.fire();
                
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "ERROR") {
                let errors = response.getError();
                
                console.log(errors);
            } else {
                console.log(state);
            }
        });
        $A.enqueueAction(action);
    }
})