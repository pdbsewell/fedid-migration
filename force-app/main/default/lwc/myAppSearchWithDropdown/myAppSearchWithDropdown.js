import { LightningElement, api, track } from "lwc";
import searchForPrepopulation from "@salesforce/apex/searchWithDropdownCC.searchForPrepopulation";
import getSearchResults from "@salesforce/apex/searchWithDropdownCC.getSearchResults";

export default class MyAppSearchWithDropdownHelper extends LightningElement {
    @api recordId = null;

    /* STATES:
        true = IDLE = not searching
        false = RESULTS = populated results
    */
    @track disable = true;
    
    //user input
    @api searchText;
    @api selectedResult;

    //output
    @api listResults = [];
    @api mapResults = null;
    @api labelField;
    @api placeHolder = "start typing to search";
    @api inputVariant = "standard";
    @api errorPlaceHolder;

    // variables from parent
    @api objectApiName;
    @api fieldsToReturn = [];
    @track required = true;

    @api inputLabel;
    // where fields from parent input
    @api whereFields = [];
    @api whereValue0;
    @api whereValue1;
    @api whereValue2;
    @api whereValue3;

    @api optionalWhereFields = [];

    // which field to search on from input
    @api searchFields = [];

    @api otherSearchText

    connectedCallback() {
        if(this.otherSearchText) {
           this.searchText = this.otherSearchText
        }
    }

    @api
    clearValues() {
        this.searchText = '';
        this.listResults = null;
        this.mapResults = null;
        this.disable = true;
    }

    @api
    prePopulate() {
        var searchId = this.selectedResult;

        var fieldsToReturn = this.fieldsToReturn;
        var objectApiName = this.objectApiName;
        var mapWhereFieldsAndValues = this.parseWhereFieldsAndValues();

        searchForPrepopulation({ 
            fieldsToReturn: fieldsToReturn, 
            objectAPIName: objectApiName, 
            searchId: searchId, 
            whereFields: mapWhereFieldsAndValues.whereFields, 
            whereValues: mapWhereFieldsAndValues.whereValues
        }).then(response => {
            var labelField = this.labelField;
            this.searchText = response[labelField];
        }).catch(errors => {
            if (errors) {
                console.error(errors);
            }
        })
    }

    @api
    doSearch(event) {
        this.selectedResult = null;
        this.disable = true;
        this.searchText = event.detail.value;
        var searchText = this.searchText;

        if(searchText.length < 1)
        {
            // early out
            return;
        }

        var fieldsToReturn = this.fieldsToReturn;
        var objectApiName = this.objectApiName;

        // validate which fields and values to pass to apex
        var mapWhereFieldsAndValues = this.parseWhereFieldsAndValues();
        var optionalWhereFields = this.optionalWhereFields;

        var searchFields = this.searchFields;

        var labelField = this.labelField;

        getSearchResults({
            fieldsToReturn: fieldsToReturn,
            objectAPIName: objectApiName,
            whereFields: mapWhereFieldsAndValues.whereFields,
            whereValues: mapWhereFieldsAndValues.whereValues,
            optionalWhereFields: optionalWhereFields,
            searchFields: searchFields,
            searchText: searchText
        }).then(response => {
            console.log(response);
            var arrResponse = response;

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

            for(var i = 0; i < iLen; ++i){
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
            this.listResults = arrOptions;
            this.mapResults = mapResults;
            this.disable = false;
            this.selectedResult = '';
        }).catch(errors => {
            if (errors) {
                console.error(errors);
            }
        });
    }

    // fire the event on select
    onSelectedResult(event) {
        // get the id of the selected record
        this.selectedResult = event.detail.value;
        var selectedValue = this.selectedResult;
        // get the label of the selected option, since the value is an object
        var mapResults = this.mapResults;
        var objSelected = mapResults[selectedValue];

        var labelField = this.labelField;
        var selectedLabel = objSelected[labelField];

        // input field is now the selected label
        this.searchText = selectedLabel;

        var evtSearch = new CustomEvent("searchselectevent", {
            detail: {
                sObject:objSelected
            }
        });

        this.dispatchEvent(evtSearch);
    }


    parseWhereFieldsAndValues() {

        // an array of fields for the WHERE clause
        var whereFields = JSON.parse(this.whereFields.replace(/'/g, "\""));

        var whereValues = [];
        var validWhereFields = [];

        // loop through the number of supplied fields
        var iWhereLen = whereFields.length;

        for(var i = 0; i < iWhereLen; ++i)
        {
            var whereVal;
            switch (i){
                case 0:
                    whereVal = this.whereValue0;
                    break;
                case 1:
                    whereVal = this.whereValue1;
                    break;
                case 2:
                    whereVal = this.whereValue2;
                    break;
                case 3:
                    whereVal = this.whereValue3;
                    break;
                default:
                    break;
            }
            if(whereVal) {
                validWhereFields.push(whereFields[i]);
                whereValues.push(whereVal);
            }
            else {
                console.error('SearchWithDropdownHelper:: no value for field:' + whereFields[i]);
            }
        }

        return {'whereFields':validWhereFields, 'whereValues':whereValues};
    }
}