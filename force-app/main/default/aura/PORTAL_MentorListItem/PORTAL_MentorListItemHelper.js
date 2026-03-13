({
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.data", data);
    },
    
    //  to make it case insensitive and consider blank fields on top for ASC:
    //  https://success.salesforce.com/ideaView?id=0873A000000E8qiQAC
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x.hasOwnProperty(field) ? (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa')} :
        function(x) {return x.hasOwnProperty(field) ? (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa'};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {            
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    
    updateMenteeApplicationStatus : function(component, event, helper, menteeRec, status) {
        
        var action = component.get("c.SERVER_updateMenteeApplicationStatus");
        
        action.setParams({"menteeRec": menteeRec,
                          "status": status});
        
        //alert(JSON.stringify(menteeRec));
        //alert('status: ' + status);
        
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);      
            
            if (state === "SUCCESS") {
                
                var data = component.get('v.data');
                data = data.map(function(rowData) {
                    
                    //alert('rowData.Id: ' + rowData.Id);
                    //alert('menteeRec.Id: ' + menteeRec.Id);
                    
                    if (rowData.Id == menteeRec.Id) {
                        //alert('found match');
                        rowData.Application_Status__c = status;
                        
                        rowData.approveDisabled = false;
                        rowData.declineDisabled = false;
                        rowData.sendMessageDisabled = true;
                        
                        if (status == 'Approved') {
                            rowData.approveDisabled = true;
                            rowData.declineDisabled = false;
                            rowData.sendMessageDisabled = false;
                        } else if (status == 'Declined') {
                            rowData.approveDisabled = false;
                            rowData.declineDisabled = true;
                            rowData.sendMessageDisabled = true;
                        }
                        
                        //component.set("v.myStatus", status);
                        
                    }
                    return rowData;
                });
                component.set("v.data", data);
            }
            else {
                
            }
        });
        
        $A.enqueueAction(action);
    },
    
    sendMessage : function(component, event, helper, row) {
        // TBD: Need to pass contactId to PORTAL_DirectMessage since it could be from contact or mentee.
        var contact = component.get("v.contact");
        //alert('contact: ' + JSON.stringify(row));
        
        contact.Id = row.Mentee__c;
        contact.Name = row.Mentee_Name__c;
        
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
    
})