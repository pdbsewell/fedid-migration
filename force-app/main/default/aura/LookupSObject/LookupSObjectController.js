({
    /**
     * Search an SObject for a match
     */
    search : function(cmp, event, helper) {
        helper.doSearch(cmp);        
    },
 
    /**
     * Select an SObject from a list
     */
    select: function(cmp, event, helper) {
        helper.handleSelection(cmp, event);
    },
     
    /**
     * Clear the currently selected SObject
     */
    clear: function(cmp, event, helper) {
        helper.clearSelection(cmp, event);    
    },
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of state 
    * @revision     
    *******************************************************************************/
    changeState: function(component, evt) {
        var selState = component.get("v.selectedState");
        component.set("v.selectedStateNEW", selState);
        var newState = component.get("v.selectedStateNEW");
        
    },   

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of country 
    * @revision     
    *******************************************************************************/
    changeCountry: function(component, evt) {
        var selCountry = component.get("v.selectedCountry");
        component.set("v.selectedCountryNEW", selCountry);
        var newCountry = component.get("v.selectedCountryNEW");
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         5.Jul.2017         
    * @description  retrieve the record using Id
    * @revision     
    *******************************************************************************/
    prepopulateLookup: function(component, event, helper) {
        helper.prepopulateLookup(component);
    }, 

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Jul.2017         
    * @description  retrieve the record using Id
    * @revision     
    *******************************************************************************/
    addErrorMsg: function(component, event, helper) {
        helper.addErrorMsg(component);
    }, 
})