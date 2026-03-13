({
    doInit : function(component, event, helper) {
        helper.getTopTenFAQ(component);
    },
    redirectToArticle : function(component, event, helper) {
        helper.redirectToArticle(component, event);
    }
    
})