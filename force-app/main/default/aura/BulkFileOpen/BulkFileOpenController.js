({
	doInit : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		var docs = helper.getDocumentList(component, recordId);		
	}
})