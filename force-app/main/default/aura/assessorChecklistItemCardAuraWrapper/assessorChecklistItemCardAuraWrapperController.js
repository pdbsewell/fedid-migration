({
	doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var parentId = component.get("v.parentId");
        console.log("assessorChecklistItemCardAuraWrapper doInit beforeif parentId= " + parentId);
        console.log("assessorChecklistItemCardAuraWrapperdoInit fileColumnCount= " + component.get("v.fileColumnCount"));
        console.log("assessorChecklistItemCardAuraWrapper doInit viewType= " + component.get("v.viewType"));
        console.log("assessorChecklistItemCardAuraWrapper doInit recordId= " + recordId);

        if(!parentId) { // if parentId is not provided, use record id
            console.log("assessorChecklistItemCardAuraWrapper doInit afterif parentId= " + parentId);
            component.set("v.parentId", recordId);   
        }    
	},
})