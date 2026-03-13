({
    getSearchPageUrl: function(component, event){
        var homePage = component.get("c.getSearchPageUrl");
        homePage.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.searchPageUrl", response.getReturnValue());
                $("#suggestresults").hide();
            }
        });
        $A.enqueueAction(homePage);
    },
    redirectToArticle: function(component, event){
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
        
    },
    handleblur: function(component, event,helper){
        $("#suggestresults").hide();
    },
    handlefocus: function(component, event){
        var searchKey = event.target.value;
        if(searchKey.length >=3){
            $("#suggestresults").show();
        }  
    },
    handlebutton: function(component, event){
        var searchKey = component.get("v.SearchText");
        if(searchKey.length>=3){
            searchKey = searchKey.replace(/%/g, "");
            searchKey = encodeURIComponent(searchKey);
            console.log('>>>>>>> SearchKey::'+searchKey);
            var redirectUrl = component.get("v.searchPageUrl")+searchKey;
            
            /** NAG 02/0/2017 
                - changed this to navigateToURL so that page won't get rerendered
                  and lose it's state
            **/
            window.open(redirectUrl,'_self')

            /*console.log('redirectUrl',redirectUrl);
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": redirectUrl
            });
            urlEvent.fire();*/
        } else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message": "The search string should be at least three characters long "
            });
            toastEvent.fire();
        }
    },
    searchKeyChange: function(component, event){
        var searchKey = event.target.value;
        var action = component.get("c.getSearchArticles");
        var suggestionlist =[];
        component.set("v.SearchText", searchKey);
        
        if(searchKey.length>=3){
            action.setParams({
                "searchText": searchKey
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                
                console.log('State>>>'+state)
                if (component.isValid() && state === "SUCCESS") {
                    suggestionlist = response.getReturnValue();
                    if(suggestionlist.length>0) {
                        $("#suggestresults").show();
                    }
                    component.set("v.SearchArticleList", suggestionlist);
                }
            });
            $A.enqueueAction(action);
        } else {
            $("#suggestresults").hide();
        }
    }
})