({
    initPersonalDetails: function (component) {
        var action = component.get("c.retrieveLocationOptions");
        var items = [];
        console.log('initPersonalDetails:');
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var pickitems = response.getReturnValue();
                for (var i = 0; i < pickitems.length; i++) {
                    items.push({
                        label: pickitems[i],
                        value: pickitems[i]
                    });
                    //console.log('initPersonalDetails: Success', JSON.stringify(items));
                    component.set("v.options", items);
                }
            }
        });
        $A.enqueueAction(action);
    },
    handlePhoneNumberChange: function (component, event, helper) {
        component.get('v.newCase').TemporaryPhone = component.get('v.newCase.TemporaryPhone');
    },
    handleChangeCurrentLocation: function (component, event, helper) {
        var selectedOptionValue = event.getParam("value");
        if (selectedOptionValue !== null) {
            component.get('v.newCase').TemporaryCurrentLocation = selectedOptionValue;
        }
    }
})