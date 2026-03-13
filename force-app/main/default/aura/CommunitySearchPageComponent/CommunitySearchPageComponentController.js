({
    redirectToArticle: function(component, event,helper){
        helper.redirectToArticle(component, event);
    },
    init: function(component, event, helper){
        helper.getSuggestions(component, event,helper);
    },
    previousArticle : function(component, event,helper){
        helper.previousArticle(component, event,helper);
    },
    nextArticle : function(component, event,helper){
        helper.nextArticle(component, event,helper);
    }
})