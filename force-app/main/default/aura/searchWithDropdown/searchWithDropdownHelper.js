({
    clearStateValues:function(component)
    {
        component.set('v.searchText', '');
        component.set('v.listResults', null);
        component.set('v.mapResults', null);
    }

    ,prepopulateSearch: function(component, searchId)
    {

        var fieldsToReturn = component.get('v.fieldsToReturn');
        var objectAPIName = component.get('v.objectAPIName');
        var mapWhereFieldsAndValues = this.parseWhereFieldsAndValues(component);

        var objParams = {
          'fieldsToReturn': fieldsToReturn
          , 'objectAPIName':objectAPIName
          , 'searchId': searchId          
          , "whereFields": mapWhereFieldsAndValues.whereFields
          , "whereValues": mapWhereFieldsAndValues.whereValues
        };

        //console.error('prepopulateSearch:' + searchId);
        var objDebug = {
            "fieldsToReturn": fieldsToReturn
            , "objectAPIName": objectAPIName
            , "whereFields": ['Id']
            , "whereValues": [searchId]
            , "optionalWhereFields": []
            , "searchFields": []
            , "searchText": ''
        };
        //this.getSqlString(component,objDebug);

        var action = component.get('c.searchForPrepopulation');
        action.setParams(objParams);
        action.setCallback(this, function(response) {
            console.log('prepopulateSearch:' + response.getState());
            if (response.getState() == "SUCCESS") {

                //store the return response from server (List<Object>)
                var objResponse = response.getReturnValue();
                if(objResponse)
                {

                    var labelField = component.get('v.labelField');
                    component.set('v.searchText', objResponse[labelField]);
                    //console.debug('prepopulated label = ' + objResponse[labelField]);
                }
            }
        });
        $A.enqueueAction(action);
    }
	, searchFor : function(component, searchText) {


		var fieldsToReturn = component.get('v.fieldsToReturn');
        var objectAPIName = component.get('v.objectAPIName');

        // validate which fields and values to pass to apex
        var mapWhereFieldsAndValues = this.parseWhereFieldsAndValues(component);
        var optionalWhereFields = component.get('v.optionalWhereFields');

        var searchFields = component.get('v.searchFields');

        // call apex SOQL
		var objParams = {
            "fieldsToReturn": fieldsToReturn
            , "objectAPIName": objectAPIName
            , "whereFields": mapWhereFieldsAndValues.whereFields
            , "whereValues": mapWhereFieldsAndValues.whereValues
            , "optionalWhereFields": optionalWhereFields
            , "searchFields": searchFields
            , "searchText": searchText
        };

        /*** Debugging the SQL */
        //this.getSqlString(component,objParams);

		var labelField = component.get('v.labelField');
        var action = component.get('c.getSearchResults');
		action.setParams(objParams);
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {

                //store the return response from server (List<Object>)
                var arrResponse = response.getReturnValue();

                var iLen = 0;
                if(arrResponse)
                    iLen = arrResponse.length;

                // a map of the results, since we cannot store a the selected value as the record
                var mapResults = {};

                // add a default blank
                var arrOptions = [];
                arrOptions.push({
                    value:''
                    , label:'Found ' + iLen + ' results'
                });
                for(var i = 0; i < iLen; ++i)
                {
                    // get the sobject record
                    var objOption = arrResponse[i];

                    //console.log(objOption.Id + ':' + objOption[labelField]);
                    var mapOption = {
                        value:objOption.Id,
                        label:objOption[labelField]
                    };
                    arrOptions.push(mapOption);

                    // add to the results map
                    mapResults[objOption.Id] = objOption;
                }
                component.set('v.listResults', arrOptions);
                component.set('v.mapResults', mapResults);
                component.set('v.state', 'RESULTS');
            }
            else if (response.getState() === 'ERROR'){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error(errors[0].message);
                    }
                }
            }
        });

        $A.enqueueAction(action);

	}

    /**
     * Logic to compute which fields and values to apex soql
     */
	, parseWhereFieldsAndValues: function (component)
    {

        // an array of fields for the WHERE clause
        var whereFields = component.get('v.whereFields');

        var whereValues = [];
        var validWhereFields = [];

        // loop through the number of supplied fields
        var iWhereLen = whereFields.length;
        for(var i = 0; i < iWhereLen; ++i)
        {
            var attrName = 'v.whereValue' + i;
            var whereVal = component.get(attrName);
            if(whereVal) {
                validWhereFields.push(whereFields[i]);
                whereValues.push(whereVal);
            }
            else {
                console.error('SearchWithDropdownHelper:: no value for field:' + whereFields[i]);
            }
        }

        return {whereFields:validWhereFields, whereValues:whereValues};
    }

	, getSqlString: function(component, objParams) {

        var action = component.get('c.getQueryString');
        action.setParams(objParams);

        console.debug('SearchWithDropdown:: objParams = {');
        for(var k in objParams)
        {
            console.debug(k + ':' + objParams[k]);
        }
        console.debug('}');

        action.setCallback(this, function(response) {
            console.debug('SearchWithDropdown:: Response State: ' + response.getState());
            console.debug('SearchWithDropdown:: Response Value: ' + response.getReturnValue());
            if(response.getState() == 'ERROR')
            {
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error(errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }


})