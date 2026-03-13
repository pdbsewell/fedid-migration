({
	dayClicked : function(component, event, helper) {
        var myDate = component.get("v.date");
        console.log('myDate: ' + JSON.stringify(myDate));
        
        var calendarEvent = $A.get("e.c:PORTAL_EVT_CalendarDayClicked");
        calendarEvent.setParams({
            name: "",
            dateClicked: myDate
        });
        calendarEvent.fire();           
	}
})