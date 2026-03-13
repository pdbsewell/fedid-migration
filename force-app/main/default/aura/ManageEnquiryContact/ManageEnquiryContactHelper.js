({
	setupContactSearch : function (component, event) {
	    component.set('v.columns', [
            {label: 'Contact Name', fieldName: 'Name', type: 'button', typeAttributes: { label: { fieldName: 'Name' }, variant : 'base'}, sortable: true},
            {label: 'Person ID', fieldName: 'Person_ID__c', type: 'text', sortable: true},
            {label: 'Monash Email Address', fieldName: 'Monash_Email_Address__c', type: 'text', sortable: true},
            {label: 'Mobile', fieldName: 'MobilePhone', type: 'text', sortable: true},
            {label: 'Phone', fieldName: 'Phone', type: 'text', sortable: true},
            {label: 'Email', fieldName: 'Email', type: 'text', sortable: true}
        ]);
	},
	retrieveContacts : function (component, event) {
	    var searchString = component.find('contact-search').get('v.value');
	    
	    //Initiate Search when there are more than 2 characters on the search word
	    if(searchString.length > 3){
	        //Show table loading
	        component.set('v.isTableLoading', true);
	        
    	    //Search
    	    var action = component.get("c.searchContact");
    	    
            //Set parameters
            action.setParams({ 
                searchText : searchString
            });
            
            // Create a callback that is executed after 
            // the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //Process results
                    var searchData = [];
                    var searchResult = response.getReturnValue();
                    
                    if(searchResult) {
                        searchData = JSON.parse(searchResult);
                    }
                    
                    component.set('v.resultLength', (response.getReturnValue().match(new RegExp("\"type\":\"Contact\"", "g")) || []).length);
                    component.set('v.data', searchData);
                    
                    //Stop table spinner
                    component.set('v.isTableLoading', false);
                }
                else if (state === "INCOMPLETE") {
                    // do something
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            
            $A.enqueueAction(action);
	    }
	},
	sortData : function (component, fieldName, sortDirection) {
        var data = component.get("v.data");
        var reverse = sortDirection !== 'asc';

        data = Object.assign([],
            data.sort(this.sortBy(fieldName, reverse ? -1 : 1))
        );
        component.set("v.data", data);
    },
    sortBy : function (field, reverse, primer) {
        var key = primer
            ? function(x) { return primer(x[field]) }
            : function(x) { return x[field] };

        return function (a, b) {
            var A = key(a);
            var B = key(b);
            return reverse * ((A > B) - (B > A));
        };
    },
    copyFromEnquiry : function (component, fieldName, sortDirection) {
        //Call method to retrieve enquiry's supplied info details
	    var action = component.get("c.copyContactDetailsFromEnquiry");
	    
        //Set parameters
        action.setParams({ 
            enquiryId : component.get('v.recordId')
        });
        
        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //Process results
                var caseResult = response.getReturnValue();
                console.log(caseResult);
                //Set contact form fields
                component.find('contactFirstName').set('v.value', caseResult['Supplied_First_Name__c']);
                component.find('contactLastName').set('v.value', caseResult['Supplied_Last_Name__c']);
                component.find('contactEmail').set('v.value', caseResult['SuppliedEmail']);
                component.find('contactPhone').set('v.value', caseResult['SuppliedPhone']);
                component.find('contactBirthDate').set('v.value', caseResult['Supplied_Date_of_Birth__c']);
                component.find('contactOptOut').set('v.value', caseResult['Supplied_Email_Opt_out__c']);
                
                //Set picklist values
                component.find('contactNationality').set('v.value', caseResult['Supplied_Nationality__c']);
                component.find('contactCountryOfResidence').set('v.value', caseResult['Supplied_Country_of_Residence__c']);
                component.find('contactResidencyStatus').set('v.value', caseResult['Residency_Status__c']);
                component.find('contactHighestLevelOfEducationToDate').set('v.value', caseResult['Highest_Level_of_Study__c']);
                
                component.set('v.showManageEnquiryContactSpinner', false);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    }
})