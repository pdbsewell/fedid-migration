({
    doInit : function(component, event, helper) {
        //Retrieve url id
        helper.retrieveContactDocumentUrlId(component, event, helper);

        //Document specific
        let selectedContactDocumentId = component.get('v.selectedContactDocumentId');
        let selectedDocumentChecklistId = component.get('v.selectedDocumentChecklistId');
        if(selectedContactDocumentId != null){
            //Retrieve document details
            helper.retrieveFileDetails(component, event, helper);
        }else if(selectedDocumentChecklistId != null){
            //Retrieve checklist details
            helper.retrieveChecklistDetails(component, event, helper);
        }

        //Construct splitter listener
        helper.setupSplitListener(component, event, helper);
    },
    splitterFrameLoad : function(component, event, helper) {
        component.set('v.frameReady', true);

        //Ensure frame and initialize is ready before reading the initial file content
        let initializeReady = component.get('v.initializeReady');
        if(initializeReady){
            helper.readFileDetails(component, event, helper);
        }
    },
    handleRequestSplit: function(component, event, helper) {
        component.set('v.requestedPages', event.getParam('requestedPages'));
        //Call visualforce page to split data
        helper.requestSplitting(component, event, helper);
    },
    refreshChecklistDetails: function(component, event, helper) {
        //Retrieve document details
        helper.retrieveNewChecklistList(component, event, helper);
    }
})