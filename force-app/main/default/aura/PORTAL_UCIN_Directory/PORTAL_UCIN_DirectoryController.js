({
    /*
     * This finction defined column header
     * and calls getAccounts helper method for column data
     * editable:'true' will make the column editable
     * */
	doInit : function(component, event, helper) {
        component.set('v.columns', [
 			{label: 'First Name', fieldName: 'FirstName', type: 'url', sortable:true,
            		typeAttributes: {label: { fieldName: 'FirstName' }, target: '_parent'}},
 			{label: 'Last Name', fieldName: 'LastName', type: 'url', sortable:true,
            		typeAttributes: {label: { fieldName: 'LastName' }, target: '_parent'}}
        ]);

        //helper.getContacts(component, helper, 0, false);
        helper.getLoggedInContact(component, helper);
    },

    onNext : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");

        helper.getContacts(component, helper, 0, false);
        component.set("v.currentPageNumber", pageNumber+1);
        helper.buildData(component, helper);
    },
    
    onPrev : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");

        helper.getContacts(component, helper, 0, true);
        component.set("v.currentPageNumber", pageNumber-1);
        helper.buildData(component, helper);
    },
    
    processMe : function(component, event, helper) {
        var currentPageNumber = component.get("v.currentPageNumber");
        var selectedPageNumber = parseInt(event.target.name);
        var itemsPerPage = component.get("v.pageSize");
        var reverseList = false;

        var offset = (selectedPageNumber - currentPageNumber) * itemsPerPage;

        if (offset == 0) {
            return;
        }

        if (offset < 0) {
            offset = (offset * -1);
            reverseList = true;
        }

        // Need to correct offset to start at correct place
        offset = offset - itemsPerPage;

        helper.getContacts(component, helper, offset, reverseList);

        component.set("v.currentPageNumber", selectedPageNumber);
        helper.buildData(component, helper);
    },
    
    onFirst : function(component, event, helper) {        
        helper.resetListParameters(component);
        helper.getContacts(component, helper, 0, false);
        component.set("v.currentPageNumber", 1);
        helper.buildData(component, helper);
    },
    
    onLast : function(component, event, helper) {   
        helper.resetListParameters(component);
        helper.getContacts(component, helper, 0, true);
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.buildData(component, helper);
    },

    // Client-side controller called by the onsort event handler
    updateColumnSorting: function (component, event, helper) {
        //var fieldName = event.getParam('fieldName');
        //var sortDirection = event.getParam('sortDirection');

        var src = event.getSource();
        var fieldName = src.getLocalId();
        var sortDirection = component.get("v.sortDirection");
        
        if (sortDirection == "asc") {
            sortDirection = "desc";
        } else {
            sortDirection = "asc";
        }

        helper.resetListParameters(component);
        component.set('v.sortDirection', sortDirection);
        component.set('v.sortedByApiName', fieldName);
        helper.getContacts(component, helper, 0, false);
    },

    openProfileModal : function(component, event, helper) {
        component.set("v.loaded", false);

        $A.createComponent("c:PORTAL_UCIN_DirectoryModal", 
            {
                contactId: event.target.id,
                loggedInContactId: component.get("v.loggedInContactId")
            }, 
            function(content, status) {
                if(status ==="SUCCESS") {
                    component.find('overlayLib').showCustomModal({
                        body:content,
                        showCloseButton: false,
                        closeCallback: function() {

                        }
                    });
                } else {
                   // console.log("ERROR");
                }
                component.set("v.loaded", true);
            }
        );
    },

    openMessagingModal: function(component, event, helper) {
        component.set("v.loaded", false);
        $A.createComponent("c:PORTAL_UCIN_Messaging", 
            {
                contactId: event.target.id                
            }, 
            function(content, status) {
                if(status ==="SUCCESS") {
                    component.find('overlayLib').showCustomModal({
                        body:content,
                        showCloseButton: false,
                        closeCallback: function() {

                        }
                    });
                } else {
                    //console.log("ERROR");
                }
                component.set("v.loaded", true);
            }
        );
    },

    handleFilterSearchTextChange: function(component, event, helper) {
        let searchTimeout = component.get("v.searchTimer");
        if(searchTimeout) {
            clearTimeout(searchTimeout);
        }
        searchTimeout = window.setTimeout(
            $A.getCallback(() => {
                helper.resetListParameters(component);
                helper.getContacts(component, helper, 0, false, '');

                component.set("v.searchTimer", null);
            }), 500  
        );
        component.set("v.searchTimer", searchTimeout);
    },

    handleSearchForChange: function (component, event, helper) {
        var filterSearchText = component.get("v.filterSearchText");
        var searchForSelected = component.get("v.searchForSelected");
        if (filterSearchText != undefined && filterSearchText != "") {
            component.set("v.filterSearchText", '');
        } else if (searchForSelected == 'All') {
            helper.resetListParameters(component);
            //helper.getContacts(component, helper, 0, false, '');
        }
    },

    handleSearchTextChange: function(component, event, helper) {
        let searchTimeout = component.get("v.searchTimer");
        if(searchTimeout) {
            clearTimeout(searchTimeout);
        }
        searchTimeout = window.setTimeout(
            $A.getCallback(() => {
                helper.resetListParameters(component);
                helper.getContacts(component, helper, 0, false, '');

                component.set("v.searchTimer", null);
            }), 500  
        );
        component.set("v.searchTimer", searchTimeout);
    },

    executeSearch: function(component, event, helper) {
        helper.resetListParameters(component);
        helper.getContacts(component, helper, 0, false, '');
    }

})