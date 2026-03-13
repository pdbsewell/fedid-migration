({
    updateEnquiry : function(component, event, helper) {
        helper.updateEnquiry(component, event, helper);
    },
    showEnquiryForm : function(component, event, helper) {
        helper.showEnquiryForm(component, event, helper);
    },
    cancel : function(component, event, helper) {
        helper.hideEnquiryForm(component, event, helper);
    },
    closeEnquiry : function(component, event, helper) {
        component.set('v.enquiryClosed',true);
        helper.updateEnquiry(component, event, helper);
    },
    init:function(component,event,helper){
        var caseId=component.get("v.recordId");     
        if(caseId.indexOf('500')===0) {
            var checkStatusLoaded = setInterval(function(){
                var statusTexts = $("#enquiryButton").parents(".mainContentArea").find(".slds-form-element_edit .slds-form-element__label");
                if(statusTexts.length > 0){
                    clearInterval(checkStatusLoaded);
                    for(var i=0, iLen = statusTexts.length; i < iLen; i++){
                        if($(statusTexts[i]).text() === "Status" || $(statusTexts[i]).text() === "Enquiry Origin" || $(statusTexts[i]).text() === "Subject"){
                            $(statusTexts[i]).parent().parent().parent().hide();
                        }
                    }
                }
                else{
                    
                }            
            }, 100);        
            var checkStatusLoaded1 = setInterval(function(){
                var statusTexts = $("#enquiryButton").parents(".mainContentArea").find(".slds-page-header__detail-block .slds-text-heading--label-normal");
                if(statusTexts.length > 0){
                    clearInterval(checkStatusLoaded1);
                    for(var i=0, iLen = statusTexts.length; i < iLen; i++){
                        
                        
                        if( $(statusTexts[i]).text() === "Status" || $(statusTexts[i]).text() === "Enquiry Number"){
                            $(statusTexts[i]).parent().hide();
                        }
                    }
                }
                else{
                    
                }            
            }, 100);
            var checkStatusLoaded2 = setInterval(function(){
                var statusTexts =$("#enquiryButton").parents(".mainContentArea").find(".actionsContainer .forceActionsContainer .slds-button");
                if(statusTexts.length > 0){
                    clearInterval(checkStatusLoaded2);
                    for(var i=0, iLen = statusTexts.length; i < iLen; i++){
                        var token = $(statusTexts[i]).text();
                        token = token.replace(/[^a-zA-Z0-9-=]/g, "");
                        if( token == "Follow"){
                            $(statusTexts[i]).parent().parent().hide();
                        }
                    }
                }
                else{
                    
                }            
            }, 100);
            helper.getCaseStatus(component,event,helper);
        }
        if(caseId.indexOf('02s')===0) {
            var checkStatusLoaded = setInterval(function(){
                var statusTexts = $("#enquiryButton").parents(".mainContentArea").find(".slds-form-element_edit .slds-form-element__label");
                if(statusTexts.length > 0){
                    clearInterval(checkStatusLoaded);
                    for(var i=0, iLen = statusTexts.length; i < iLen; i++){
                        if($(statusTexts[i]).text() === "HTML Body"){
                            $(statusTexts[i]).hide();
                        }
                    }
                }
                else{
                    
                }            
            }, 100);
            var checkStatusLoaded1 = setInterval(function(){
                var statusTexts = $("#enquiryButton").parents(".mainContentArea").find(".section-header-title");
                if(statusTexts.length > 0){
                    clearInterval(checkStatusLoaded1);
                    for(var i=0, iLen = statusTexts.length; i < iLen; i++){
                        if($(statusTexts[i]).text() === "Message Content" || $(statusTexts[i]).text() === "Information"){
                            $(statusTexts[i]).text("Message");
                        }
                    }
                }
                else{
                    
                }            
            }, 100);
        }
        if(caseId.indexOf('500')!=0) {
            $('#enquiryButton').hide();
        }
    },
    refreshCase:function(component,event,helper){
        helper.hideEnquiryForm(component, event, helper);
        window.location.reload();
    }   		
})