({
    studentRedirect :  function(component, event, helper){
        window.open(component.get("v.URLSetting").SSO_URL__c,"_parent");   
    },
    init:function(component,event,helper){         
        helper.getUserInfo(component, event, helper);        
    },
    externalRedirect:function(component,event,helper){
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/contact"
        });
        urlEvent.fire();
    },    
    closeModel:function(component,event,helper){
        component.set("v.isOpen",false);
        $('#enquiryButton').show();
    }
})