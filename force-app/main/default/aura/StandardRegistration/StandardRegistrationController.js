({
     doInit :function(component, event, helper)
     {
        component.set("v.mainError", "");
         helper.retrieveFacultyData(component);
     },
     
     swithTabs:function(component, event, helper)
     {
           helper.switchTabs(component,event,helper);
     },
     tabSelected: function(component, event, helper)
      {
         var clickedTab = component.find("tabs").get("v.selectedTabId");
      }
})