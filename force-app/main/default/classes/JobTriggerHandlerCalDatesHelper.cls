/*******************************************************************************
* @author       Majid Reisi Dehkordi
* @date         11.June.2018
* @description  Helper class for jobtriggerhandler.
*               It will process the records from Stg_Calendar_Dates__c objects to
*				Calendar_Dates__c object
* @revision     -
*               13.05.2020 - PV - Fixed SOQL in LOOP
*******************************************************************************/
public class JobTriggerHandlerCalDatesHelper {

    private static List<jobTriggerMapping__mdt> lstFieldMapping = null;
    private static Schema.SObjectType targetObjType = null;
    private static Schema.SObjectType sourceObjType = null;


    public static void initializeJobControlRecord(List<jobTriggerMapping__mdt> lstFieldMappingPar, Schema.SObjectType targetObjTypePar)
    {
        //Initialize list field mapping
        lstFieldMapping = lstFieldMappingPar;
        //Initialize the target obj type
        targetObjType = targetObjTypePar;
    }

    public static void processJobControlRecord(String jobId, String targetObjectName)
    {
        String stagingObjectsQuery = createQuery(jobId, targetObjectName);
        List<Stg_Calendar_Dates__c> listOfStagingObjects = Database.query(stagingObjectsQuery);

        List<sObject> lstSObject = new List<sObject>();
        for(Stg_Calendar_Dates__c stagingObj: listOfStagingObjects)
        {
            lstSObject.add(createNewRecordFromMappingStgCalDate(stagingObj, targetObjectName));
            stagingObj.Record_Status__c = 'Completed';
        }

        lstSObject = addCalendarsIds(lstSObject);

        //Split list for insert and update of records
        Map<String,SObject> extIdMap = new Map<String,SObject>();
        for(SObject so : lstSObject) {
            extIdMap.put(String.valueOf(so.get('Calendar_Date_Unique_Key__c')),so);
        }

        Set<String> extIdSet = extIdMap.keyset();
        String splitQuery = 'SELECT Id,Calendar_Date_Unique_Key__c FROM '+String.valueOf(targetObjType) +' WHERE Calendar_Date_Unique_Key__c in :extIdSet';

        system.debug(splitQuery);

        List<SObject> insertList = new List<SObject>();
        Map<Id,SObject> updateMap = new Map<Id,SObject>();
        Map<String,Id> queryMap = new Map<String,Id>();

        for(SObject so : database.query(splitquery)) {
            queryMap.put(String.valueOf(so.get('Calendar_Date_Unique_Key__c')), so.Id);
        }

        for(SObject so : lstSObject) {
            Id theId = queryMap.get(String.valueOf(so.get('Calendar_Date_Unique_Key__c')));
            if(theId != null) {
                so.Id = theId;
                updateMap.put(theId,so);
            }
            else {
                insertList.add(so);
            }
        }

        Database.SaveResult[] srStagingList = Database.update(listOfStagingObjects, false);

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
        for(Job_Control__c  obj : [Select Id,Processing_Status__c,Record_Update_Count__c,Number_of_Records_Processed__c from Job_Control__c where Job_Code__c = :jobId]){
            obj.Processing_Status__c = 'Target Load Completed' ; 
            if( obj.Number_of_Records_Processed__c == null){
                obj.Number_of_Records_Processed__c = listOfStagingObjects.size();
            }
            else {
                obj.Number_of_Records_Processed__c = listOfStagingObjects.size() + obj.Number_of_Records_Processed__c.intValue();
            }
            obj.Record_Update_Count__c = obj.Record_Update_Count__c.intValue() + 1;
            jobList.add(obj);
        }
        if(!jobList.isEmpty()){
            update jobList;
        }
    }

