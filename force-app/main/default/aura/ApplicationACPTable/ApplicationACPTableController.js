/**
 * Created by trentdelaney on 4/9/18.
 */
({
    doInit : function (component, event, helper) {
        var editable = component.get("v.editable")
        helper.getApplicationsWithAcps(component, editable);
    },

    editApplication : function(component, event, helper){
        helper.editMyApplication(component);
    },
    
    removeApplication : function (component, event, helper) {
        helper.deleteApplication(component);
    },

    viewApplication : function (component, event, helper) {
        var appId = event.getSource().get("v.value");
        helper.viewMyApplication(component, '/applicationreview', appId, 'documentsListDiv');
    },

    display : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },

    displayOut : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },
    
    closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isModalOpen" attribute to "Fasle"  
      component.set("v.isModalOpen", false);
   },
    
    openModel: function(component, event, helper) {
      // for Display Model,set the "isModalOpen" attribute to "true"
      component.set("v.isModalOpen", true);
   },
})