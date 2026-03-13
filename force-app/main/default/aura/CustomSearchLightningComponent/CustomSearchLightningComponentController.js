({
    init : function(component, event, helper) {
       helper.getSearchPageUrl(component, event);  
    },
    searchKeyChange: function(component, event, helper) {
        helper.searchKeyChange(component, event);
    },
    redirectToArticle: function(component, event,helper){
        helper.redirectToArticle(component, event);
    },
    handleblur: function(component, event,helper){;
        helper.handleblur(component, event,helper);
    },
    handlefocus: function(component, event,helper){
        helper.handlefocus(component, event);
    },
    handlebutton: function(component, event,helper){
        helper.handlebutton(component, event);
    },
    handleEnterEvent: function(component, event,helper){
        if(event.which==13) {
           helper.handlebutton(component, event); 
        }
    }
})