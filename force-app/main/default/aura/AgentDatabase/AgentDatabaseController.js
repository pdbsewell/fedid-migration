({
    fireSearchEvent : function(component, event, helper) {
        
        console.log("inside AgentDatabaseController.js fireSearchEvent");
        var appEvent = $A.get("e.c:searchAgenciesInitiated");
        appEvent.setParams({"searchCriteria" : component.get("v.searchString")});
        appEvent.fire();
        
    },
    
    resetSearchString : function(component, event, helper) {
        
        console.log("inside AgentDatabaseController.js resetSearchString");
        component.set("v.searchString", "");
        
    },
    
    fireResetEvent : function(component, event, helper) {
        
        console.log("inside AgentDatabaseController.js fireResetEvent");
        component.set("v.searchString", "--blank--");
        component.set("v.countrySelected", "default");
        
        var appEvent = $A.get("e.c:resetInitiated");
        appEvent.fire();
        
    },
    
    fireCountryFilterEvent : function(component, event, helper) {
        
        console.log("inside AgentDatabaseController.js fireCountryFilterEvent");
        var selectedOptionValue = event.getParam("value");
        console.log(selectedOptionValue);
        
        if (selectedOptionValue != "default") {
            var appEvent = $A.get("e.c:filterAgencyByCountry");
            appEvent.setParams({"selectedCountry" : selectedOptionValue});
            appEvent.fire();
        }
    },
    
    doInitCountries : function (component, event, helper) {
        
        console.log("inside AgentDatabaseController.js doInitCountries");
        
        var action = component.get("c.getAllCountries");
        action.setCallback(this, function(response){
            var allCountries = [];
            
            var defaultValue = {"label" : "Select country or region", "value" : "default"};
            allCountries.push(defaultValue);
            
            var retVal = response.getReturnValue();
            for (var i = 0, len = retVal.length; i < len; i++) {
                var country = {
                    "label": retVal[i].ShippingCountry,
                    "value": retVal[i].ShippingCountry
                };
                allCountries.push(country);
            }
            component.set("v.countries", allCountries);
            component.set("v.loaded", true);
        });
        
        $A.enqueueAction(action);
        
    },

    doResetCountryDropdown : function (component, event, helper) {

        component.set("v.countrySelected", "default");
        component.set("v.searchString", "--blank--");

    }
    
})