    private static String createQuery(String jobId, String targetObjectName)
    {
        String sQuery = 'SELECT Id ';
        for(jobTriggerMapping__mdt oMDT: lstFieldMapping)
        {
            sQuery += ',' + oMDT.Source_Field__r.QualifiedApiName;
        }
        sQuery += ' FROM Stg_Calendar_Dates__c' + ' WHERE Job_Code__c =: jobId AND Record_Status__c !=  \'' + 'Completed' + '\'limit 2000';
        return sQuery;
    }


    private static sObject createNewRecordFromMappingStgCalDate(Stg_Calendar_Dates__c oStag, String targetObjectName)
    {
        sObject sObjectNew = targetObjType.newSObject();
        for(jobTriggerMapping__mdt oMDT: lstFieldMapping)
        {
            sObjectNew.put(oMDT.Target_Field__r.QualifiedApiName, oStag.get(oMDT.Source_Field__r.QualifiedApiName));
        }
        return sObjectNew;
    }

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         11.June.2018
    * @description  Adding Calendar__c Ids to Calendar_Dates__c objects
    * @revision     -
    *******************************************************************************/
    private static List<Calendar_Dates__c> addCalendarsIds(List<Calendar_Dates__c> listOfCalendarDates)
    {
        //A set to store all Calendar_Code__c values that exist in Calendar_Dates__c objects
        Set<String> calendarCodes = new Set<String>();
        for(Calendar_Dates__c calendarDateObj: listOfCalendarDates)
        {
            calendarCodes.add(calendarDateObj.Calendar_Code__c);
        }

        Map<String, id> calCodeCalIdMap = new Map<String, id>();
        if(calendarCodes.size() > 0)
        {
            // Get all of the calendar ids and fill in the map
            List<Calendar__c > listOfCalendars1 = [select id,Calendar_Code__c from Calendar__c where Calendar_Code__c IN :calendarCodes];
            for(Calendar__c calendarObj: listOfCalendars1)
            {
                calCodeCalIdMap.put(calendarObj.Calendar_Code__c, calendarObj.id);
            }

            // Populate listOfCalendarDates with matching calendar ids
            for(Calendar_Dates__c calDateObj: listOfCalendarDates)
            {
                calDateObj.CalendarId__c = calCodeCalIdMap.get(calDateObj.Calendar_Code__c);
            }

            //To Populate listOfCalendarDates with new calendar ids (for those who don't have matching calendars)
            //Step 1) Create the new calendar with matching Calendar_Code__c
            Set<Calendar__c> listOfNewCalendars = new Set<Calendar__c >();
            calendar__c newCal;
            for(Calendar_Dates__c calendarObj: listOfCalendarDates)
            {
                if(calendarObj.CalendarId__c == null)
                {
                    newCal = new calendar__c();
                    newCal.name = 'N/A';
                    newCal.Calendar_Code__c = calendarObj.Calendar_Code__c;

                    listOfNewCalendars.add(newCal);
                }
            }
            //Step 2) Insert All new calendars
            if(listOfNewCalendars.size() > 0)
                Insert new List<Calendar__c>(listOfNewCalendars);

            //Step 3) Get all CalendarCodes of listOfCalendarDates
            List<String> calendarCodes2 = new List<String>();
            for(Calendar_Dates__c calendarObj: listOfCalendarDates)
            {
                calendarCodes2.add(calendarObj.Calendar_Code__c);
            }

            //Step 4) Get all of the calendar ids and fill in the map
            List<Calendar__c > listOfCalendars2 = [select id,Calendar_Code__c from Calendar__c where Calendar_Code__c IN :calendarCodes2];
            for(Calendar__c calendarObj: listOfCalendars2)
            {
                calCodeCalIdMap.put(calendarObj.Calendar_Code__c, calendarObj.id);
            }

            //Step 5) Populate listOfCalendarDates with matching calendar ids
            for(Calendar_Dates__c calDateObj: listOfCalendarDates)
            {
                calDateObj.CalendarId__c = calCodeCalIdMap.get(calDateObj.Calendar_Code__c);
            }
        }

        return listOfCalendarDates;
    }
}