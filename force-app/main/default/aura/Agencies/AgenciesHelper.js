({
	getPage : function(component, event) {

        var pageSize = component.get("v.pageSize");
        var page = component.get("v.page");

        switch (component.get("v.displayMode")) {
            case 1:
                // all
                var action = component.get("c.getAllAgenciesWithPagination");
                action.setParams({"pageNumber": page || 1});
                break;
            case 2:
                // filter by country
                var action = component.get("c.searchAgenciesByCountryWithPagination");
                var selectedCountry = component.get("v.countryOfChoice")
                action.setParams({"chosenCountry": selectedCountry, "pageNumber": page || 1});
                break;
            case 3:
                // filter by 1st character
                var action = component.get("c.searchAgenciesBy1stAlphabetWithPagination");
                var alphabetChosen = component.get("v.firstChar");
                action.setParams({"chosenLetter": alphabetChosen, "pageNumber": page || 1});
                break;
            case 4:
                // SOSL search
                var action = component.get("c.searchAgenciesWithPagination");
                var searchClause = component.get("v.soslSearchTerm");
                action.setParams({"searchTerm": searchClause, "pageNumber": page || 1});
                break;
        }

        action.setCallback(this, function(response){

            var result  = response.getReturnValue();

            component.set("v.loaded", true);
            component.set("v.allAgencies", result.agencies);
            component.set("v.page", result.page);
            component.set("v.total", result.total);
            component.set("v.pages", Math.ceil(result.total/result.pageSize));
            if (result.total == 0) {
                component.set("v.displayBottomPaginator", false);
            } else {
                component.set("v.displayBottomPaginator", true);
            }

        });
        
        $A.enqueueAction(action);

	}
})