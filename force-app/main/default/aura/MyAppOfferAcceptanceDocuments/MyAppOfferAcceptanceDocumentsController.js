({
    init: function(component, event, helper) {
        helper.retrieveContextOfferId(component, event, helper);
    },

    handleFilePreview : function(component, event) {
        $A.get('e.lightning:openFiles').fire({
            recordIds: [event.getParam('documentId')]
        });
    }
})