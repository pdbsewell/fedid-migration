({
    editRecord : function(component, event, helper) {
        var item = component.get("v.item");
        
        //alert(item.Id);
        
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
             "recordId": item.Id
       });
        editRecordEvent.fire();
	},
    
    editEventApplication : function(component, event, helper) {
        var target = event.getSource();
        
        var recordId = component.get("v.item.Id");
        var recordTypeId = component.get("v.recordTypeId");

        console.log('recordId: ' + recordId);

        var modalBody;
        $A.createComponent("c:PORTAL_ListingCreate", {"recordTypeId": recordTypeId,
                                                      "recordId": recordId
                                                     },
           function(content, status) {
               //alert('status: ' + status);
               
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLibEditListing').showCustomModal({
                       header: "Edit Event Application",
                       body: modalBody, 
                       showCloseButton: true,
                       closeCallback: function() {
                           //alert('You closed the alert!');
                       }
                   })
               }
               else {
                   alert('cannot create component');
               }
           });          
    },   

    handleDeleteRecord: function(component, event, helper) {
        if (confirm("Are you sure?")) {        
            console.log('Deleting...');
            
            component.find("recordHandler").deleteRecord($A.getCallback(function(deleteResult) {
                // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
                // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
                if (deleteResult.state === "SUCCESS" || deleteResult.state === "DRAFT") {
                    // record is deleted
                    console.log("Record is deleted.");
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"title": "Success!","message": "Application is deleted.","type": "success"});
                    toastEvent.fire();
                    
                } else if (deleteResult.state === "INCOMPLETE") {
                    console.log("User is offline, device doesn't support drafts.");
                } else if (deleteResult.state === "ERROR") {
                    console.log('Problem deleting record, error: ' + JSON.stringify(deleteResult.error));
                } else {
                    console.log('Unknown problem, state: ' + deleteResult.state + ', error: ' + JSON.stringify(deleteResult.error));
                }
            }));
}
    },
})