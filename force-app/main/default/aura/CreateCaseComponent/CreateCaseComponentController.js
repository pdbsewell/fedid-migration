({
    init : function(component, event, helper) {
        helper.getUserFirstName(component);
        helper.populatePicklist(component, event);
        helper.getUserType(component);
        component.set("v.isButtonClicked",false);
    },
    handleCheckbox : function(component, event, helper) {
        helper.handleCheckbox(component, event);
    },
    save : function (component, event, helper) {
        if(component.get("v.isButtonClicked")!=true) {
            component.set("v.isButtonClicked",true);
        	helper.Save(component,event,helper); 
        }
    },
    getSuggestions : function (component, event, helper) {
        //helper.getSuggestions(component,event);
    },
    redirectToArticle : function(component, event, helper) {
        helper.redirectToArticle(component,event);
    },
    closeModel: function(component, event, helper) {
        $A.util.addClass(component.find("artical-modal").getElement(), "slds-hide");
    },
    captureupload : function(component, event, helper) {
        
        console.log('captureLoad>>');
        var fileInput = component.find("file").getElement();
        var file = fileInput.files;
        var fileNames = [];
        
        if(file.length==0) {
            $("#selectedFiles").hide();
            component.set("v.selectedFiles",fileNames);
            return;
        }
        
        if(file.length > 5){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "You can select only 5 files"
            });
            toastEvent.fire();
            return; 
        } 
        
        for(var i=0;i<file.length;i++) {
            fileNames.push(file[i].name);
        }
        
        if(fileNames.length>0){
            $("#selectedFiles").show();
            component.set("v.selectedFiles",fileNames);
        } 
        component.set("v.isButtonClicked",false);
    },
    redirectPrivacyStatement: function(component, event, helper) {
        helper.redirectPrivacyStatement(component,event);
    }
})