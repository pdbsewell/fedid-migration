({
    getTopTenFAQ: function(component) {
        var action = component.get("c.getTopTenArticles");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.topTenArticleList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },  
    redirectToArticle: function(component, event){
        var toptenRec;
        var navEvt;
        var idx = event.target.id;
        console.log('EventFired>>>');
        navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": idx,
            "slideDevName": "detail"
        });
        console.log('articleId>>>'+idx);
        navEvt.fire();
        
    }
    
})