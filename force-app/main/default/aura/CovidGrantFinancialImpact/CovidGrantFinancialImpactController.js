({
    handleImpactLossOfIncomeChange: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryImpactLossOfIncome = ischecked;        
    },
    handleImpactTechnologyChange: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryImpactTechnology = ischecked;        
    },
    handleImpactAccomodationChange: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryImpactAccomodation = ischecked;        
    },
    handleImpactTravelChange: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryImpactTravel = ischecked;        
    },
    handleImpactFoodIncidentalsChange: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryImpactFoodIncidentals = ischecked;        
    }
})