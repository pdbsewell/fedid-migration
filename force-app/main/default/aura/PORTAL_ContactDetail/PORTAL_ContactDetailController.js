({
	doInit : function(component, event, helper) {
      	var recordId = component.get('v.recordId');
       
        var action = component.get("c.SERVER_getContactInfo");
      	action.setParams({"contactId": recordId});

        action.setCallback(this,function(response) {
            var state = response.getState();
            var response = response.getReturnValue();
           
            if (state === "SUCCESS") {               
            
                //alert(JSON.stringify(response));
                
                //alert('Department: ' + response.Department);
                
                if (response != null) {
                    
                    if (response.ucinn_ascendv2__Degree_Information_Contact__r != null) {
                    	var major = response.ucinn_ascendv2__Degree_Information_Contact__r[0].ucinn_ascendv2__Degree__c;  
                        //alert('major: ' + major);
                        component.set("v.major", major);
                        
                    	var department = response.ucinn_ascendv2__Degree_Information_Contact__r[0].ucinn_ascendv2__Major_Formula__c;   
                    	//alert('department: ' + department);
						component.set("v.department", department);                          
                    }                  
                }
                
                component.set("v.contact", response);
            }
        });
        
        $A.enqueueAction(action);

        
        var myAction = component.get("c.SERVER_getMyContactInfo");

        myAction.setCallback(this,function(response) {
            var state = response.getState();
            var response = response.getReturnValue();
           
            if (state === "SUCCESS") { 
                component.set("v.myContact", response);
            }
        });

        $A.enqueueAction(myAction);
	},
    
    sendMessage : function(component, event, helper) {
        var contact = component.get("v.contact");

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
})