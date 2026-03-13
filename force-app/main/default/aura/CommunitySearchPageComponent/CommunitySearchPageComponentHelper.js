({
    redirectToArticle: function(component, event){
        var navEvt;
        var idx = event.target.id;
        console.log('EventFired>>>'+idx);
        navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": idx,
            "slideDevName": "detail"
        });
        console.log('articleId>>>'+idx);
        navEvt.fire();
        
    },
    getSuggestions: function(component,event,helper){
        var urlParameters = [];
        urlParameters = document.URL.split('/');
        //var searchToken = urlParameters[urlParameters.length-1];
        //var searchToken = document.URL.lastIndexOf('Token?=')+1,str.lastIndexOf('#end');
        var searchToken = urlParameters[urlParameters.length-1].replace(/%20/g, " ");
        
        component.set("v.SearchLabel", unescape(searchToken));
        
        searchToken = searchToken.replace(/[^a-zA-Z0-9-=$]/g, " ");
        console.log('searchToken Function :: '+searchToken);       
        
        var pSizeAction = component.get("c.getPageSize");
        pSizeAction.setCallback(this,function(response){
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.PageSize", response.getReturnValue()); 
            }                    
        });
        $A.enqueueAction(pSizeAction);
        
        var searchTextAction = component.get("c.getSearchToken");
        searchTextAction.setParams({"searchText": searchToken});
        searchTextAction.setCallback(this,function(response){
            if (component.isValid() && response.getState() === "SUCCESS") {
                //component.set("v.SearchLabel", response.getReturnValue());
            }                    
        });
        $A.enqueueAction(searchTextAction);
        
        
        var action = component.get("c.getSearchResults");
        action.setParams({"searchText": searchToken});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('>>>>>>State'+state);
            if (component.isValid() && state === "SUCCESS") {
                var searchresults = response.getReturnValue();
                if(searchresults.length>0) {
                    component.set("v.SearchArticleList", searchresults);
                    component.set("v.CurrentArticle", 0);
                    component.set("v.TotalResultSize", searchresults.length);
                    component.set("v.LastArticle", component.get("v.CurrentArticle")+component.get("v.PageSize"));
                    helper.CurrentArticleList(component,event);
                } else {
                    $("#search-results").hide();
                    $("#no-searchresults").show();
                }
                
                component.set('v.showArticleSearchLoadingSpinner', false);
            } 
        }
        );
        $A.enqueueAction(action);
        $A.util.removeClass(component.find("search-header"), 'slds-hide');
        $A.util.removeClass(component.find("search-count"), 'slds-hide');
        $A.util.removeClass(component.find("search-pagination"), 'slds-hide');
        
    },
    CurrentArticleList: function(component,event){
        var totalResultSize = component.get("v.SearchArticleList").length;
        console.log('>>>>totalResultSize'+totalResultSize);
        var CurrentArticleList = [];
        for(var i=component.get("v.CurrentArticle");i<component.get("v.CurrentArticle")+component.get("v.PageSize") && i<totalResultSize;i++) {
            CurrentArticleList.push(component.get("v.SearchArticleList")[i]);
        }
        var hasNextArticle =  component.get("v.CurrentArticle")+component.get("v.PageSize")<totalResultSize?true:false;
        var hasPreviousArticle = component.get("v.CurrentArticle")==0?false:true;
        console.log('>>>hasNext'+hasNextArticle+'hasPrev'+hasPreviousArticle);
        component.set("v.CurrentArticleList", CurrentArticleList);
        component.set("v.hasNextArticle",hasNextArticle);
       	component.set("v.hasPreviousArticle", hasPreviousArticle);
        var LastArticle = component.get("v.CurrentArticle")+component.get("v.PageSize")>component.get("v.TotalResultSize")?component.get("v.TotalResultSize"):component.get("v.CurrentArticle")+component.get("v.PageSize");
        component.set("v.LastArticle", LastArticle);
    },
    previousArticle: function(component,event,helper){
        console.log('>>>Previous Article');
        component.set("v.CurrentArticle", component.get("v.CurrentArticle")-component.get("v.PageSize"));
        helper.CurrentArticleList(component,event);
    },
    nextArticle: function(component,event,helper){
        console.log('>>>next Article');
        component.set("v.CurrentArticle", component.get("v.CurrentArticle")+component.get("v.PageSize"));
        helper.CurrentArticleList(component,event);
    } 
    
})