/*******************************************************************************
* @author       Nitin Khandelwal
* @date         7.June.2018        
* @description  Helper class for jobtriggerhandler. It will process the records from staging CRICOS Code object to
CRICOS Code object
* @revision     07 June 2018

*******************************************************************************/

public class JobTriggerHandlerCriCodeHelper {
    
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
        List<Stg_CRICOS_Code__c> lstStaging = Database.query(sQueryForUniqueId);
        List<sObject> lstSObject = new List<sObject>();
        for(Stg_CRICOS_Code__c oStag: lstStaging)
        {
            lstSObject.add(createNewRecordFromMappingStgCriCode(oStag, sObjectName));
            oStag.Record_Status__c = 'Completed';
        }
        lstSObject = addCourseIds(lstSObject);
        lstSObject = addUnitSetIds(lstSObject);
        system.debug('lstSObject' + lstSObject.size());
        
        //split the list for insert and update 
        
        Map<String,SObject> extIdMap = new Map<String,SObject>();
        for(SObject so : lstSObject){
            extIdMap.put((String)so.get('Unique_Key__c'),so);
        }
        system.debug('extIdMap' + extIdMap);
        Set<String> extIdSet = extIdMap.keyset();
        String splitQuery = 'SELECT Id,Unique_Key__c FROM '+String.valueOf(sobType) +' WHERE Unique_Key__c in :extIdSet';
        system.debug(splitQuery);
        List<SObject> insertList = new List<SObject>();
        Map<Id,SObject> updateMap = new Map<Id,SObject>();
        Map<String,Id> queryMap = new Map<String,Id>();
        for(SObject so : database.query(splitquery)){
            queryMap.put((String)so.get('Unique_Key__c'), so.Id);
        }
        for(SObject so : lstSObject){
            Id theId = queryMap.get((String)so.get('Unique_Key__c'));
            if(theId != null){
                so.Id = theId;
                updateMap.put(theId,so);
            }
            else{
                insertList.add(so);
            }
        }
        system.debug('insertList' + insertList.size());
        system.debug('Update' + updateMap.values().size());
        // lstSObject =addUnitIds(lstSObject);
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
        Database.SaveResult[] UpdateList = Database.update(updateMap.values(), false);
        
        // Iterate through each returned result
        for (Database.SaveResult srUpdate : UpdateList) {
            if (srUpdate.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : srUpdate.getErrors()) {
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
        sQuery += ' FROM Stg_CRICOS_Code__c' + ' WHERE Job_Code__c =: sUniqueId AND Record_Status__c !=  \'' + 'Completed' + '\'limit 2000';
        return sQuery;
    }
    
    private static sObject createNewRecordFromMappingStgCriCode(Stg_CRICOS_Code__c oStag, String sObjectName)
    {
        sObject sObjectNew = sobType.newSObject();
        for(jobTriggerMapping__mdt oMDT: lstFieldMapping)
        {
            sObjectNew.put(oMDT.Target_Field__r.QualifiedApiName, oStag.get(oMDT.Source_Field__r.QualifiedApiName));
        }
        return sObjectNew;
    }
    
    
    private static List<CRICOS_Code__c> addCourseIds(List<CRICOS_Code__c> listOfCRICOSCodes)
    {
        List<String> CRICOSCodes = new List<String>();
        for(CRICOS_Code__c CRICOSObj: listOfCRICOSCodes)
        {
            CRICOSCodes.add(CRICOSObj.Course_Version_key__c);
        }
        system.debug('course ver keys' + CRICOSCodes);
        Map<String, id> calCodeCalIdMap = new Map<String, id>();
        if(CRICOSCodes.size() > 0)
        {
            List<Course__c > listOfCRICOSCodes1= [select id,Course_Code__c from Course__c where Course_Code__c IN :CRICOSCodes and course_code__c != null];
            for(Course__c courseObj: listOfCRICOSCodes1)
            {
                calCodeCalIdMap.put(courseObj.Course_Code__c, courseObj.id);
            }
            system.debug('course list' + listOfCRICOSCodes1);
            for(CRICOS_Code__c calDateObj: listOfCRICOSCodes)
            {
                calDateObj.course__c = calCodeCalIdMap.get(calDateObj.Course_Version_key__c);
            }
            Set<Course__c> listOfNewCRICOSCodes = new Set<Course__c >();
            Course__c newCal;
            for(CRICOS_Code__c CRICOSObj: listOfCRICOSCodes)
            {
                if(CRICOSObj.Course__c == null)
                {
                    newCal = new Course__c();
                    newCal.name = 'N/A';
                    newCal.Course_Code__c = CRICOSObj.Course_Version_key__c;
                    listOfNewCRICOSCodes.add(newCal);
                }
            }
            if(listOfNewCRICOSCodes.size() > 0)
                Insert new List<Course__c>(listOfNewCRICOSCodes);
            system.debug('stub Course records' + listOfNewCRICOSCodes);
            List<String> CRICOSCodes2 = new List<String>();
            for(CRICOS_Code__c CRICOSObj: listOfCRICOSCodes)
            {
                CRICOSCodes2.add(CRICOSObj.Course_Version_key__c);
            }
            
            List<Course__c > listOfCalendars2 = [select id,Course_Code__c from Course__c where Course_Code__c IN :CRICOSCodes2 and course_code__c != null];
            for(Course__c CRICOSObj: listOfCalendars2)
            {
                calCodeCalIdMap.put(CRICOSObj.Course_Code__c, CRICOSObj.id);
            }
            for(CRICOS_Code__c calDateObj: listOfCRICOSCodes)
            {
                calDateObj.course__c = calCodeCalIdMap.get(calDateObj.Course_Version_key__c);
            }
        }
        return listOfCRICOSCodes;
    }
    private static List<CRICOS_Code__c> addUnitSetIds(List<CRICOS_Code__c> listOfCRICOSCodes2)
    {
        List<String> CRICOSCodes1 = new List<String>();
        for(CRICOS_Code__c CRICOSObj: listOfCRICOSCodes2)
        {
            CRICOSCodes1.add(CRICOSObj.Unit_Set_Version_key__c);
        }
        
        Map<String, id> calCodeCalIdMap1 = new Map<String, id>();
        
        List<Course__c > listOfCRICOSCodes1 = [select id,Course_Code__c from Course__c where Course_Code__c IN :CRICOSCodes1 and course_code__c != null];
        for(Course__c CRICOSObj: listOfCRICOSCodes1)
        {
            calCodeCalIdMap1.put(CRICOSObj.Course_Code__c, CRICOSObj.id);
        }
        for(CRICOS_Code__c calDateObj: listOfCRICOSCodes2)
        {
            calDateObj.unit_set__c = calCodeCalIdMap1.get(calDateObj.Unit_Set_Version_key__c);
        }
        
        return listOfCRICOSCodes2;
    }
    
}