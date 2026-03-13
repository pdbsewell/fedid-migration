({
    /*
     * This finction defined column header
     * and calls getAccounts helper method for column data
     * editable:'true' will make the column editable
     * */
	doInit : function(component, event, helper) {

        component.set('v.contact.Account__c', '');
        
        component.set('v.columns', [
 			{label: 'First Name', fieldName: 'linkName', type: 'url', sortable:true,
            		typeAttributes: {label: { fieldName: 'FirstName' }, target: '_parent'}},
 			{label: 'Last Name', fieldName: 'linkName', type: 'url', sortable:true,
            		typeAttributes: {label: { fieldName: 'LastName' }, target: '_parent'}},
            {label: 'Year', fieldName: 'ucinn_ascendv2__Preferred_Class_Year__c', type: 'text', sortable:true}
        ]);

        var action = component.get('c.SERVER_getBaseUrl')
        action.setCallback(this, function (response) {
            var state = response.getState()
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue()
                component.set('v.baseUrl', result)
                
                console.log('directory baseUrl: ' + result);
                
                // Need to get the base URL first before constructing the list of contacts.
               	helper.getContacts(component, helper);
            }
        })
        $A.enqueueAction(action)
    },
    
    onNext : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber+1);
        helper.buildData(component, helper);
    },
    
    onPrev : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber-1);
        helper.buildData(component, helper);
    },
    
    processMe : function(component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        helper.buildData(component, helper);
    },
    
    onFirst : function(component, event, helper) {        
        component.set("v.currentPageNumber", 1);
        helper.buildData(component, helper);
    },
    
    onLast : function(component, event, helper) {        
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.buildData(component, helper);
    },

 	// Client-side controller called by the onsort event handler
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    
    handleEnterKey : function(component, event, helper) {
    	var isEnterKey = event.keyCode === 13;
        
        //if (isEnterKey) {
			helper.getContacts(component, helper);
        //}
    },
    
    handleClick : function(component, event, helper) {
        
        helper.getContacts(component, helper);
/*
      	var searchText = component.get('v.searchText');
        
      	var action = component.get('c.searchForIds');
        
      	action.setParams({searchText: searchText});
        
      	action.setCallback(this, function(response) {
        	var state = response.getState();
            
        	if (state === 'SUCCESS') {
          		var ids = response.getReturnValue();
          		sessionStorage.setItem('customSearch--recordIds', JSON.stringify(ids));
          		var navEvt = $A.get('e.force:navigateToURL');
          		navEvt.setParams({url: '/directory'});
          		navEvt.fire();
        	}
      	});
        
      	$A.enqueueAction(action);
*/
    },
    
    handleSearchForChange: function (component, event, helper) {
        
        var toggleText = component.find("currentEmployerLookup");
        //$A.util.toggleClass(toggleText, "toggle");
 		$A.util.addClass(toggleText, "slds-hide");
        
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        //alert("Option selected with value: '" + selectedOptionValue + "'");
        component.set("v.searchForSelected", selectedOptionValue);
        
        component.set("v.classYear", "");
        component.set("v.constituentType", "");
        component.set("v.department", "");
        component.set("v.contact.Account__c", "");
        
        if (selectedOptionValue == 'FacultyStaff' ||
            selectedOptionValue == 'Student') {

            component.set("v.constituentType", selectedOptionValue);
            helper.getContacts(component, helper);
            
        } else if (selectedOptionValue == 'CurrentEmployer') {
            var toggleText = component.find("currentEmployerLookup");
            //$A.util.toggleClass(toggleText, "toggle");
            $A.util.removeClass(toggleText, "slds-hide");
            helper.getContacts(component, helper);
        }
        else {
        	helper.getContacts(component, helper);
        }
    },
    
    handleClassYearChange : function(component, event, helper) {
        //component.set("v.classYear", "");
        component.set("v.constituentType", "");
        component.set("v.department", "");
        component.set("v.contact.Account__c", "");
        
        // This will contain the string of the "value" attribute of the selected option
        var classYear = event.getParam("value");
        helper.getContacts(component, helper);
    },
    
    handleDepartmentChange : function(component, event, helper) {
        component.set("v.classYear", "");
        component.set("v.constituentType", "");
        //component.set("v.department", "");
        component.set("v.contact.Account__c", "");

        // This will contain the string of the "value" attribute of the selected option
        var department = event.getParam("value");
        helper.getContacts(component, helper);
    },
    
    handleEmployerChange : function(component, event, helper) {
        component.set("v.classYear", "");
        component.set("v.constituentType", "");
        component.set("v.department", "");
        //component.set("v.contact.Account__c", "");

        // This will contain the string of the "value" attribute of the selected option
        var employer = event.getParam("value");
        //alert('employer: ' + employer);
        helper.getContacts(component, helper);
    },
    
    handleSearchTextChange : function(component, event, helper) {
        helper.getContacts(component, helper);
    },
})