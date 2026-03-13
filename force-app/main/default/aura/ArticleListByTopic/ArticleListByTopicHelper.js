({
    redirectToArticle: function(component, event,helper){
        var navEvt;
        var idx = event.target.id;
        navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": idx,
            "slideDevName": "detail"
        });
        navEvt.fire();
        
    },getArticleDetails:function(component,event,helper){
        var topicId=component.get("v.recordId");        
        var action = component.get("c.getArticleByTopic");        
        action.setParams({"topicId":topicId});
        var pageSize;
        var action2 = component.get("c.getPageSize"); 
        action2.setCallback(this, function(a) {
            var result = a.getReturnValue();             
            pageSize=result;
            component.set("v.pageSize",pageSize);
        });
        $A.enqueueAction(action2);
        action.setCallback(this, function(a) {
            var result = a.getReturnValue();   
            if(result!=null)
            {
                component.set("v.ArticleList",result);  
                component.set("v.pageSize",pageSize);  
                var pages=parseInt(result.length/pageSize);
                component.set("v.currentIndexArticle",0);
                component.set("v.currentPageArticle",1);
                component.set("v.lastPageArticle",result.length>pages*pageSize?pages+1:pages);
                component.set("v.totalRecordsArticle",result.length);            
                component.set("v.ArticleList",result);        
                helper.setArticleListVar(component,event,helper);     
                if(result.length==0) {
                    $('#topicAvailable').hide();
                    $('#no-searchresults').show();
                }
                else {
                    $('#topicAvailable').show();
                    $('#no-searchresults').hide();
                }
            }
       });
        
       $A.enqueueAction(action);
       var action2 = component.get("c.getTopicLabelMap");    
        action2.setParams({"topicId":topicId});
        action2.setCallback(this, function(a) {
            var rtnValue = a.getReturnValue();   
            component.set("v.topicLabel",rtnValue);  
            
       });
        $A.enqueueAction(action2); 
        console.log('finished getArticleDetails');
    },
    firstArticle:function(component,event,helper){
        component.set("v.currentIndexArticle",0);  
        component.set("v.currentPageArticle",1);        
        helper.setArticleListVar(component,event,helper);
    },
    nextArticle:function(component,event,helper){
        component.set("v.currentIndexArticle",component.get("v.currentIndexArticle")+component.get("v.pageSize"));  
        component.set("v.currentPageArticle",component.get("v.currentPageArticle")+1);   
        helper.setArticleListVar(component,event,helper);
    },
    previousArticle:function(component,event,helper){
        component.set("v.currentIndexArticle",component.get("v.currentIndexArticle")-component.get("v.pageSize"));  
        component.set("v.currentPageArticle",component.get("v.currentPageArticle")-1); 
        helper.setArticleListVar(component,event,helper);
    },
    lastArticle:function(component,event,helper){
        component.set("v.currentPageArticle",component.get("v.lastPageArticle")); 
        component.set("v.currentIndexArticle",(component.get("v.lastPageArticle")-1)*component.get("v.pageSize"));
        helper.setArticleListVar(component,event,helper);
    },
    setArticleListVar:function(component,event,helper){
		var ArticleListVar=[];
        for(var i=component.get("v.currentIndexArticle");i<component.get("v.currentIndexArticle")+component.get("v.pageSize") && i<component.get("v.ArticleList").length;i++)
        {
            ArticleListVar.push(component.get("v.ArticleList")[i]);
        }        
        component.set("v.ArticleListPaginated",ArticleListVar);
        var hasNextArticle=component.get("v.currentPageArticle")==component.get("v.lastPageArticle")  || component.get("v.pageSize")==0?false:true;
        var hasPreviousArticle=component.get("v.currentPageArticle")==1 || component.get("v.pageSize")==0?false:true;
        var lastIndexArticle=component.get("v.currentIndexArticle")+component.get("v.pageSize")<component.get("v.totalRecordsArticle")?component.get("v.currentIndexArticle")+component.get("v.pageSize"):component.get("v.totalRecordsArticle");
        component.set("v.lastIndexArticle",lastIndexArticle);
        component.set("v.hasNextArticle",hasNextArticle);
        component.set("v.hasPreviousArticle",hasPreviousArticle); 
    }
})