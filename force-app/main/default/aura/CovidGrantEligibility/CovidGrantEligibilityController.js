/**
 * Created by angelorivera on 31/8/20.
 */

({
    handleEligibilityItem1: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryEligibilityItem1 = ischecked;
    },
    handleEligibilityItem2: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryEligibilityItem2 = ischecked;
    },
    handleEligibilityItem3: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryEligibilityItem3 = ischecked;
    },
    handleEligibilityItem4: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryEligibilityItem4 = ischecked;
    }
});