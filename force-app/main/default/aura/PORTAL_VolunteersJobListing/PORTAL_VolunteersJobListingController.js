({
	doInit : function(component, event, helper) {

        component.set('v.mapMarkers', [
            {
                location: {
                    Street: '230 Commerce',
                    City: 'Irvine',
                    State: 'CA',
                    Country: 'USA'
                },

                title: 'UC Innovation HQ',
                description: 'UC Innovation Headquarter.'
            }
        ]);
        
        component.set('v.center', {
            location: {
                City: 'Oodnadatta',
                State: 'South Australia',
                Country: 'Australia'
            }
        });

        component.set('v.zoomLevel', 4);
		component.set('v.markersTitle', 'Locations');        
        component.set('v.showFooter', true);
        
        var jobAction = component.get("c.SERVER_getVolunteerJobs");
        
		var showMap = component.get("v.showMap");

        jobAction.setParams({  "scope": component.get("v.scope"),
                               "sharing": component.get("v.sharing"),
                               "relevance": component.get("v.relevance"),
                               "maxItems": component.get("v.maxItems")});        

        //jobAction.setParams({ "signupContact": component.get("v.contact") });
   
        jobAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);  

            var locationList = [];    
            
            if (state === "SUCCESS") {
                component.set("v.volunteerJobList", result);

                var itemsPerPage = component.get("v.itemsPerPage");
                var volunteerJobListToDisplay = result;

                if (itemsPerPage < result.length) {
                    volunteerJobListToDisplay = result.slice(0, itemsPerPage);
                }
                
                console.log('itemsPerPage: ' + itemsPerPage);
                console.log('totalNumberOfPages: ' + Math.ceil(result.length / itemsPerPage));

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log(volunteerJobListToDisplay);
                component.set("v.volunteerJobListToDisplay", volunteerJobListToDisplay);                
                
                
                for (var i = 0; i < result.length; i++) {
                    var itemRec = result[i];
                    
                    console.log('itemRec: ' + JSON.stringify(itemRec));
                    
                    locationList.push({
                        location: {
                            Street: itemRec.Location_Street__c,
                            City: itemRec.Location_City__c,
                            PostalCode: itemRec.Location_Zip_Postal_Code__c,
                            State: itemRec.Location__c,
                            Country: itemRec.Country__c
                        },
                        title: itemRec.Name
                    });
                }
                
                //alert(JSON.stringify(locationList));
                
                component.set('v.mapMarkers', locationList);               
            }
            else {

            }
        });

        $A.enqueueAction(jobAction);
        
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
        
	},
    previousPage : function (cmp, event, helper) {
        console.log("in previous page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var volunteerJobList = cmp.get("v.volunteerJobList");

        if (currentPage - 1 == 1) {
            cmp.set("v.previousButtonDisabled", true);
        }

        if (currentPage + 1 >= Math.ceil(volunteerJobList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", false);
        }

        var start = (currentPage - 2) * itemsPerPage;
        var end = (currentPage - 1) * itemsPerPage;
        console.log("start is " + start);
        console.log("end is " + end);
        if (start < 0) {
            start = 0;
        }

        var volunteerJobListToDisplay = volunteerJobList.slice(start, end);

        cmp.set("v.volunteerJobListToDisplay", volunteerJobListToDisplay);

        cmp.set("v.currentPage", currentPage - 1);
    },
    nextPage : function(cmp, event, helper) {
        console.log("in next page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var volunteerJobList = cmp.get("v.volunteerJobList");
        // if this is the first page
        if (currentPage == 1) {
            cmp.set("v.previousButtonDisabled", false);
        }

        // Handle buttons disabled
        if (currentPage + 1 >= Math.ceil(volunteerJobList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", true);
        }

        var start = currentPage * itemsPerPage;
        var end = (currentPage + 1) * itemsPerPage;

        console.log("start is " + start);
        console.log("end is " + end);

        if (end > volunteerJobList.length) {
            end = volunteerJobList.length;
        }

        var volunteerJobListToDisplay = volunteerJobList.slice(start, end);

        cmp.set("v.volunteerJobListToDisplay", volunteerJobListToDisplay);

        cmp.set("v.currentPage", currentPage + 1);
    },
	carouselCicked : function(component, event, helper) {
        //alert('clicked');
    },
    
    pageRefresh : function(component, event, helper) {
        var jobAction = component.get("c.SERVER_getVolunteerJobs");

        jobAction.setParams({  "scope": component.get("v.scope"),
                               "sharing": component.get("v.sharing"),
                               "relevance": component.get("v.relevance"),
                               "maxItems": component.get("v.maxItems")});        

        //jobAction.setParams({ "signupContact": component.get("v.contact") });
   
        jobAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);  
            
            if (state === "SUCCESS") {
                component.set("v.volunteerJobList", result);

                var itemsPerPage = component.get("v.itemsPerPage");
                var volunteerJobListToDisplay = result;

                if (itemsPerPage < result.length) {
                    volunteerJobListToDisplay = result.slice(0, itemsPerPage);
                }
                
                console.log('itemsPerPage: ' + itemsPerPage);
                console.log('totalNumberOfPages: ' + Math.ceil(result.length / itemsPerPage));

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log(volunteerJobListToDisplay);
                component.set("v.volunteerJobListToDisplay", volunteerJobListToDisplay);                             
            }
            else {

            }
        });

        $A.enqueueAction(jobAction);
    }
})