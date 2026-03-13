({   
	initCalendar : function(component, event, helper) {
        var today = new Date();
        var dd = today.getDate();
        var mm = today.getMonth(); //January is 0!
        var yyyy = today.getFullYear();
      // get first day of month
        var today = new Date(yyyy, mm, 1); 
        component.set("v.currentMonth", today);
        
        var numYears = 5;
        
        var beginningYear = yyyy.toString();
        var endingYear = (yyyy + numYears).toString();
        
        component.set("v.beginningYear", beginningYear);
        component.set("v.endingYear", endingYear);

        var options = [];
        
        for (var i = 0; i <= numYears; i++) {
            options.push({'label': (yyyy + i).toString(), 'value': (yyyy + i).toString()});
        }
        
        component.set("v.options", options);
        component.set("v.selectedOption", yyyy.toString());

        // Commenting out since we want to have the PORTAL_EVT_Calendar event intialize the calendar.
        //helper.createCalendar(component); 

	},  // end function
    
	createCalendar : function(component) {

        var listingList = component.get('v.listingList');
        var today = component.get('v.currentMonth');
        var selectedDept = component.get('v.selectedDept');
        
        //these are labels for the days of the week
        var cal_days_labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];    
        component.set('v.daysOfWeek', cal_days_labels)
        // these are human-readable month name labels, in order
        var cal_months_labels = ['January', 'February', 'March', 'April',
                                 'May', 'June', 'July', 'August', 'September',
                                 'October', 'November', 'December'];        
        
        //today = new Date();
        // Returns the day of the month (from 1-31)
        var dd = today.getDate();
        console.log(' dd = ' + dd);
        
        //January is 0!
        // Returns the month (from 0-11)
        var mm = today.getMonth();
        console.log(' mm = ' + mm);
        
        // Returns the year
        var yyyy = today.getFullYear();
        
        console.log(' yyyy = ' + yyyy);
        
        // get first day of month
        var firstDay = new Date(yyyy, mm, 1);
        console.log(' firstday = ' + firstDay);
        
        // Returns the day of the week (from 0-6)
        var startingDay = firstDay.getDay();
        
        var nextDay = new Date(firstDay);
        component.set('v.month', cal_months_labels[mm] + ' ' + yyyy);       
        console.log(' starting day ' + startingDay);
        
        // find number of days in month
        // getDate() - Returns the day of the month (from 1-31)
        var monthLength = new Date(yyyy, mm + 1, 0).getDate();
        console.log (' monthLength ' + monthLength);  
        
        // compensate for leap year
        if (mm == 2) { // February only!
            if((yyyy % 4 == 0 && yyyy % 100 != 0) || yyyy % 400 == 0){
                monthLength = 29;
            }
        }
        
        

 // **********************************************************************88   
    // Array of components to create
    	var newComponents = [];
        
        // put the weeks/table rows in the components array
        for (var i = 0; i < 7; i++) 
        {
			newComponents.push(["aura:html", {
            	"tag": "tr"
      		}]);              
        }
        
        // This part blanks out any days prior to the start of the month.
        for (var i = 1; i <= startingDay; i++) {
            // put the days rows in the components array
       		 newComponents.push(["c:PORTAL_CalendarDay", {
				"visible": false
        	 }]); 
        }           
  
 // **********************************************************************
 // in this section, we loop through the days of the month and create components for each day       
 
        // Get the month and year of the date we are currently at in the calendar.
        var getMonth = nextDay.getMonth() + 1;
        var getFullYear = nextDay.getFullYear();
        
        var myDateIsoString = nextDay.toISOString().slice(0,10);
        
        console.log('getMonth: ' + getMonth);
        console.log('getFullYear: ' + getFullYear);   
        
        for (var i = 1; i <= monthLength; i++) {  //
            var stringBody = [];
            var hasListing = false;

            
            console.log('createCalendar: listingList: ' + JSON.stringify(listingList));
            
            if (listingList != null) {
                for(var e = 0;  e < listingList.length; e ++) {
                    var eventDate = new Date(listingList[e].StartDateTime);
                    
                    //eventDate = eventDate.toISOString().slice(0,10);
                    
                    console.log('createCalendar: eventDate: ' + JSON.stringify(eventDate));
                    
                    // if the calendar day of the month matches the calendar day of the event, then add the subject of the event to the calendar day component
                    if (eventDate.getDate() == i &&
                        eventDate.getMonth() + 1 == getMonth &&
                        eventDate.getFullYear() == getFullYear) {
                        console.log('match: i = ' + i);
                        hasListing = true;
                    }
                    else {
                        console.log('not match: i = ' + i);
                    }
                } // end for 
            }

            var myDate = getFullYear.toString() + '-' + getMonth.toString() + '-' + i.toString();
            console.log('myDate: ' + myDate);
            console.log('myDateIsoString: ' + myDateIsoString);
            
            newComponents.push(["c:PORTAL_CalendarDay", {
				"day": i,
                "toDoItems": stringBody,
                "hasListing": hasListing,
                "date": myDate,
        	}]);
        }  
        
        for (var i = 1; i <= 5; i++) {
            // put the days rows in the components array
       		 newComponents.push(["c:PORTAL_CalendarDay", {
                 "visible": false
        	 }]); 
        }             
            
     // **********************************************************************88           
     
       $A.createComponents(newComponents,
            function (components, status, errorMessage) {
               if (status === "SUCCESS") {
                   var pageBody = component.get("v.body");
                   pageBody = [];
                   for (var outer = 0; outer < 6; outer ++) {	
                        var tr = components[outer];
                        var trBody = tr.get("v.body");
                        for (var inner = 1; inner < 8; inner ++) {
                            var outerAdj = outer +0;
                            var adj =  6 + + inner + (7 * outerAdj); 
                            var toDay = components[adj];
                            trBody.push(toDay);
                        }
                        tr.set("v.body", trBody)
                        pageBody.push(tr);
                   }
    
                    component.set("v.body", pageBody);
                }  // end success
                else if (status === "INCOMPLETE") {
                    MessageHandlingService.incompleteServerCall();
                }
                else if (status === "ERROR") {
                    let error = response.getError();
                    
                    if (error && error[0] && error[0].message) {
                        MessageHandlingService.errorServerCall(error[0].message);
                    }
                    else {
                         MessageHandlingService.errorServerCall();
                    }
                }
            } // end callback function
        );     // end create component   
        		
	}
})