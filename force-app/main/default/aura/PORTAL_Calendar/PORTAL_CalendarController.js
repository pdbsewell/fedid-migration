({
    // Calendar - controller
    
	doInit : function(component, event, helper) {
		helper.initCalendar(component, event, helper);

	},  // end function
    
	todayClicked : function(component, event, helper) {
 		helper.initCalendar(component, event, helper);

        helper.createCalendar(component); 

	},  // end function
    
    lastMonth : function(component, event, helper) {
		var beginningYear = component.get('v.beginningYear');
        
        var currentMonth = component.get('v.currentMonth');
        currentMonth = new Date(currentMonth);
        
        currentMonth = currentMonth.setMonth(currentMonth.getMonth() - 1);
        currentMonth = new Date(currentMonth);
        component.set('v.currentMonth', currentMonth);
        var month = currentMonth.getMonth() + 1;
        var year = currentMonth.getFullYear() ;

        // Adjust year combobox as needed.
        var selectedOptionValue = component.get('v.selectedOption');
        
        if (year.toString() != selectedOptionValue) {
            component.set("v.selectedOption", year.toString());
        }
        
        console.log('month: ' + month);
        console.log('year: ' + year);
        
        if (month == 1 && (year.toString() == beginningYear)) {
            // disable prevMonth button.
			component.set("v.disableLastMonthButton", true);
        }

        // If we just went to previous month, then next month button should always be enabled.
        component.set("v.disableNextMonthButton", false);
        
        helper.createCalendar(component); 
//        helper.retrieveEventList(component, month, year);
	},
    
 
    nextMonth : function(component, event, helper) {
        var endingYear = component.get('v.endingYear');

        var currentMonth = component.get('v.currentMonth');
        currentMonth = new Date(currentMonth);
        
        currentMonth = currentMonth.setMonth(currentMonth.getMonth() + 1);
        currentMonth = new Date(currentMonth);
        component.set('v.currentMonth', currentMonth);
        
        var month = currentMonth.getMonth() + 1;
        var year = currentMonth.getFullYear() ;
        
        // Adjust year combobox as needed.
        var selectedOptionValue = component.get('v.selectedOption');
        
        if (year.toString() != selectedOptionValue) {
            component.set("v.selectedOption", year.toString());
        }
        
        if (month == 12 && (year.toString() == endingYear)) {
            // disable prevMonth button.
			component.set("v.disableNextMonthButton", true);
        }

        // If we just went to next month, then previous month button should always be enabled.
        component.set("v.disableLastMonthButton", false);


        helper.createCalendar(component); 
//        helper.retrieveEventList(component, month, year);
        
	},


    handleYearChange : function(component, event, helper) {
		var beginningYear = component.get('v.beginningYear');
        var endingYear = component.get('v.endingYear');
        
        var selectedOptionValue = component.get('v.selectedOption');

        var year = selectedOptionValue;
        
        var currentMonth = component.get('v.currentMonth');
        currentMonth = new Date(currentMonth);
        
        currentMonth = currentMonth.setYear(year);
        currentMonth = new Date(currentMonth);
        component.set('v.currentMonth', currentMonth);
        
		var month = currentMonth.getMonth() + 1;
        
        console.log('month: ' + month);
        console.log('year: ' + year);
        console.log('endingYear: ' + endingYear);
        console.log('beginningYear: ' + beginningYear);
        
        if (month == 12 && (year.toString() == endingYear)) {
            // disable prevMonth button.
			component.set("v.disableNextMonthButton", true);
        }
        else {
            component.set("v.disableNextMonthButton", false);
        }
        
        if (month == 1 && (year.toString() == beginningYear)) {
            // disable prevMonth button.
			component.set("v.disableLastMonthButton", true);
        }    
        else {
            component.set("v.disableLastMonthButton", false);
        }

        helper.createCalendar(component);        
    },
    
	listingListChanged : function(component, event, helper) {
        var eventName = event.getParam("name");
        var listingList = event.getParam("listingList");
		var inputEventName = component.get("v.inputEventName");
            
        console.log('listingListChanged: ' + JSON.stringify(listingList));
        
//        if (eventName == inputEventName) {            
        	component.set('v.listingList', listingList);
        	helper.createCalendar(component);
//        }
    }    
    
})