({
	doInit : function(component, event, helper) {
        var action = component.get('c.SERVER_getBaseUrl')
        action.setCallback(this, function (response) {
            var state = response.getState()
            
            console.log('state: ' + state);
            
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue()
            
            	console.log('baseUrl: ' + result);

            	component.set('v.baseUrl', result)
            }
        })
        $A.enqueueAction(action)
        
		helper.getListingList(component, event, helper, true);
	},
    
	carouselCicked : function(component, event, helper) {
        //alert('clicked');
    },
    
    previousPage : function (component, event, helper) {
        console.log("in previous page");

        var currentPage = component.get("v.currentPage");
        var itemsPerPage = component.get("v.itemsPerPage");
        var listingList = component.get("v.listingList");

        if (currentPage - 1 == 1) {
            component.set("v.previousButtonDisabled", true);
        }

        if (currentPage + 1 >= Math.ceil(listingList.length / itemsPerPage)) {
            component.set("v.nextButtonDisabled", false);
        }

        var start = (currentPage - 2) * itemsPerPage;
        var end = (currentPage - 1) * itemsPerPage;
        console.log("start is " + start);
        console.log("end is " + end);
        if (start < 0) {
            start = 0;
        }

        var listingListToDisplay = listingList.slice(start, end);

        component.set("v.listingListToDisplay", listingListToDisplay);

        component.set("v.currentPage", currentPage - 1);
    },
    nextPage : function(component, event, helper) {
        console.log("in next page");

        var currentPage = component.get("v.currentPage");
        var itemsPerPage = component.get("v.itemsPerPage");
        var listingList = component.get("v.listingList");
        // if this is the first page
        if (currentPage == 1) {
            component.set("v.previousButtonDisabled", false);
        }

        // Handle buttons disabled
        if (currentPage + 1 >= Math.ceil(listingList.length / itemsPerPage)) {
            component.set("v.nextButtonDisabled", true);
        }

        var start = currentPage * itemsPerPage;
        var end = (currentPage + 1) * itemsPerPage;

        console.log("start is " + start);
        console.log("end is " + end);

        if (end > listingList.length) {
            end = listingList.length;
        }

        var listingListToDisplay = listingList.slice(start, end);

        component.set("v.listingListToDisplay", listingListToDisplay);

        component.set("v.currentPage", currentPage + 1);
    },

    pageRefresh : function(component, event, helper) {
		helper.getListingList(component, event, helper, false);
	},
    
    handleSearchTextChange : function(component, event, helper) {
		helper.getListingList(component, event, helper, false);
    },
    
    handleClear : function(component, event, helper) {
        component.set("v.searchText", "");
        component.set("v.currentDate", "");
        
		helper.getListingList(component, event, helper, true);
    },
    
    calendarDayClicked : function(component, event, helper) {
        var eventName = event.getParam("name");
        var dateClicked = event.getParam("dateClicked");
        
        console.log('dateClicked: ' + dateClicked);
        
        component.set("v.currentDate", dateClicked);
        
        //if (eventName == inputEventName) {            
        	helper.getListingList(component, event, helper, false);
        //}
    },
    
})