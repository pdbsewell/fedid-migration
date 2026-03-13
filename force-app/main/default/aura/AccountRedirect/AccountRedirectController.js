({
	doInit : function(component, event, helper) {
	    //Initialize variables
	    var isInConsole = true;
	    
	    //Retrieve console workspace
        var workspaceAPI = component.find('workspace');
        
        //Determine if the the user is on console or not
	    workspaceAPI.isConsoleNavigation().then(function(response) {
            isInConsole = response;

    	    //Determine if a redirection should occur
    	    var action = component.get('c.determineRedirect');
            
            //Set parameters
            action.setParams({ 
                accountId : component.get('v.recordId')
            });
            
    	    //Create a callback that is executed after the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    /* Do not do redirection when user is system admin */
                    //Initialize Variables
                    var tabMap;
                    var currentTabId;
                    
                    //Determine which record to redirect the user
                    var objectType;
                    var redirectRecordId;
                    if(response.getReturnValue() != null){
                        objectType = 'Contact';
                        redirectRecordId = response.getReturnValue();
                    }else{
                        objectType = 'Account';
                        redirectRecordId = component.get('v.recordId');
                    }
                        
                    //Execute console redirection if in console
    	            if(isInConsole){
                        //Get tab id of the opened tab
                        workspaceAPI.getFocusedTabInfo().then(function(tabResponse) {
                            currentTabId = tabResponse.tabId;
                            
                            //Focus on the opened tab for the redirected record
                            tabMap = new Map();
                        
                            //Retrieve all tabs
                            workspaceAPI.getAllTabInfo().then(function(allTabsResponse) {
                                for(var tab in allTabsResponse) {
                                    //Enter tab details - recordId : tabId
                                    if(allTabsResponse[tab].recordId != null){
                                        tabMap.set(allTabsResponse[tab].recordId, allTabsResponse[tab].tabId);
                                    }
                                }
                            })
                            .catch(function(error){
                                console.log(error);
                            });
                            
                            //Redirect UI
                            if(tabMap.get(redirectRecordId) != null){
                                workspaceAPI.focusTab({tabId : tabMap.get(redirectRecordId)});
                            }else{
                                //If there are no opened tab for the redirected record
                                //Open tab for the redirected record
                                workspaceAPI.openTab({
                                    url: '/lightning/r/' + objectType + '/' + redirectRecordId + '/view?nooverride=1',
                                    focus: true,
                                    overrideNavRules: true
                                }).then(function(openedResponse) {
                                    workspaceAPI.focusTab({tabId : openedResponse});
                                })
                                .catch(function(error) {
                                    console.log(error);
                                });
                            }
                            
                            //Close new opened tab
                            if(component.get('v.recordId') == tabResponse.recordId){
                                workspaceAPI.closeTab({tabId: currentTabId});
                            }
                        })
                        .catch(function(error) {
                            console.log(error);
                        });
    	            }else{
            	        //logic running on non-console view
            	        var navService = component.find('navService');
                        // Sets the route to /lightning/r/ object / record id /view?nooverride=1
                        var pageReference = {    
                               'type': 'standard__recordPage',
                               'attributes': {
                                   'recordId': redirectRecordId,
                                   'objectApiName': objectType,
                                   'actionName': 'view'
                               }
                        };
                        component.set('v.pageReference', pageReference);
            	    }
                }
                else if (state === 'INCOMPLETE') {
                    // do something
                }
                else if (state === 'ERROR') {
                    var errors = response.getError();
                    if(errors) {
                        if(errors[0] && errors[0].message) {
                            console.log('Error message: ' + errors[0].message);
                        }
                    }else {
                        console.log('Unknown error');
                    }
                }
            });
            
            $A.enqueueAction(action);
        })
        .catch(function(error) {
            console.log(error);
        });
	}
})