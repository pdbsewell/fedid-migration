({
    gettopics:function(component,event,helper) {
        var articleId=component.get("v.recordId");
        console.log('>>>>>articleId'+articleId);        
        var action = component.get("c.getTopics");
        var result = [];        
        action.setParams({"ArticleId": articleId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('>>> State ::'+state);
            if (component.isValid() && state === "SUCCESS") {
                result = response.getReturnValue(); 
                if(result.length>0) {
                    component.set("v.TopicList",result);
                    $("#topic-links").show();
                } else {
                    component.set("v.TopicList",result);
                    $("#topic-links").hide();
                }
            }  
        });
        $A.enqueueAction(action);
    },
    redirectToTopic: function(component,event,helper) {
        var navEvt;
        var idx = event.target.id;
        navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": idx,
            "slideDevName": "detail"
        });
        navEvt.fire();
    }
})