/**
 * Apex Controller for looking up an SObject via SOSL
 */
public with sharing class LookupSObjectController {
    /**
     * Aura enabled method to search a specified SObject for a specific string
     */
    /*@AuraEnabled
    public static Result[] lookup(String searchString, String sObjectAPIName) {
        // Sanitze the input
        String sanitizedSearchString = String.escapeSingleQuotes(searchString);
        String sanitizedSObjectAPIName = String.escapeSingleQuotes(sObjectAPIName);
 
        List<Result> results = new List<Result>();
        
        String fieldString = '(id,name)';
        String fieldToShowOnSearch = 'Name';
        if (sanitizedSObjectAPIName == 'Qualification__c') {
            fieldString = '(id,name,Qualification_Name__c)';
            fieldToShowOnSearch = 'Qualification_Name__c';
        }
        // Build our SOSL query
        String searchQuery = 'FIND \'' + sanitizedSearchString + '*\' IN ALL FIELDS RETURNING ' + sanitizedSObjectAPIName + fieldString + ' Limit 50'; 
 
        // Execute the Query
        List<List<SObject>> searchList = search.query(searchQuery);
        
        // Create a list of matches to return
        for (SObject so : searchList[0])
        {
            results.add(new Result((String)so.get(fieldToShowOnSearch), so.Id));
        }
         
        return results;
    }*/

    /**
     * Aura enabled method to search a specified SObject for a specific string
     */
    @AuraEnabled
    public static Result[] lookupWithRecordType(String searchString, String sObjectAPIName, String recordTypeSelected, String selectedState, String selectedCountry) {
        system.debug('recordTypeSelected: '+ recordTypeSelected);
        // Sanitze the input
        String sanitizedSearchString = String.escapeSingleQuotes(searchString);
        String sanitizedSObjectAPIName = String.escapeSingleQuotes(sObjectAPIName);
 
        List<Result> results = new List<Result>();
        String fieldToShowOnSearch = 'Name'; 
        List<SObject> searchList;
        String queryLimit = ' LIMIT 20';

        if (sanitizedSObjectAPIName == 'Qualification__c') {
            fieldToShowOnSearch = 'Qualification_Name__c';
            String recordTypeToSearch = '= \'' + recordTypeSelected + '\'';
            String stateFilter = '';
            if (selectedState != '' && selectedState != null) {
                stateFilter = ' AND (State__c = \'' + selectedState + '\' OR State__c=\'\') ';
            }
            String countryFilter = ' AND Overseas__c = false ';
            if (selectedCountry != 'Australia' && selectedCountry != null) {
                countryFilter = ' AND Overseas__c = true ';
            }
            String searchQuery = 'SELECT Id, Name, Qualification_Name__c FROM ' + sanitizedSObjectAPIName + ' WHERE Qualification_Name__c LIKE \'%' + sanitizedSearchString + '%\' AND RecordType.Name ' + recordTypeToSearch + stateFilter + countryFilter + queryLimit; 
            searchList = database.query(searchQuery);
        } else if (sanitizedSObjectAPIName == 'Institution__c') {
            fieldToShowOnSearch = 'Institution_Name__c';
            String recordTypeToSearch = '= \'' + recordTypeSelected + '\'';
            if (recordTypeSelected == 'Secondary') {
                recordTypeToSearch = 'IN (\'Secondary\', \'OS Secondary\')';
            }
            String countryFilter = ' AND Country__c = \'Australia\' ';
            if (selectedCountry != 'Australia' && selectedCountry != null) {
                selectedCountry = selectedCountry.replaceAll('\'', '');
                countryFilter = ' AND (Country__c = \''+selectedCountry+'\' OR Country__c = \'\') ';
            }
            String stateFilter = '';
            if (selectedState != '' && selectedState != null) {
                stateFilter = ' AND State__c = \'' + selectedState + '\' ';
            }
            String searchQuery = 'SELECT Id, Institution_Code__c, Institution_Name__c FROM ' + sanitizedSObjectAPIName + ' WHERE Institution_Name__c LIKE \'%' + sanitizedSearchString + '%\' AND Type__c ' + recordTypeToSearch + countryFilter + stateFilter +  queryLimit; 
            searchList = database.query(searchQuery);
        }
        // Create a list of matches to return
        for (SObject so : searchList) {
            results.add(new Result((String)so.get(fieldToShowOnSearch), so.Id));
        }

        return results;
    }
     
    /**
     * Inner class to wrap up an SObject Label and its Id
     */
    public class Result
    {
        @AuraEnabled public String SObjectLabel {get; set;}
        @AuraEnabled public Id SObjectId {get; set;}
         
        public Result(String sObjectLabel, Id sObjectId)
        {
            this.SObjectLabel = sObjectLabel;
            this.SObjectId = sObjectId;
        }
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         5.Jul.2017         
    * @description  retrieve Institution record using the institution code
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static String retrieveInstitutionIdByCode (String insCode, String insName) {
        Institution__c instRecord = new Institution__c();
        for (Institution__c instRec: [  SELECT  Id
                                        FROM    Institution__c 
                                        WHERE   Institution_Code__c =: insCode
                                        AND     Institution_Name__c =: insName
                                        LIMIT   1 ] ) {
            instRecord = instRec;
        }
        return instRecord.Id;
    }
}