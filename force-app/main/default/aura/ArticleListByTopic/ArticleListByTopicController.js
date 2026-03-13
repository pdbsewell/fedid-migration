({
	firstArticle:function(component,event,helper){
       helper.firstArticle(component, event, helper);        
    },
    nextArticle:function(component,event,helper){
       helper.nextArticle(component, event, helper);        
    },
    previousArticle:function(component,event,helper){
       helper.previousArticle(component, event, helper);        
    },
    lastArticle:function(component,event,helper){
       helper.lastArticle(component, event, helper);        
    },
    init: function(component,event,helper) {
        helper.getArticleDetails(component, event, helper);      
    },
    redirectToArticle: function(component, event,helper){
        helper.redirectToArticle(component, event,helper);
    }
})