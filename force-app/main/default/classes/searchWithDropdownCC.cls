/**
 * @description       : Controller class for aura component searchWithDropdownCC
 * @author            : ???
 * @group             : Services
 * @last modified on  : 2021-02-04
 * @last modified by  : Kristian Vegerano
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2021-02-04 - Kristian Vegerano - Made without sharing to enable my.app user to attach the monash abroad applications to a university (current institution)
 */
public with sharing class searchWithDropdownCC {
    private static Integer MAX_RESULTS_LIMIT = 50;
    @AuraEnabled
    public static List<Object> getSearchResults(List<String> fieldsToReturn,
            String objectAPIName,
            List<String> whereFields,
            List<String> whereValues,
            List<String> optionalWhereFields,
            List<String> searchFields,
            String searchText)
    {

        String sQuery = getQueryString(fieldsToReturn,
                objectAPIName,
                whereFields,
                whereValues,
                optionalWhereFields,
                searchFields,
                searchText);

        List<object> listResults;
        listResults = Database.query(sQuery);

        return listResults;
    }

    /**
     * Construct the query string, useful for debugging any errors when implemented
     *
     * @return
     */
    @AuraEnabled
    public static String getQueryString(List<String> fieldsToReturn,
            String objectAPIName,
            List<String> whereFields,
            List<String> whereValues,
            List<String> optionalWhereFields,
            List<String> searchFields,
            String searchText)
    {
        Set<String> setFieldsToReturn = new Set<String> ();

        // fields to return
        for(String strField : fieldsToReturn)
        {
            setFieldsToReturn.add(String.escapeSingleQuotes(strField));
        }

        // where conditions
        String sWhere = '';
        Integer iWhereFields = whereFields.size();
        for(Integer iWhere = 0; iWhere < iWhereFields; ++iWhere)
        {
            if(iWhere != 0)
                sWhere += ' AND ';

            // do not do not add quotes for integer and booleans
            String sValue = whereValues[iWhere];
            String sDelim = '\'';
            if(sValue.isNumeric() || sValue=='true' || sValue =='false')
            {
                sDelim = '';
            }

            // if it's an optional field, need to add an or clause
            String sField = whereFields[iWhere];
            if(optionalWhereFields.indexOf(sField) >= 0)
            {
                sWhere += '(' + String.escapeSingleQuotes(sField) + '=NULL OR ';
                sWhere +=  String.escapeSingleQuotes(sField) + '=' + sDelim + String.escapeSingleQuotes(sValue) + sDelim;
                sWhere += ')';
            }
            else
            {
                // SFTG-2480 Included to handle NOT logic & LIKE comparison scenarios; 
                // Prefix where Fields names in the component with ! (for NOT) and % (for LIKE) in this order
                // example: whereFields="['Overseas__c','RecordType.Name', '!%Qualification_Name__c']"
                Boolean isLikeComparison = false;
                Boolean isNOTLogic = false;
                if (sField.startsWith('!')) { 
                    isNOTLogic = true;
                    sField = sField.removeStart('!');
                } 
                if (sField.startsWith('%')) { 
                    isLikeComparison = true;
                    sField = sField.removeStart('%');
                }
                if (isLikeComparison) {
                    if (isNOTLogic){
                        sWhere +=  '( NOT ' + String.escapeSingleQuotes(sField) + ' LIKE \'%' + String.escapeSingleQuotes(sValue) + '%\')';
                    } else {
                        sWhere +=  '(' + String.escapeSingleQuotes(sField) + ' LIKE \'%' + String.escapeSingleQuotes(sValue) + '%\')';
                    }
                } else {
                    if (isNOTLogic){
                        sWhere +=  String.escapeSingleQuotes(sField) + '!=' + sDelim + String.escapeSingleQuotes(sValue) + sDelim;
                    } else {
                        sWhere +=  String.escapeSingleQuotes(sField) + '=' + sDelim + String.escapeSingleQuotes(sValue) + sDelim;
                    }
                }
            }
        }

        // like clause
        String sSearch = '';
        Integer iSearchFields = searchFields.size();
        for(Integer iSearch = 0; iSearch < iSearchFields; ++iSearch)
        {
            if(iSearch != 0)
                sSearch += ' OR ';
            sSearch += String.escapeSingleQuotes(searchFields[iSearch]) + ' LIKE \'%' + String.escapeSingleQuotes(searchText) + '%\'';
        }
        String orderByClause = '';
        if(sSearch != '') {
            sWhere += ' AND (' + sSearch + ')';

            // order by the first search field
            orderByClause = ' ORDER BY ' + String.escapeSingleQuotes(searchFields[0]);
        }

        String dynamicSOQL = DynamicSoqlBuilder.getInstance()   
                    .showSOQLStatement(true)
                    .setEnforced(true)
                    .querySObject(String.escapeSingleQuotes(objectAPIName))
                    .queryFields(setFieldsToReturn)
                    .getQuery(sWhere);
        // limit results
        String limitClause = ' LIMIT ' + MAX_RESULTS_LIMIT;

        // final query
        String strQuery = dynamicSOQL.remove('\\') + orderByClause + limitClause; 
        System.debug('query = ' + strQuery );

        return strQuery;
    }


    @AuraEnabled
    public static Object searchForPrepopulation(List<String> fieldsToReturn, String objectAPIName, Id searchId, List<String> whereFields, List<String> whereValues)
    {
        whereFields.add('Id');        
        whereValues.add(searchId);

        String[] arrEmpty = new String[]{};
        String sQuery = getQueryString(fieldsToReturn, objectAPIName,whereFields, whereValues, arrEmpty, arrEmpty, '');

        List<object> listResults;
        listResults = Database.query(sQuery);

        if(listResults.size() == 1)
            return listResults[0];
        return null;
    }
}