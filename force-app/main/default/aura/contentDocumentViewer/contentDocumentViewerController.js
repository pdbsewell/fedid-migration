({
    doInit : function(component, event, helper) {
        //Retrieve url id
        helper.retrieveContactDocumentUrlId(component, event, helper);
        //Retrieve document details
        helper.retrieveFileDetails(component, event, helper);
    }
})