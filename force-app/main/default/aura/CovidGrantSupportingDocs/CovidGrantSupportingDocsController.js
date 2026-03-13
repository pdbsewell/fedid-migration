({
    handleUploadDocChange : function(component, event, helper) {
        if(!component.get('v.newCase').selectedFiles){
            component.get('v.newCase').selectedFiles = [];
        }
        component.get('v.newCase').selectedFiles = component.get('v.newCase.selectedFiles');
    }
})