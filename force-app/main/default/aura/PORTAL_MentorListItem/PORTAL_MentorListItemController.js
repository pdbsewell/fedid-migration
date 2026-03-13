({
    doInit : function(component, event, helper) {
        var item = component.get("v.item");
        var contact = component.get("v.contact");
        
        //alert(JSON.stringify(item));
        //alert(JSON.stringify(item.Mentees_Mentor__r));
        
        if (item.Mentees_Mentor__r != null) {
            
            for (var i = 0; i < item.Mentees_Mentor__r.length; i++) {
                var requestStatus = item.Mentees_Mentor__r[i].Application_Status__c;
                
                item.Mentees_Mentor__r[i].approveDisabled = false;
                item.Mentees_Mentor__r[i].declineDisabled = false;
                item.Mentees_Mentor__r[i].sendMessageDisabled = true;
                
                if (requestStatus == 'Approved') {
                    item.Mentees_Mentor__r[i].approveDisabled = true;
                    item.Mentees_Mentor__r[i].declineDisabled = false;
                    item.Mentees_Mentor__r[i].sendMessageDisabled = false;
                } else if (requestStatus == 'Declined') {
                    item.Mentees_Mentor__r[i].approveDisabled = false;
                    item.Mentees_Mentor__r[i].declineDisabled = true;
                    item.Mentees_Mentor__r[i].sendMessageDisabled = true;
                }
                
                if (item.Mentees_Mentor__r[i].Mentee__c == contact.Id) {
                    component.set("v.myStatus", requestStatus);
                    component.set("v.menteeRecordId", item.Mentees_Mentor__r[i].Id);
                    component.set("v.isInitDone", true);
                    
                    console.log("menteeRecordId: " + item.Mentees_Mentor__r[i].Id)
                }
                
            }
        }
        
        component.set("v.data", item.Mentees_Mentor__r);
        
        component.set('v.columns', [
            {label: 'Requester', fieldName: 'Mentee_Name__c', type: 'text', sortable:true},
            {label: 'Topics of Interest', fieldName: 'Topics_of_Interest__c', type: 'text', sortable:true},
            {label: 'Application Status', fieldName: 'Application_Status__c', type: 'text', sortable:true},
            { type: 'button', typeAttributes: { label: 'Approve', name: 'approve', title: 'Click to approve', disabled: {fieldName: 'approveDisabled'}}},
            { type: 'button', typeAttributes: { label: 'Decline', name: 'reject', title: 'Click to reject', disabled: {fieldName: 'declineDisabled'}}},
            { type: 'button', typeAttributes: { label: 'Send Message', name: 'send_message', title: 'Click to send message', disabled: {fieldName: 'sendMessageDisabled'}}}
        ]);
        /*
        var data = component.get('v.data');
        
        if (data != null) {
            data = data.map(function(rowData) {
                alert(JSON.stringify(rowData));
                
                if (rowData.Application_Status__c == 'Approved') {
                        //rowData.disabled = true;
                }
                
                //return rowData;
            });
            //cmp.set("v.data", data);
        
        }
*/
        //alert(JSON.stringify(item));
    },
    
    editRecord : function(component, event, helper) {
        var item = component.get("v.item");
        
        //alert(item.Id);
        
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": item.Id
        });
        editRecordEvent.fire();
    },
    
    createRecord : function (component, event, helper) {
        var item = component.get("v.item");
        var contact = component.get("v.contact");
        
        //alert(item.Id);
        
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Mentee__c",
            "defaultFieldValues": {
                'Mentor__c': item.Id,
                'Mentee__c': contact.Id
            }            
        });
        createRecordEvent.fire();
    },
    
    sendMessage : function(component, event, helper) {
        var item = component.get("v.item");
        var contact = component.get("v.contact");
        
        contact.Id = item.CreatedById;
        contact.Name = item.Mentor_Name__c;
        
        //alert('contact: ' + JSON.stringify(contact));
        
        var modalBody;
        $A.createComponent("c:PORTAL_DirectMessage", {"contact":contact},
                           function(content, status, errorMessage) {
                               //alert('status: ' + status);
                               
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlaySendDirectMessage').showCustomModal({
                                       header: "Send Message to " + contact.Name,
                                       body: modalBody, 
                                       showCloseButton: true,
                                       closeCallback: function() {
                                           //alert('You closed the alert!');
                                       }
                                   })
                               }
                               else if (status === "INCOMPLETE") {
                                   console.log("No response from server or client is offline.")
                                   // Show offline error
                               }
                                   else if (status === "ERROR") {
                                       console.log("Error: " + errorMessage);
                                       // Show error message
                                   }
                           });          
    },
    
    // Client-side controller called by the onsort event handler
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        
        //alert(JSON.stringify(row));
        
        switch (action.name) {
            case 'approve':
                helper.updateMenteeApplicationStatus(cmp, event, helper, row, 'Approved');
                break;
            case 'reject':
                helper.updateMenteeApplicationStatus(cmp, event, helper, row, 'Declined');
                break;
            case 'send_message':
                helper.sendMessage(cmp, event, helper, row);
                break;
        }
    },
    
    editMentorApplication : function(component, event, helper) {
        var target = event.getSource();
        
        var recordId = component.get("v.item.Id");

        console.log('recordId: ' + recordId);

        var modalBody;
        $A.createComponent("c:PORTAL_MentorCreate", {"recordId": recordId},
           function(content, status) {
               //alert('status: ' + status);
               
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLibEditMentor').showCustomModal({
                       header: "Edit Mentor Application",
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
    
    handleDeleteMentorRecord: function(component, event, helper) {
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
    
    submitMenteeApplication : function(component, event, helper) {
        var target = event.getSource();
        
        var mentorRecId = component.get("v.item.Id");
        var contactId = component.get("v.contact.Id");

        console.log('mentorRecId: ' + mentorRecId);

        var modalBody;
        $A.createComponent("c:PORTAL_MenteeCreate", {"mentorRecId": mentorRecId,
                                                     "contactId": contactId
                                                    },
           function(content, status) {
               //alert('status: ' + status);
               
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLibEditMentee').showCustomModal({
                       header: "Submit Mentee Application",
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
    
    editMenteeApplication : function(component, event, helper) {
        var target = event.getSource();
        
        var mentorRecId = component.get("v.item.Id");
        var contactId = component.get("v.contact.Id");

        console.log('mentorRecId: ' + mentorRecId);

        var modalBody;
        $A.createComponent("c:PORTAL_MenteeCreate", {"mentorRecId": mentorRecId,
                                                     "contactId": contactId
                                                    },
           function(content, status) {
               //alert('status: ' + status);
               
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLibEditMentee').showCustomModal({
                       header: "Edit Mentee Application",
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
        
    handleDeleteMenteeRecord: function(component, event, helper) {
        if (confirm("Are you sure?")) {

            console.log('Deleting mentee...');
            
            component.find("recordHandlerMentee").deleteRecord($A.getCallback(function(deleteResult) {
                console.log("state: " + deleteResult.state);
                
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