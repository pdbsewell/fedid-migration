({
    doInit : function(component, event, helper) {
        helper.initializeNewPledge(component, event, helper);
    },
    designationDetailListItemEventHandler : function(component, event, helper) {
        let operation = event.getParam("operation");
        let source = event.getParam("source");
        let target = event.getParam("target");
        let index = event.getParam("index");
        let incomingData = event.getParam("data");

        if (target == "designationDetailList") {
            if (source == "designationDetailListItem") {
                if (operation == "remove") {
                    // no action now
                }
                else if (operation == "append") {
                    // no action now
                }
                else if (operation == "modify") {
                    // just re-calculate the sum of amount for now
                    let designationDetailRecList = component.get("v.designationDetailRecList");
                    var totalAmount = 0;
                    for (let designationDetailRec of designationDetailRecList) {
                        if (designationDetailRec.ucinn_ascendv2__Amount__c && designationDetailRec.ucinn_ascendv2__Amount__c > 0) {
                            totalAmount += designationDetailRec.ucinn_ascendv2__Amount__c;
                        }
                    }
                    component.set("v.pledgeRec.Amount", totalAmount);
                }
            }
        }

        // For now, no more propagation is expected, stop it now.
        event.stopPropagation();
    },
    previewInstallment : function(component, event, helper) {
        helper.calculateInstallments(component, event, helper);
        component.set("v.previewInstallment", true);
    },
    closePreviewInstallment : function(component, event, helper) {
        component.set("v.previewInstallment", false);
    },

    validatePledgeInfomationAsync : function(component, event, helper) {
        var params = event.getParam('arguments');
        var callback;
        if (params) {
            callback = params.callback;
        }

        var otherValidationsAndCallback = function() {
            var designationDetailRecList = component.get("v.designationDetailRecList");
            var tributeRecList = component.get("v.tributeRecList");
            var validated = true;

            validated = validated && helper.checkDesignationDetails(component, designationDetailRecList, helper);
            validated = validated && helper.checkTributeDetails(component, tributeRecList, helper);

            callback(validated);
        };

        helper.calculateInstallmentsWithCallback(component, event, helper, otherValidationsAndCallback);
    }
})