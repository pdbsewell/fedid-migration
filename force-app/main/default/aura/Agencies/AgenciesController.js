({
    doInit : function(component, event, helper) {
        
        console.log("inside AgenciesController.js doInit");

        component.set("v.loaded", false);
        component.set("v.displayMode", 1);
        component.set("v.page", 1);
        helper.getPage(component, event);

    },
    
    doSearch : function(component, event, helper) {
        
        console.log("inside AgenciesController.js doSearch");

        component.set("v.loaded", false);
        component.set("v.displayMode", 4);
        component.set("v.page", 1);
        component.set("v.soslSearchTerm", event.getParam("searchCriteria"));

        helper.getPage(component, event);

    },
    
    doCountryFilter : function(component, event, helper) {
        
        console.log("inside AgenciesController.js doCountryFilter");

        component.set("v.loaded", false);
        component.set("v.displayMode", 2);
        component.set("v.page", 1);
        component.set("v.countryOfChoice", event.getParam("selectedCountry"));
        helper.getPage(component, event);

    },
    
    doSearchBy1stAlphabet : function(component, event, helper) {
        
        console.log("inside AgenciesController.js doSearchBy1stAlphabet");

        var alphabetChosen = event.getParam("alphabetChosen");
        component.set("v.loaded", false);
        component.set("v.displayMode", 3);
        component.set("v.page", 1);
        component.set("v.firstChar", alphabetChosen);
        helper.getPage(component, event);

    },
    
    onPagePrevious : function (component, event, helper) {

        console.log("inside AgenciesController.js onPageNext, and page = " + page);

        var page = component.get("v.page") || 1;
        page = page - 1;
        component.set("v.page", page);
        component.set("v.loaded", false);
        helper.getPage(component, event);

    },
    
    onPageNext : function (component, event, helper) {

        console.log("inside AgenciesController.js onPageNext, and page = " + page);

        var page = component.get("v.page") || 1;
        page = page + 1;
        component.set("v.page", page);
        component.set("v.loaded", false);
        helper.getPage(component, event);
        
    }
    
})