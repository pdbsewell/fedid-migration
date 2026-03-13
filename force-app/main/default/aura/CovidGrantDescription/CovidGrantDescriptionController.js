({
    handleCheckboxChange: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryConsentCenterLink = ischecked;
    },
    handleCheckboxChangePreviousApplication: function (component, event, helper) {
        /* var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryPreviousApplication = ischecked;         */
        var selectedOptionValue = event.getParam("value");
        if (selectedOptionValue !== null) {
            console.log('TemporaryPreviousApplication', selectedOptionValue);
            component.get('v.newCase').TemporaryPreviousApplication = selectedOptionValue;
        }
    },
    handleAmountChange: function (component, event, helper) {
        component.get("v.newCase").TemporaryAmountNeeded = component.get('v.newCase.TemporaryAmountNeeded');        
    },
    handleDescriptionChange: function (component, event, helper) {
        component.get("v.newCase").TemporaryDescription = component.get('v.newCase.TemporaryDescription');        
    },
    handleExpenseOutlineChange: function (component, event, helper) {
        component.get("v.newCase").TemporaryExpenseOutline = component.get('v.newCase.TemporaryExpenseOutline');        
    }

})