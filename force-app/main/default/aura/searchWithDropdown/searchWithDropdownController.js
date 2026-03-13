({

    doInit : function(component, event, helper) {

    }

    , prePopulate: function(component, event, helper) {

    	var idPrePopulated = component.get('v.selectedResult');

    	// search by id and populate
		helper.prepopulateSearch(component, idPrePopulated);
	}

	,doSearch : function(component, event, helper) {
    	component.set('v.selectedResult', null);
        component.set('v.state', 'IDLE');
		var searchText = component.get('v.searchText');

		if(searchText.length < 1)
		{
			// early out
			return;
		}

        helper.searchFor(component, searchText);
	}

	,clearFields:function(component, event, helper)
	{
		helper.clearStateValues(component);
        component.set('v.state', 'IDLE');
	}

	, onSelectedResult : function(component, event, helper)
    {
    	// get the id of the selected record
    	var selectedValue = component.get('v.selectedResult');

    	// get the label of the selected option, since the value is an object
        var mapResults = component.get('v.mapResults');
		var objSelected = mapResults[selectedValue];

        var labelField = component.get('v.labelField');
		var selectedLabel = objSelected[labelField];

		// input field is now the selected label
		component.set('v.searchText', selectedLabel);

		// fire the event
		var evtSearch = component.getEvent("onSearchSelectEvent");
		evtSearch.setParams({
			"sObject":objSelected
		});
		evtSearch.fire();
    }
})