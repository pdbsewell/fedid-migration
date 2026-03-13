({
	doBrowserCheck : function(component, event, helper) {
		var isNotChrome = true;

		if(navigator.userAgent.indexOf("Firefox") != -1 ) 
        {
             component.set("v.notChrome", isNotChrome);
        }
        else if((navigator.userAgent.indexOf("MSIE") != -1 ) || (!!document.documentMode == true )) //IF IE > 10
        {
          component.set("v.notChrome", isNotChrome);
        }  
        else 
        {
           isNotChrome = false;
        }
	}
})