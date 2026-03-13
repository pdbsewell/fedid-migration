({	
	helperFocusedTab : function(component, event, helper) {
        var rec = component.get("v.recordId");
        if(rec != undefined){
        	helper.getlogDetails(component, event,helper,rec);
        } 
	},
	getlogDetails: function (component, event, helper,lctId) {
		//set action to call apex method from Server-side controller
		component.set("v.spinner","true"); //spinner start
		var action = component.get("c.getChatbotTranscript");
		action.setParams({
			recordId : component.get("v.recordId")
		});
		action.setCallback(this, function(response){
			if(response.getState() === "SUCCESS"){
				var responseBody = response.getReturnValue();
				component.set("v.chatLogDetailList",responseBody);
				if(responseBody.length >0){
               		component.set("v.caseID",responseBody[0].caseID);
                	helper.getSubtab(component, event, helper,component.get("v.recordId"),component.get("v.caseID"));
					component.set("v.error","false");
					component.set("v.card","true");
				}
				else{
					component.set("v.error","true");
					component.set("v.card","false");
				}
				component.set("v.spinner","false");
			}else{
				component.set("v.error","true");
				component.set("v.card","false");
				component.set("v.spinner","false");
			}
		});
		$A.enqueueAction(action);
	},
    //opening Enquiry subtab 
    getSubtab: function (component, event, helper,rec,caseID) {
		var workspaceAPI = component.find("workspace");         	
        // open a subtab with the related case/enquiry 
        workspaceAPI.getEnclosingTabId()
			.then(function(enclosingTabId) {
				// only create subtab if in a (parent) tab context
				if(enclosingTabId) {
					workspaceAPI.openSubtab({
						parentTabId: enclosingTabId,
						url: '/lightning/r/Case' + '/'+ caseID +'/'+ 'view', focus: false});
				}
				
			})   
			.catch(function(error) {
				console.log(error);
			}); 
    }  
})