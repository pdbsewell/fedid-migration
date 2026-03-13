({
    doInit : function(component, event, helper) {
        // Gift and Pledge must pre-defined deisgnations before step 2
        let selectedDesignations = component.get("v.selectedDesignations");
        var designationDetailRecList = component.get("v.designationDetailRecList");

        if (selectedDesignations != null && selectedDesignations.length > 0) {
            var designationDetailListArray = new Array();

            for (var oneDesignation of selectedDesignations) {
                designationDetailListArray.push({
                    'Id': null,
                    'ucinn_ascendv2__Designation__c': oneDesignation.Id,
                    'ucinn_ascendv2__Amount__c': '',
                    'ucinn_ascendv2__Payment_Frequency__c': '',
                    'ucinn_ascendv2__Number_of_Payments__c': '',
                    'ucinn_ascendv2__Contact__c': '',
                    'ucinn_ascendv2__Has_Tax_Receipt__c': '',
                    'ucinn_ascendv2__G_L_Account__c': '',
                    'ucinn_ascendv2__Campaign__c': '',
                    'ucinn_ascendv2__Non_Gift_Amount__c': '',
                    'ucinn_ascendv2__Designation__r': oneDesignation
                });
            }

            // A map that hold designation id to designation amount
            // Mainly use for recover user pre-defined amount for matching designation during page navigation
            var designationDetailMap = new Map();

            if (designationDetailRecList != undefined && designationDetailRecList != null && designationDetailRecList.length > 0) {
                for (var oneDesignationDetail of designationDetailRecList) {

                    var definedDesignation = oneDesignationDetail.ucinn_ascendv2__Designation__c;
                    if (definedDesignation != undefined && definedDesignation != null && definedDesignation != '') {
                        designationDetailMap.set(definedDesignation, {"Amount":oneDesignationDetail.ucinn_ascendv2__Amount__c, "NumberOfPayments":oneDesignationDetail.ucinn_ascendv2__Number_of_Payments__c});
                    }
                }

                for (var oneDesignationDetailInArray of designationDetailListArray) {
                    if (designationDetailMap.has(oneDesignationDetailInArray.ucinn_ascendv2__Designation__c)) {
                        var designationDetailInfo = designationDetailMap.get(oneDesignationDetailInArray.ucinn_ascendv2__Designation__c);
                        oneDesignationDetailInArray.ucinn_ascendv2__Amount__c = designationDetailInfo.Amount;
                        oneDesignationDetailInArray.ucinn_ascendv2__Number_of_Payments__c = designationDetailInfo.NumberOfPayments;
                    }
                }
            }

            component.set("v.designationDetailRecList", designationDetailListArray);
            return;
        }
        else {
            let MessageHandlingService = component.find("MessageHandlingService");
            MessageHandlingService.validationError("Please make sure at least one designation is selected on previous page.");

            return;
        }
    }
})