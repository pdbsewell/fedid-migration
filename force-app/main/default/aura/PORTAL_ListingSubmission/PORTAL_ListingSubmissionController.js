({
	doInit : function(component, event, helper) {

        var recordTypeIdAction = component.get("c.SERVER_getRecordTypeId");

        recordTypeIdAction.setParams({"recordType": component.get("v.recordType")});
   
        recordTypeIdAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            console.log('result: ' + JSON.stringify(result));
            console.log('state: ' + state);      
        
            if (state === "SUCCESS") {
                component.set("v.recordTypeId", result);
            }
            else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            }
            else if (state === "ERROR") {
                let error = response.getError();
                
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                     MessageHandlingService.errorServerCall();
                }
            }
        });

        $A.enqueueAction(recordTypeIdAction);

        var contactAction = component.get("c.SERVER_getContactInfo");
        
        contactAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);      
        
            if (state === "SUCCESS") {
                component.set("v.contact", result);
            }
            else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            }
            else if (state === "ERROR") {
                let error = response.getError();
                
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                     MessageHandlingService.errorServerCall();
                }
            }
        });

        $A.enqueueAction(contactAction);
        
        var action = component.get("c.SERVER_getMyListingList");

        action.setParams({"recordType": component.get("v.recordType"),
            			  "maxItems": component.get("v.maxItems"),
                          "searchText": "",
                          "portalZone": "All"});
   
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);      
        
            if (state === "SUCCESS") {
                component.set("v.listingList", result);

                var itemsPerPage = component.get("v.itemsPerPage");
                var listingListToDisplay = result;

                if (itemsPerPage < result.length) {
                    listingListToDisplay = result.slice(0, itemsPerPage);
                }

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log('listingListToDisplay: ' + JSON.stringify(listingListToDisplay));
                component.set("v.listingListToDisplay", listingListToDisplay);
            }
            else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            }
            else if (state === "ERROR") {
                let error = response.getError();
                
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                     MessageHandlingService.errorServerCall();
                }
            }
        });

        $A.enqueueAction(action);
	},
    
    previousPage : function (cmp, event, helper) {
        console.log("in previous page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var listingList = cmp.get("v.listingList");

        if (currentPage - 1 == 1) {
            cmp.set("v.previousButtonDisabled", true);
        }

        if (currentPage + 1 >= Math.ceil(listingList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", false);
        }

        var start = (currentPage - 2) * itemsPerPage;
        var end = (currentPage - 1) * itemsPerPage;
        console.log("start is " + start);
        console.log("end is " + end);
        if (start < 0) {
            start = 0;
        }

        var listingListToDisplay = listingList.slice(start, end);

        cmp.set("v.listingListToDisplay", listingListToDisplay);

        cmp.set("v.currentPage", currentPage - 1);
    },
    nextPage : function(cmp, event, helper) {
        console.log("in next page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var listingList = cmp.get("v.listingList");
        // if this is the first page
        if (currentPage == 1) {
            cmp.set("v.previousButtonDisabled", false);
        }

        // Handle buttons disabled
        if (currentPage + 1 >= Math.ceil(listingList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", true);
        }

        var start = currentPage * itemsPerPage;
        var end = (currentPage + 1) * itemsPerPage;

        console.log("start is " + start);
        console.log("end is " + end);

        if (end > listingList.length) {
            end = listingList.length;
        }

        var listingListToDisplay = listingList.slice(start, end);

        cmp.set("v.listingListToDisplay", listingListToDisplay);

        cmp.set("v.currentPage", currentPage + 1);
    },

    pageRefresh : function(component, event, helper) {
        var action = component.get("c.SERVER_getMyListingList");

        action.setParams({"recordType": component.get("v.recordType"),
            			  "maxItems": component.get("v.maxItems"),
                          "searchText": "",
                          "portalZone": "All"});
   
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);      
        
            if (state === "SUCCESS") {
                component.set("v.listingList", result);

                var itemsPerPage = component.get("v.itemsPerPage");
                var listingListToDisplay = result;

                if (itemsPerPage < result.length) {
                    listingListToDisplay = result.slice(0, itemsPerPage);
                }

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log('listingListToDisplay: ' + JSON.stringify(listingListToDisplay));
                component.set("v.listingListToDisplay", listingListToDisplay);
            }
            else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            }
            else if (state === "ERROR") {
                let error = response.getError();
                
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                     MessageHandlingService.errorServerCall();
                }
            }
        });

        $A.enqueueAction(action);
	},
    
    handleSearchTextChange : function(component, event, helper) {
        
        var action = component.get("c.SERVER_getMentorList");
                                
		var searchText = component.get("v.searchText");
        
        //alert(searchText);

        action.setParams({"maxItems": component.get("v.maxItems"),
                          "searchText": searchText});
   
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('state: ' + state);  
            //alert('result: ' + JSON.stringify(result));    
        
            if (state === "SUCCESS") {
                component.set("v.listingList", result);

                var itemsPerPage = component.get("v.itemsPerPage");
                var listingListToDisplay = result;

                if (itemsPerPage < result.length) {
                    listingListToDisplay = result.slice(0, itemsPerPage);
                }

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log(listingListToDisplay);
                component.set("v.listingListToDisplay", listingListToDisplay);
            }
            else {

            }
        });

        $A.enqueueAction(action);
    },
    
	createNewListing : function (component, event, helper) {
        var item = component.get("v.item");
        var contact = component.get("v.contact");
        
        var recordTypeId = component.get("v.recordTypeId");
        
        //alert(item.Id);
        
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Listing__c",
            "recordTypeId" : recordTypeId
        });
        createRecordEvent.fire();
    },
    
    
    submitEventModel : function(component, event, helper) {
        var target = event.getSource();
        
        var recordTypeId = component.get("v.recordTypeId");
        
        console.log('here1');

        var modalBody;
        $A.createComponent("c:PORTAL_ListingCreate", {"recordTypeId": recordTypeId},
           function(content, status) {
               //alert('status: ' + status);
               
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLib').showCustomModal({
                       header: "Submit Event Application",
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