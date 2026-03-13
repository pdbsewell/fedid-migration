({
    getArticleDetail : function(component, event, helper) {
        var articleId=component.get("v.recordId");
        console.log('>>>>>articleId'+articleId);        
        var action = component.get("c.getArticleDetail");       
        action.setParams({"ArticleId": articleId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('>>> State ::'+state);
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.ArticleDetail",response.getReturnValue());
            }  
        });
        $A.enqueueAction(action);
    }
})