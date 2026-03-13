({
    /**
     * Perform the SObject search via an Apex Controller
     */
    doSearch : function(cmp, event) {
        console.log("running search...");
        var lookupListItems = cmp.find("lookuplist-items");
        lookupListItems.set('v.body', new Array());
        // Get the search string, input element and the selection container
        var searchString = cmp.get("v.searchString");
        var inputElement = cmp.find('lookup');
        var lookupList = cmp.find("lookuplist");
        var searchHelp = cmp.find("searchHelp");
        
        var selectedState = cmp.get("v.selectedStateNEW");
        var selectedCountry = cmp.get("v.selectedCountryNEW");
        // Clear any errors and destroy the old lookup items container
        inputElement.set('v.errors', null);
        
        // We need at least 3 characters for an effective search
        if (typeof searchString === 'undefined' || searchString.length < 3)
        {
            // Hide the lookuplist
            $A.util.addClass(lookupList, 'slds-hide');
            $A.util.addClass(searchHelp, 'slds-hide');
            return;
        }
 
        // Show the lookuplist
        $A.util.removeClass(lookupList, 'slds-hide');
        $A.util.removeClass(cmp.find("searchHelp"), 'slds-hide');

        // Hide the Input Element
        var listItem = cmp.find('lookupSearch');
        $A.util.removeClass(listItem, 'slds-hide');
 
        // Get the API Name
        var sObjectAPIName = cmp.get('v.sObjectAPIName');
 
        // Create an Apex action
        //var action = cmp.get("c.lookup");
        var action = cmp.get("c.lookupWithRecordType");
        var recordTypeToUse = cmp.get('v.recordTypeToUse');
 
        // Mark the action as abortable, this is to prevent multiple events from the keyup executing
        action.setAbortable();
        
        // Set the parameters
        action.setParams({ "searchString" : searchString, "sObjectAPIName" : sObjectAPIName, "recordTypeSelected" : recordTypeToUse, "selectedState" : selectedState, "selectedCountry" : selectedCountry});
        //action.setParams({ "searchString" : searchString, "sObjectAPIName" : sObjectAPIName });

        // Define the callback
        action.setCallback(this, function(response) {
            var state = response.getState();
            // Callback succeeded
            if (cmp.isValid() && state === "SUCCESS")
            {
                
                // Get the search matches
                var matches = response.getReturnValue();
                
                // If we have no matches, return
                if (matches.length == 0)
                {
                    return;
                }
                
                // Render the results
                this.renderLookupComponents(cmp, lookupListItems, matches);
            }
            else if (state === "ERROR") // Handle any error by reporting it
            {
                var errors = response.getError();
                 
                if (errors) 
                {
                    if (errors[0] && errors[0].message) 
                    {
                        this.displayToast('Error', errors[0].message);
                    }
                }
                else
                {
                    this.displayToast('Error', 'Unknown error.');
                }
            }
        });
         
        // Enqueue the action                  
        $A.enqueueAction(action);                
    },
 
    /**
     * Render the Lookup List Components
     */   
    renderLookupComponents : function(cmp, lookupListItems, matches)
    {
        lookupListItems.set('v.body', new Array());
        // list Icon SVG Path and Class
        var listIconSVGPath = cmp.get('v.listIconSVGPath');
        var listIconClass = cmp.get('v.listIconClass');
        
        // Array of components to create
        var newComponents = new Array();
        
        // Add a set of components for each match found
        for (var i=0; i<matches.length; i++)
        {
            // li element
            newComponents.push(["aura:html", {
                "tag" : "li",
                "HTMLAttributes" : {
                    "class" : "slds-lookup__item"
                }
            }]);
 
            // a element
            newComponents.push(["aura:html", {
                "tag" : "a",
                "HTMLAttributes" : { 
                    "id" : cmp.getGlobalId() + '_id_' + matches[i].SObjectId, 
                    "role" : "option", 
                    "onclick" : cmp.getReference("c.select") 
                }
            }]);
 
            // svg component
            newComponents.push(["c:svg", {
                "class" : "slds-icon " + listIconClass + " slds-icon--small",
                "xlinkHref" : listIconSVGPath
            }]);
 
            // output text component
            // For some reason adding an aura:id to this component failed to record the id for subsequent cmp.find requests
            newComponents.push(["ui:outputText", {
                "value" : matches[i].SObjectLabel
            }]);
        }
        
 
        // Create the components
        $A.createComponents(newComponents, function(components, status) {
            // Creation succeeded
            if (status === "SUCCESS")
            {
                // Get the List Component Body
                var lookupListItemsBody = lookupListItems.get('v.body');
                
                // Iterate the created components in groups of 4, correctly parent them and add them to the list body
                for (var i=0; i<components.length; i+=4)
                {
                    // Identify the releated components
                    var li = components[i];
                    var a = components[i+1];
                    var svg = components[i+2];
                    var outputText = components[i+3];
 
                    // Add the <a> to the <li>
                    var liBody = li.get('v.body');
                    liBody.push(a);
                    li.set('v.body', liBody);
 
                    // Add the <svg> and <outputText> to the <a>
                    var aBody = a.get('v.body');
                    aBody.push(svg);
                    aBody.push(outputText);
                    a.set('v.body', aBody);
 
                    // Add the <li> to the container
                    lookupListItemsBody.push(li);
                }
                // Update the list body
                lookupListItems.set('v.body', lookupListItemsBody);
           }
           else // Report any error
           {
                this.displayToast('Error', 'Failed to create list components.');
           }
        });
 
    },
 
    /**
     * Handle the Selection of an Item
     */
    handleSelection : function(cmp, event) {
        // Resolve the Object Id from the events Element Id (this will be the <a> tag)
        var objectId = this.resolveId(event.currentTarget.id);
 
        // The Object label is the 2nd child (index 1)
        var objectLabel = event.currentTarget.children[1].innerText;
 
        // Log the Object Id and Label to the console
        console.log('objectId=' + objectId);
        cmp.set("v.selectedObjectId", objectId);
        //console.log('objectLabel=' + objectLabel);
                 
        // Create the UpdateLookupId event
        var updateEvent = cmp.getEvent("updateLookupIdEvent");
        
        // Populate the event with the selected Object Id
        updateEvent.setParams({
            "sObjectId" : objectId
        });
        
        // Fire the event
        updateEvent.fire();
        
        // Update the Searchstring with the Label
        cmp.set("v.searchString", objectLabel);
        cmp.set("v.showLabel", true);
        var lookupError = cmp.find("lookupError");
        lookupError.set("v.errors", null);

        //component.set("v.hasSelected", true);
        // Hide the Input Element
        var inputElement = cmp.find('lookup');
        $A.util.addClass(inputElement, 'slds-hide');
        
        // Show the Lookup pill
        var lookupPill = cmp.find("lookup-pill");
        $A.util.removeClass(lookupPill, 'slds-hide');

        // Hide the Input Element
        var listItem = cmp.find('lookupSearch');
        $A.util.addClass(listItem, 'slds-hide');

        // Lookup Div has selection
        var inputElement = cmp.find('lookup-div');
        $A.util.addClass(inputElement, 'slds-has-selection');
        
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         5.Jul.2017         
    * @description  prepopulate the lookup if the variable is populated on load
    * @revision     
    *******************************************************************************/
    prepopulateLookup : function (component, event) {
        //only run if the selected code is not null/blank
        var selectedCode = component.get("v.selectedCode");
        var selectedQualId = component.get("v.selectedQualId");
        // Create the UpdateLookupId event
        var updateEvent = component.getEvent("updateLookupIdEvent");
        if (selectedCode != null && selectedCode != '') {
            var action = component.get("c.retrieveInstitutionIdByCode");
            action.setParams({  "insCode"   : selectedCode,
                                "insName"   : component.get('v.selectedLabel') });
            action.setCallback(this, function(a) {
                var objectId = a.getReturnValue();
                // Populate the event with the selected Object Id
                updateEvent.setParams({
                    "sObjectId" : objectId
                });
                // Fire the event
                updateEvent.fire();

                this.displaySelectedValue(component);
            });
            $A.enqueueAction(action);
            component.set("v.showLabel", true);
        } 

        if (selectedQualId != null && selectedQualId != '') {
            // Populate the event with the selected Object Id
            updateEvent.setParams({
                "sObjectId" : selectedQualId
            });
            // Fire the event
            updateEvent.fire();

            this.displaySelectedValue(component);
            component.set("v.showLabel", true);
        }

        //clear lookup
        var lookupError = component.find("lookupError");
        lookupError.set("v.errors", null);
    },
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         6.Jul.2017         
    * @description  sets the value on the front end
    * @revision     
    *******************************************************************************/
    displaySelectedValue : function (component) {
        // Update the Searchstring with the Label
        component.set("v.searchString", component.get("v.selectedLabel"));
        
        //component.set("v.hasSelected", true);
        // Lookup Div has selection
        var lookupDiv = component.find('lookup-div');
        $A.util.addClass(lookupDiv, 'slds-has-selection');
        
        // Hide the Input Element
        var inputElement = component.find('lookup');
        $A.util.addClass(inputElement, 'slds-hide');
        
        // Show the Lookup pill
        var lookupPill = component.find("lookup-pill");
        $A.util.removeClass(lookupPill, 'slds-hide');
        
        // Hide the Input Element
        var listItem = component.find('lookupSearch');
        $A.util.addClass(listItem, 'slds-hide');
    },
 
    /**
     * Clear the Selection
     */
    clearSelection : function(cmp) {
        // Create the ClearLookupId event
        var clearEvent = cmp.getEvent("clearLookupIdEvent");
        
        if (cmp.get("v.selectedQualId") != null && cmp.get("v.selectedQualId") != '') {
            var objectId = cmp.get("v.selectedQualId");
            // Populate the event with the selected Object Id
            clearEvent.setParams({
                "sObjectId" : objectId
            });

            // Fire the event
            clearEvent.fire();
        } else {
            var selectedCode = cmp.get("v.selectedCode");
            if (selectedCode != null && selectedCode != '') {
                var action = cmp.get("c.retrieveInstitutionIdByCode");
                action.setParams({  "insCode"   : selectedCode,
                                    "insName"   : cmp.get('v.selectedLabel') });
                action.setCallback(this, function(a) {
                    var objectId = a.getReturnValue();
                    // Populate the event with the selected Object Id
                    clearEvent.setParams({
                        "sObjectId" : objectId
                    });

                    // Fire the event
                    clearEvent.fire();
                });
                $A.enqueueAction(action);
            } else {
                var objectId = cmp.get("v.selectedObjectId");
                clearEvent.setParams({
                    "sObjectId" : objectId
                });

                // Fire the event
                clearEvent.fire();
            }
        }
        
        // Clear the Searchstring
        cmp.set("v.searchString", '');
        
        //component.set("v.hasSelected", false);
        // Show the Input Element
        var inputElement = cmp.find('lookup');
        $A.util.removeClass(inputElement, 'slds-hide');

        // Hide the Lookup pill
        var lookupPill = cmp.find("lookup-pill");
        $A.util.addClass(lookupPill, 'slds-hide');

        var listItem = cmp.find('lookupSearch');
        $A.util.addClass(listItem, 'slds-hide');

        // Lookup Div has no selection
        var inputElement = cmp.find('lookup-div');
        $A.util.removeClass(inputElement, 'slds-has-selection');

        cmp.set("v.showLabel", false);
        var lookupError = cmp.find("lookupError");
        lookupError.set("v.errors", null);
        $A.util.removeClass(cmp.find("lookup"), 'has-errors');
    },
 
    /**
     * Resolve the Object Id from the Element Id by splitting the id at the _
     */
    resolveId : function(elmId)
    {
        var i = elmId.lastIndexOf('_');
        return elmId.substr(i+1);
    },
 
    /**
     * Display a message
     */
    displayToast : function (title, message) 
    {
        var toast = $A.get("e.force:showToast");
 
        // For lightning1 show the toast
        if (toast)
        {
            //fire the toast event in Salesforce1
            toast.setParams({
                "title": title,
                "message": message
            });
 
            toast.fire();
        }
        else // otherwise throw an alert
        {
            alert(title + ': ' + message);
        }
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Jul.2017         
    * @description  adds an error message to the lookup
    * @revision     
    *******************************************************************************/
    addErrorMsg: function(component) {
        var lookup = component.find("lookupError");
        if (component.get("v.lookupErrorMsg") != '' && component.get("v.lookupErrorMsg") != null) {
            lookup.set("v.errors", [{message: component.get("v.lookupErrorMsg")}]);
            $A.util.addClass(component.find("lookup"), 'has-errors');
        } else {
            $A.util.removeClass(component.find("lookup"), 'has-errors');
            lookup.set("v.errors", null);
        }
    },
})