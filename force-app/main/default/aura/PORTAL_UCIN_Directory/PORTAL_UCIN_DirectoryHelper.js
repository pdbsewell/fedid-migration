({
	getContacts : function(component, helper, offset, reverseList, searchText) {
        component.set("v.loaded", false);
        var sortedByApiName = component.get('v.sortedByApiName');
        var sortDirection = component.get('v.sortDirection');
        var itemsPerPage = component.get('v.pageSize');
        var sortedValue = null;
        var contactId = null;
        var filterSearchText = component.get("v.filterSearchText");
        var searchForSelected = component.get("v.searchForSelected");
        var baseUrl = component.get('v.baseUrl');
        var action = component.get("c.SERVER_getContacts");

        if (!searchText) {
            searchText = component.find('enter-search').get('v.value');
        }

		// Get first id and value if we're reversing the list
        if (reverseList == true) {
            sortedValue = component.get('v.firstSortedValue');
			contactId = component.get('v.firstContactId');

			// Specific to 'Last' button
            if (!sortedValue && !contactId) {
				itemsPerPage = component.get('v.totalRecords') % itemsPerPage;
				// If mod is 0, then should show the complete last page.
				if (itemsPerPage == 0) {
					itemsPerPage = component.get("v.pageSize");
				}
				
            }
        } else if (reverseList == false) {
            sortedValue = component.get('v.lastSortedValue');
            contactId = component.get('v.lastContactId');
        }

       // console.log('searchForSelected' + searchForSelected);
        //console.log('filterSearchText' + filterSearchText);

        action.setParams({'searchText': searchText,
                          'searchForSelected': searchForSelected,
                          'filterSearchText': filterSearchText,
                          'sortedByApiName': sortedByApiName,
                          'sortDirection': sortDirection,
                          'itemsPerPage': itemsPerPage,
                          'offset': offset,
                          'reverseList': reverseList,
                          'contactId': contactId,
                          'sortedValue': sortedValue});

        action.setCallback(this,function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
           // console.log('STATE: ' + state);

            if (state === "SUCCESS") {
               // console.log(JSON.stringify(response.getReturnValue()));
               // console.log('Response Time: '+((new Date().getTime())-requestInitiatedTime));
                
                var records = result['contactList'];               
                var totalPages = Math.ceil(result['count']/component.get("v.pageSize"));

                if(reverseList == true) {
                    records.reverse();
                }

                if (records.length != 0) {
                    var firstRecord = records[0];
                    var lastRecord = records[records.length-1];

                    //console.log(sortedByApiName);

                    component.set('v.firstSortedValue', firstRecord[sortedByApiName]);
                    component.set('v.lastSortedValue', lastRecord[sortedByApiName]);
                    component.set('v.firstContactId', firstRecord.Id)
					component.set('v.lastContactId', lastRecord.Id)
                }
                
                if (totalPages == 0) {
                    totalPages = 1;
                } 
                
                records.forEach(function(record) {
                    if (record.Contact_Qualifications__r != undefined && record.Contact_Qualifications__r.length > 0) {
                        for (var eachDegree of record.Contact_Qualifications__r) {
                            var dt = new Date(eachDegree.Date_Achieved__c);
                            eachDegree.degreeYear = dt.getFullYear();
                        }                        
                    }                    
                });

                component.set("v.totalPages", totalPages);
                component.set("v.allData", records);
                helper.buildData(component, helper); 
            } else {
               // console.log(response.getError()[0].message);
			}
			component.set("v.loaded", true);
        });
        
        var requestInitiatedTime = new Date().getTime();
        
		$A.enqueueAction(action);
		
    },
    
    getLoggedInContact: function(component, helper) {
        let action = component.get("c.SERVER_getMyContactInfo");
        action.setCallback(this,function(response) {
            var status = response.getState();
            var returnValue = response.getReturnValue();
            
            if (status === "SUCCESS") {
                component.set("v.loggedInContactId", returnValue.Id);
                //console.log('charlie ' + returnValue.Id);
            } else if (status === "INCOMPLETE") {
                //console.log('incomplete');
            } else if (status == "ERROR") {
                var errors = response.getError();
                //console.log(errors);
            }
        });

        $A.enqueueAction(action);
    },
	
	/*
     * this function will build table data
     * based on current page selection
     * */
    buildData : function(component, helper) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var allData = component.get("v.allData");
        var x = 0;

        //creating data-table data
        for(; x<pageSize; x++){
            if(allData[x]){
            	data.push(allData[x]);
            }
        }
        component.set("v.data", data);
        
        helper.generatePageList(component, pageNumber);
    },
    
    /*
     * this function generate page list
     * */
    generatePageList : function(component, pageNumber){
        pageNumber = parseInt(pageNumber);
        var pageList = [];
		var totalPage = component.get("v.totalPages");
		var firstPageTracked;
        var lastPageTracked;
                
        // Special case, to make sure ... doesn't show up
        if (totalPage == 2) {
            firstPageTracked = 2;
            lastPageTracked = 1;
        }
        else if (pageNumber < 7) {
			var startPage = 2;
            firstPageTracked = startPage;

            var count = 0;
            for (var i = startPage; i < totalPage; i++) {
                pageList.push(i);
				count++;
				
				lastPageTracked = i;
                
                if (count >= 5) {
                    break;
                }
            }
        } else if (pageNumber > (totalPage - 5)) {
			pageList.push(totalPage-5, totalPage-4, totalPage-3, totalPage-2, totalPage-1);
			firstPageTracked = totalPage-5;
			lastPageTracked = totalPage-1;
        } else {
			pageList.push(pageNumber-2, pageNumber-1, pageNumber, pageNumber+1, pageNumber+2);
			firstPageTracked = pageNumber-2;
			lastPageTracked = pageNumber+2;
        }
        
		component.set("v.pageList", pageList);
		component.set("v.firstPageTracked", firstPageTracked);
        component.set("v.lastPageTracked", lastPageTracked);
	},
	
	resetListParameters : function(component) {
        component.set('v.firstContactId', '');
        component.set('v.lastContactId', '');
        component.set('v.firstSortedValue', '');
        component.set('v.lastSortedValue', '');
        component.set("v.currentPageNumber",1);
    }, 
})