({
    switchTabs:function(component,event, helper)
    {
          var goTo = event.getParam("goTo");
           component.find("tabs").set("v.selectedTabId",goTo);
    }
})