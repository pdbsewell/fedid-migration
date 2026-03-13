({
     updateLastTabSaved:function(component,event,helper)
          {
                component.set("v.ValidationMsg","");
                var tabsaved = event.getParam("savedTab");
                component.set("v.lastSavedTab",tabsaved);
                console.log(' StdReqCQController ???************ updateLastTabSaved ***************'+tabsaved+'**'+event.getParam("regtype"));
                component.set("v.ValidationMsg","");
                component.set("v.ACPId",event.getParam("ACPId"));
                component.set("v.bookingId",event.getParam("bookingId"));
                component.set("v.FSLink",event.getParam("FSLink"));
                component.set("v.ccode",event.getParam("ccode"));
                component.set("v.regtype",event.getParam("regtype"));
                console.log('code=='+event.getParam("ccode"));
                var urlfs= component.get("v.FSLink")+"?regtype="+component.get("v.regtype")+"&ACPId="+component.get("v.ACPId")+"&bookingId="+component.get("v.bookingId")+"&ccode="+component.get("v.ccode");
                component.set("v.framesrc",urlfs);
         },
          doInit:function(component,event,helper)
          {
              if(component.get("v.lastSavedTab")!='tab2')
                  component.set("v.ValidationMsg","You cannot navigate to this tab without saving the previous one.");
          }
})