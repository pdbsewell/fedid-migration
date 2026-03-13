({
    /*
     * This finction defined column header
     * and calls getAccounts helper method for column data
     * editable:'true' will make the column editable
     * */
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
        
        component.set('v.columns', [
            {label: 'Year', fieldName: 'yearVal', type: 'text', sortable:true },
            {label: 'Payment Amount', fieldName: 'amtVal', type: 'currency', cellAttributes: { alignment: 'left' }, sortable:true },
			{label: 'Tax Letter', type: 'button', typeAttributes: { label: 'View Tax Letter', name: 'viewTaxLetter', title: 'Click to View tax letter'}},
        ]);

        helper.getYearEndTaxLetter(component, helper);
            
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
            
    handleRowAction: function (cmp, event, helper) {

        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'viewTaxLetter':
                helper.showRowDetails(cmp, row);
                break;
            default:
                break;
        }
    }
})