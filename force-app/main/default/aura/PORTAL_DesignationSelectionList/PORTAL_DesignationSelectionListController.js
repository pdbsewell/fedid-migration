({
    doInit : function(component, event, helper) {
        let MessageHandlingService = component.find("MessageHandlingService");
        let findPubliclyVisibleDesignationsAction = component.get("c.SERVER_findPubliclyVisibleDesignations");
        var selectedDesignations = component.get("v.selectedDesignations");
        let portalUserRecommendationParam = component.get("v.portalUserRecommendationParam");
        findPubliclyVisibleDesignationsAction.setParams({"params":{}});
        findPubliclyVisibleDesignationsAction.setCallback(this, function(response) {
            var returnObject = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                let availableDesignations = returnObject.availableDesignations;
                if (availableDesignations != null && availableDesignations.length > 0) {

                    var orderedDesignationList = [];
                    var recommendedDesignationList = [];
                    var recommendTypeToDesignation = {};
                    let recommendType1 = portalUserRecommendationParam.recommendType1;
                    let recommendType2 = portalUserRecommendationParam.recommendType2;
                    let recommendType3 = portalUserRecommendationParam.recommendType3;
                    
                    for (let oneDesignation of availableDesignations) {
                        if (oneDesignation.Recommend_Type_1__c && oneDesignation.Recommend_Type_1__c == recommendType1) {
                            recommendTypeToDesignation.recommendType1 = oneDesignation;
                        }
                        else if (oneDesignation.Recommend_Type_2__c && oneDesignation.Recommend_Type_2__c == recommendType2) {
                            recommendTypeToDesignation.recommendType2 = oneDesignation;
                        }
                        else if (oneDesignation.Recommend_Type_3__c && oneDesignation.Recommend_Type_3__c == recommendType3) {
                            recommendTypeToDesignation.recommendType3 = oneDesignation;
                        }
                        else {
                            orderedDesignationList.push(oneDesignation);
                        }
                    }

                    if (recommendTypeToDesignation.recommendType1) {
                        recommendedDesignationList.push(recommendTypeToDesignation.recommendType1);
                    }
                    if (recommendTypeToDesignation.recommendType2) {
                        recommendedDesignationList.push(recommendTypeToDesignation.recommendType2);
                    }
                    if (recommendTypeToDesignation.recommendType3) {
                        recommendedDesignationList.push(recommendTypeToDesignation.recommendType3);
                    }

                    orderedDesignationList = recommendedDesignationList.concat(orderedDesignationList);

                    component.set("v.availableDesignations", orderedDesignationList);
                }

                var availableDesignationsMapping = {};
                for (let oneDesignation of availableDesignations) {
                    availableDesignationsMapping[oneDesignation.Id] = oneDesignation.Name;
                }

                if (selectedDesignations == null || selectedDesignations.length == 0) {
                    component.set("v.selectedDesignations", [{}]);
                }
                else {
                    for (let oneDesignation of selectedDesignations) {
                        if (availableDesignationsMapping[oneDesignation.Id] == null) {
                            component.set("v.selectedDesignations", [{}]);
                            break;
                        }
                    }
                }
            }
            else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            }
            else if (state === "ERROR") {
                let error = response.getError();
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                    MessageHandlingService.errorServerCall();
                }
            }
        });
        $A.enqueueAction(findPubliclyVisibleDesignationsAction);
    },

    addDesignation : function(component, event, helper) {
        var selectedDesignations = component.get("v.selectedDesignations");

        if (selectedDesignations != null) {
            selectedDesignations.push({});
            component.set("v.selectedDesignations", selectedDesignations);
        }
        else {
            component.set("v.selectedDesignations", [{}]);
        }
    },

    designationListItemEventHandler : function(component, event, helper) {
        let operation = event.getParam("operation");
        let source = event.getParam("source");
        let target = event.getParam("target");
        let index = event.getParam("index");
        let incomingData = event.getParam("data");

        if (target == "designationSelectionList") {
            if (source == "designationSelectionListItem") {
                if (operation == "remove") {
                    var selectedDesignations = component.get("v.selectedDesignations");
                    if (index > -1) {
                        selectedDesignations.splice(index, 1);
                        component.set("v.selectedDesignations", selectedDesignations);
                    }
                }
                else if (operation == "append") {
                    // no action now
                }
                else if (operation == "modify") {
                    var selectedDesignations = component.get("v.selectedDesignations");
                    if (index > -1) {
                        selectedDesignations[index] = JSON.parse(JSON.stringify(incomingData));
                    }
                    component.set("v.selectedDesignations", selectedDesignations);
                }
            }
        }

        // For now, no more propagation is expected, stop it now.
        event.stopPropagation();
    },
    validateDesignationsSelectionInfomationSync : function(component, event, helper) {
        let MessageHandlingService = component.find("MessageHandlingService");
        var selectedDesignations = component.get("v.selectedDesignations");

        if (selectedDesignations == null || selectedDesignations.length == 0) {
            MessageHandlingService.validationError("Please make sure at least one designation is selected.");
            return false;
        }

        var designationIdSet = new Array();

        for (var oneDesignation of selectedDesignations) {

            if ($A.util.isEmpty(oneDesignation.Id)) {
                MessageHandlingService.validationError("Please remove empty designation selection.");
                return false;
            }

            if (designationIdSet.indexOf(oneDesignation.Id) != -1) {
                MessageHandlingService.validationError("Please make sure there are no duplicate designations.");
                return false;
            }
            designationIdSet.push(oneDesignation.Id);
        }

        return true;
    }
})