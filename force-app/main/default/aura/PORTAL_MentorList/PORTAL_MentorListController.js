({
    doInit : function(component, event, helper) {
        
        var contactAction = component.get("c.SERVER_getContactInfo");
        
        contactAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);      
            
            if (state === "SUCCESS") {
                component.set("v.contact", result);
            }
            else {
                
            }
        });
        
        $A.enqueueAction(contactAction);
        
        var action = component.get("c.SERVER_getMentorList");
        
        action.setParams({"sharing": component.get("v.sharing"),
                          "relevance": component.get("v.relevance"),
                          "maxItems": component.get("v.maxItems"),
                          "searchText": ""});
        
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            console.log('result: ' + JSON.stringify(result));
            console.log('state: ' + state);      
            
            if (state === "SUCCESS") {
                component.set("v.mentorList", result);
                
                var itemsPerPage = component.get("v.itemsPerPage");
                var mentorListToDisplay = result;
                
                if (itemsPerPage < result.length) {
                    mentorListToDisplay = result.slice(0, itemsPerPage);
                }
                
                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));
                
                console.log(mentorListToDisplay);
                component.set("v.mentorListToDisplay", mentorListToDisplay);
            }
            else {
                
            }
        });
        
        $A.enqueueAction(action);
    },
    
    previousPage : function (cmp, event, helper) {
        console.log("in previous page");
        
        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var mentorList = cmp.get("v.mentorList");
        
        if (currentPage - 1 == 1) {
            cmp.set("v.previousButtonDisabled", true);
        }
        
        if (currentPage + 1 >= Math.ceil(mentorList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", false);
        }
        
        var start = (currentPage - 2) * itemsPerPage;
        var end = (currentPage - 1) * itemsPerPage;
        console.log("start is " + start);
        console.log("end is " + end);
        if (start < 0) {
            start = 0;
        }
        
        var mentorListToDisplay = mentorList.slice(start, end);
        
        cmp.set("v.mentorListToDisplay", mentorListToDisplay);
        
        cmp.set("v.currentPage", currentPage - 1);
    },
    nextPage : function(cmp, event, helper) {
        console.log("in next page");
        
        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var mentorList = cmp.get("v.mentorList");
        // if this is the first page
        if (currentPage == 1) {
            cmp.set("v.previousButtonDisabled", false);
        }
        
        // Handle buttons disabled
        if (currentPage + 1 >= Math.ceil(mentorList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", true);
        }
        
        var start = currentPage * itemsPerPage;
        var end = (currentPage + 1) * itemsPerPage;
        
        console.log("start is " + start);
        console.log("end is " + end);
        
        if (end > mentorList.length) {
            end = mentorList.length;
        }
        
        var mentorListToDisplay = mentorList.slice(start, end);
        
        cmp.set("v.mentorListToDisplay", mentorListToDisplay);
        
        cmp.set("v.currentPage", currentPage + 1);
    },
    
    pageRefresh : function(component, event, helper) {
        //window.open("https://demo-ucinn-portal-uat-demo.cs71.force.com/alumniportal/s/events?",  "_self");
        
        
        var action = component.get("c.SERVER_getMentorList");
        
        action.setParams({"sharing": component.get("v.sharing"),
                          "relevance": component.get("v.relevance"),
                          "maxItems": component.get("v.maxItems"),
                          "searchText": ""});
        
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);      
            
            if (state === "SUCCESS") {
                component.set("v.mentorList", result);
                
                var itemsPerPage = component.get("v.itemsPerPage");
                var mentorListToDisplay = result;
                
                if (itemsPerPage < result.length) {
                    mentorListToDisplay = result.slice(0, itemsPerPage);
                }
                
                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));
                
                console.log(mentorListToDisplay);
                component.set("v.mentorListToDisplay", mentorListToDisplay);
            }
            else {
                
            }
        });
        
        $A.enqueueAction(action);
    },
    
    handleSearchTextChange : function(component, event, helper) {
        
        var action = component.get("c.SERVER_getMentorList");
        
        var searchText = component.get("v.searchText");
        
        //alert(searchText);
        
        action.setParams({"sharing": component.get("v.sharing"),
                          "relevance": component.get("v.relevance"),
                          "maxItems": component.get("v.maxItems"),
                          "searchText": searchText});
        
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('state: ' + state);  
            //alert('result: ' + JSON.stringify(result));    
            
            if (state === "SUCCESS") {
                component.set("v.mentorList", result);
                
                var itemsPerPage = component.get("v.itemsPerPage");
                var mentorListToDisplay = result;
                
                if (itemsPerPage < result.length) {
                    mentorListToDisplay = result.slice(0, itemsPerPage);
                }
                
                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));
                
                console.log(mentorListToDisplay);
                component.set("v.mentorListToDisplay", mentorListToDisplay);
            }
            else {
                
            }
        });
        
        $A.enqueueAction(action);
    },
    
    createNewMentor : function (component, event, helper) {
        var item = component.get("v.item");
        
        //alert(item.Id);
        
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Mentor__c"        
        });
        createRecordEvent.fire();
    },
    
    submitMentorApplication : function(component, event, helper) {
        var target = event.getSource();
        
        console.log('here1');

        var modalBody;
        $A.createComponent("c:PORTAL_MentorCreate", {},
           function(content, status) {
               //alert('status: ' + status);
               
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLib').showCustomModal({
                       header: "Submit Mentor Application",
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