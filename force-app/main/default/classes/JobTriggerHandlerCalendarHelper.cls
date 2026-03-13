/*******************************************************************************
* @author       Nitin Khandelwal
* @date         7.June.2018
* @description  Helper class for jobtriggerhandler. It will process the records from staging calendar object to
				calendar object
* @revision     07 June 2018

*******************************************************************************/

public class JobTriggerHandlerCalendarHelper {
    private static List<jobTriggerMapping__mdt> lstFieldMapping = null;
    private static Schema.SObjectType sobType = null;

    public static void initializeJobControlRecord(Schema.SObjectType sobTypePar, List<jobTriggerMapping__mdt> lstFieldMappingPar)
    {
        lstFieldMapping = lstFieldMappingPar;
        sobType = sobTypePar;
    }

    public static void processJobControlRecord(String sUniqueId, String sObjectName, String sType)
    {
        if(lstFieldMapping ==null)
            lstFieldMapping = [SELECT Source_Field__r.QualifiedApiName, Source_Object__c, Target_Field__r.QualifiedApiName, Target_Object__r.QualifiedApiName
                                      FROM jobTriggerMapping__mdt WHERE Target_Object__r.DeveloperName =:sObjectName AND IsActive__c = true];
        if(sobType == null)
            sobType = Schema.getGlobalDescribe().get(lstFieldMapping[0].Target_Object__r.QualifiedApiName);
        String sQueryForUniqueId = getQuery(sObjectName, sUniqueId);
        List<Stg_Calendar__c> lstStaging = Database.query(sQueryForUniqueId);
        List<sObject> lstSObject = new List<sObject>();
        for(Stg_Calendar__c oStag: lstStaging)
        {
            lstSObject.add(createNewRecordFromMappingStgCalendar(oStag, sObjectName));
            oStag.Record_Status__c = 'Completed';
        }
        //Split list for insert and update of records
        Map<String,SObject> extIdMap = new Map<String,SObject>();
        for(SObject so : lstSObject) {
            extIdMap.put(String.valueOf(so.get('Calendar_Code__c')),so);
        }
        Set<String> extIdSet = extIdMap.keyset();
        String splitQuery = 'SELECT Id,Calendar_Code__c FROM '+String.valueOf(sobType) +' WHERE Calendar_Code__c in :extIdSet';
        system.debug(splitQuery);
        List<SObject> insertList = new List<SObject>();
        Map<Id,SObject> updateMap = new Map<Id,SObject>();
        Map<String,Id> queryMap = new Map<String,Id>();
        for(SObject so : database.query(splitquery)) {
            queryMap.put(String.valueOf(so.get('Calendar_Code__c')), so.Id);
        }
        for(SObject so : lstSObject) {
            Id theId = queryMap.get(String.valueOf(so.get('Calendar_Code__c')));
            if(theId != null) {
                so.Id = theId;
                updateMap.put(theId,so);
            }
            else {
                insertList.add(so);
            }
        }
        Database.SaveResult[] srStagingList = Database.update(lstStaging, false);

        // Iterate through each returned result
        for (Database.SaveResult srStag : srStagingList) {
            if (srStag.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
            }
            else {
                // Operation failed, so get all errors
                for(Database.Error err : srStag.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Staging fields that affected this error: ' + err.getFields());
                }
            }
        }
        Database.SaveResult[] srList = Database.update(updateMap.values(), false);
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
            }
            else {
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Course fields that affected this error: ' + err.getFields());
                }
            }
        }
        Database.SaveResult[] srInsertList = Database.insert(insertList, false);

        // Iterate through each returned result
        for (Database.SaveResult srInsert : srInsertList) {
            if (srInsert.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
            }
            else {
                // Operation failed, so get all errors
                for(Database.Error err : srInsert.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Course fields that affected this error: ' + err.getFields());
                }
            }
        }
        // updating the job control table record after the processing of records is complete
        List<Job_Control__c> jobList = new List<Job_Control__c>();
        for(Job_Control__c  obj : [Select Id,Processing_Status__c,Record_Update_Count__c,Number_of_Records_Processed__c from Job_Control__c where Job_Code__c = :sUniqueId]){
            obj.Processing_Status__c = 'Target Load Completed' ; 
            if( obj.Number_of_Records_Processed__c == null){
                obj.Number_of_Records_Processed__c = lststaging.size();
            }
            else  
                obj.Number_of_Records_Processed__c = lststaging.size() + obj.Number_of_Records_Processed__c.intValue();
            obj.Record_Update_Count__c = obj.Record_Update_Count__c.intValue() + 1;
            jobList.add(obj);
        }
        if(!jobList.isEmpty()){
            update jobList;
        }
    }

    private static String getQuery(String sObjectName, String sUniqueId)
    {
        String sQuery = 'SELECT Id ';
        for(jobTriggerMapping__mdt oMDT: lstFieldMapping)
        {
            sQuery += ',' + oMDT.Source_Field__r.QualifiedApiName;
        }
        sQuery += ' FROM Stg_Calendar__c' + ' WHERE Job_Code__c =: sUniqueId AND Record_Status__c !=  \'' + 'Completed' + '\'limit 2000';
        return sQuery;
    }

    private static sObject createNewRecordFromMappingStgCalendar(Stg_Calendar__c oStag, String sObjectName)
    {
        sObject sObjectNew = sobType.newSObject();
        for(jobTriggerMapping__mdt oMDT: lstFieldMapping)
        {
            sObjectNew.put(oMDT.Target_Field__r.QualifiedApiName, oStag.get(oMDT.Source_Field__r.QualifiedApiName));
        }
        return sObjectNew;
    }
}