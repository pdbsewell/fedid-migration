({
    init: function(component, event, helper) {
        helper.retrieveContextApplicationId(component, event, helper);
    },

    handleFilePreview : function(component, event) {
        console.log(JSON.stringify(event));
        $A.get('e.lightning:openFiles').fire({
            recordIds: [event.getParam('documentId')]
        });
    }
})