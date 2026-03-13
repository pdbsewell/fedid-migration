/**
 * Created by trentdelaney on 4/9/18.
 */
({
    doInit : function (component, event, helper){
        helper.hasDrafts(component);
    },

    newApplication : function(component, event, helper){
        var firstPage = component.get("v.firstPage");
        helper.createApplication(component, firstPage);
    },

    editApplication : function(component, event, helper){
        helper.editMyApplication(component);
    },

    removeApplication : function (component, event, helper) {
        helper.deleteApplication(component);
    }
})