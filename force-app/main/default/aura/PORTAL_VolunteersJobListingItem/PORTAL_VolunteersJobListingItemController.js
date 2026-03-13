({
    doInit : function(component, event, helper) {
        
    },
    
    signUpModal : function(component, event, helper) {
        var target = event.getSource();  
        
        var slotId = target.get("v.value");
        //alert('slotId: ' + slotId);
        
        var item = component.get("v.item");
        
        //alert('item: ' + JSON.stringify(item));
        
        var jobName = item.Name;
        var jobId = item.Id;
        
        //alert('jobName: ' + jobName);
        //alert('jobId: ' + jobId);
        
        var contact = component.get("v.contact");
        
        console.log('contact: ' + JSON.stringify(contact));
        
        var firstName = '';
        var lastName = '';
        var email = '';
        var homePhone = '';
        var phone = '';
        var volunteerOrganization = '';
        
        if (contact != null) {
            firstName = contact.FirstName;
            lastName = contact.LastName;
            email = contact.Email;
            homePhone = contact.HomePhone;
            phone = contact.Phone;
            volunteerOrganization = contact.Volunteer_Organization__c;
        }
        else {
            contact = new Object();
        }
        
        console.log('contact: ' + JSON.stringify(contact));
        
        var modalBody;
        $A.createComponent("c:PORTAL_VolunteersJobSignup", {"volunteerJobId":jobId,
                                                            "volunteerSlotId": slotId, 
                                                            "firstName": firstName, 
                                                            "lastName": lastName, 
                                                            "email": email, 
                                                            "homePhone": homePhone, 
                                                            "phone": phone,
                                                            "volunteerOrganization": volunteerOrganization,
                                                            "contact": contact},
                           function(content, status) {
                               //alert('status: ' + status);
                               
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Volunteer Sign Up for " + jobName,
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
    
    checkInModal : function(component, event, helper) {
        
        var target = event.getSource();  
        
        var shiftIdStartDateEndDate = target.get("v.value");
        
        //alert('shiftIdStartDateEndDate: ' + shiftIdStartDateEndDate);
        
        var strSplit = shiftIdStartDateEndDate.split("_");
        
        //alert(strSplit.length);
        
        var shiftId;
        var startDate;
        var endDate;
        
        if (strSplit.length == 3) {
            shiftId = strSplit[0];
            startDate = strSplit[1];
            endDate = strSplit[2];
        }
        else {
            shiftId = strSplit[0];
        }
        
        var item = component.get("v.item");
        
        //alert('item: ' + JSON.stringify(item));
        
        var jobName = item.Name;
        var jobId = item.Id;
        
        //var jobName = component.get("v.volunteerJobList")[index].Name;
        //var jobId = component.get("v.volunteerJobList")[index].Id;
        
        var contact = component.get("v.contact");
        
        if (contact == null) {
            contact = new Object();
        }        
        
        //alert('shiftId: ' + shiftId);
        //alert('startDate: ' + startDate);
        //alert('endDate: ' + endDate);
        //alert('contact: ' + JSON.stringify(contact));
        
        var modalBody;
        $A.createComponent("c:PORTAL_VolunteersReportHours", {"volunteerJobId": jobId,
                                                              "volunteerShiftId": shiftId,
                                                              "jobStartDateTime": startDate,
                                                              "jobEndDateTime": endDate,
                                                              "contact": contact},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Report Hours for " + jobName,
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
})