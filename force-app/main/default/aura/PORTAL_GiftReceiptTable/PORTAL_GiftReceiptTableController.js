({
    /*
     * This finction defined column header
     * and calls getAccounts helper method for column data
     * editable:'true' will make the column editable
     * */
	doInit : function(component, event, helper) {     
        component.set('v.columns', [
            {label: 'Date', fieldName: 'ucinn_ascendv2__Credit_Date__c', type: 'date-local', sortable:true },
            {label: 'Payment Amount', fieldName: 'ucinn_ascendv2__Payment_Amount__c', type: 'currency', cellAttributes: { alignment: 'left' }, sortable:true },
            {label: 'Designation', fieldName: 'ucinn_ascendv2__Designation_Description_Formula__c', type: 'text', sortable:true },
            {label: 'Tender Type', fieldName: 'ucinn_ascendv2__Tender_Type_Formula__c', type: 'text', sortable:true },
            {label: 'Transaction Type', fieldName: 'ucinn_ascendv2__Transaction_Type__c', type: 'text', sortable:true },
			{label: 'Gift Receipt', type: 'button', initialWidth: 135, typeAttributes: { label: 'View Receipt', name: 'viewGiftReceipt', title: 'Click to View Gift Receipt'}},
        ]);

        helper.getGiftReceiptDetails(component, helper);
            
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
/*            
        var commPrefixAction = component.get('c.getCommunityPrefixName')
        commPrefixAction.setCallback(this, function (response) {
            var state = response.getState()
            
            console.log('state: ' + state);
            
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue()
            
            	console.log('communityPrefix: ' + result);
            
                component.set('v.communityPrefix', result)
            }
        })
        $A.enqueueAction(commPrefixAction)            
*/
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
    updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
            
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'viewGiftReceipt':
                helper.showRowDetails(component, row);
                break;
            default:
                break;
        }
    }
})