/*******************************************************************************
* @author       Nitin Khandelwal
* @date         7.June.2018        
* @description  Helper class for jobtriggerhandler. It will process the records from staging course object to
course object
* @revision     07 June 2018
*
*	Todo - Exception handling needs work
*******************************************************************************/
public class JobTriggerHandlerCourseHelper {
    public static final String fieldValue = 'Course-Published';
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
        List<Stg_Course__c> lstStaging = Database.query(sQueryForUniqueId);
        for(Stg_Course__c lStag: lstStaging){
            lStag.Course_Type__c = sType;
        }
        if(lstStaging.size() > 0)
        {
            List<Database.SaveResult> srStagingList = Database.update(lstStaging, false);
        }
        List<sObject> lstSObject = new List<sObject>();
        for(Stg_Course__c oStag: lstStaging)
        {
            lstSObject.add(createNewRecordFromMapping(oStag, sObjectName));
            oStag.Record_Status__c = 'Completed';
        }
        //Split list for insert and update of records
        Map<String,SObject> extIdMap = new Map<String,SObject>();
        for(SObject so : lstSObject){
            extIdMap.put((String)so.get('Course_code__c'),so);
        }
        Set<String> extIdSet = extIdMap.keyset();
        String splitQuery = 'SELECT Id,Course_code__c FROM '+String.valueOf(sobType) +' WHERE Course_code__c in :extIdSet';
        system.debug(splitQuery);
        List<SObject> insertList = new List<SObject>();
        Map<Id,SObject> updateMap = new Map<Id,SObject>();
        Map<String,Id> queryMap = new Map<String,Id>();
        for(SObject so : database.query(splitquery)){
            queryMap.put((String)so.get('Course_code__c'), so.Id);
        }
        for(SObject so : lstSObject){
            Id theId = queryMap.get((String)so.get('Course_code__c'));
            if(theId != null){
                so.Id = theId;
                updateMap.put(theId,so);
            }
            else{
                insertList.add(so);
            }
        }
        Database.SaveResult[] srStagingList = Database.update(lstStaging, false);
        
        // Iterate through each returned result
        for (Database.SaveResult srStag : srStagingList) {
            if (!srStag.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : srStag.getErrors()) {
                    logUtilityException.addLogEvent('STG Course', '1', err, 'processJobControlRecord');
                }
            }
        }
        Database.SaveResult[] srList = Database.update(updateMap.values(), false);
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    logUtilityException.addLogEvent('STG Course', '2', err, 'processJobControlRecord');
                }
            }
        }
        Database.SaveResult[] srInsertList = Database.insert(insertList, false);
        
        // Iterate through each returned result
        for (Database.SaveResult srInsert : srInsertList) {
            if (!srInsert.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : srInsert.getErrors()) {
                    logUtilityException.addLogEvent('STG Course', '3', err, 'processJobControlRecord');
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

        for(Job_Control__c  obj : [Select Id,Processing_Status__c from Job_Control__c where Job_Code__c = :sUniqueId and Process_Name__c = 'Course']){
            List<Course__c> newLstTarget = new List<Course__c>();
            String query = '';
            String SobjectApiName = 'Course__c';
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
            String strFields = '';
            for(String fieldName : fieldMap.keyset() )
            {
                if(strFields == null || strFields == '')
                {
                    strFields = fieldName;
                }else{
                    strFields = strFields + ' , ' + fieldName;
                }
            }
            
            // Field mapping are defined in custom metadata. Why do we need this for course published??
            
            query = 'SELECT ' + strFields + ' FROM ' + SobjectApiName + ' WHERE Job_Code__c = :sUniqueId AND Course_field_comparison__c = false AND Course_Type__c = \'' + fieldValue + '\'';
            List <Course__c> lstTarget = Database.query(query);
            For(Course__c course1 : lstTarget){
                Course__c course2 = new Course__c ();
                course2 = course1.clone(false,false,false,false);
                course2.Specialisation_Code__c = '';
                course2.Specialisation__c = '';
                course2.Course_Code__c = course1.Name;
                course2.Level__c = course1.Level__c;
                course2.Review_Date__c = course1.Review_Date__c;
                course2.End_Date__c = course1.End_Date__c;
                course2.Expiry_Date__c = course1.Expiry_Date__c;
                course2.Title__c = course1.Title__c;
                course2.Points__c = course1.Points__c;
                course2.Faculty_Code__c = course1.Faculty_Code__c;
                course2.Short_Title__c = course1.Short_Title__c;
                course2.Faculty_Description__c = course1.Faculty_Description__c;
                course2.Managing_Faculty__c = course1.Managing_Faculty__c;
                course2.Partner_Faculty_Description__c = course1.Partner_Faculty_Description__c;
                course2.Course_Description__c = course1.Course_Description__c;
                course2.Version__c = course1.Version__c;
                course2.Level_Description__c = course1.Level_Description__c;
                course2.Sub_Level__c = course1.Sub_Level__c;
                course2.Sub_Level_Description__c = course1.Sub_Level_Description__c; 
                course2.Duration_FT__c = course1.Duration_FT__c;
                course2.Status__c = course1.Status__c;
                course2.Abbreviation__c = course1.Abbreviation__c;
                course2.Type__c = course1.Type__c;
                course2.Partner_Faculty_Code__c = course1.Partner_Faculty_Code__c;
                course2.Start_Date__c = course1.Start_Date__c;
                newLstTarget.add(course2);
            }
            Map<String,Course__c> extIdMap_target = new Map<String,Course__c>();
            for(Course__c so_target : newLstTarget){
                extIdMap_target.put((String)so_target.get('Course_Code__c'),so_target);
            }
            Set<String> extIdSet_target = extIdMap_target.keyset();
            String splitQuery_course = 'SELECT Id,Course_Code__c FROM Course__c WHERE Course_Code__c in :extIdSet_target';
            system.debug(splitQuery_course);
            List<Course__c> insertlstTarget = new List<Course__c>();
            Map<Id,Course__c> updateMapTarget = new Map<Id,Course__c>();
            Map<String,Id> queryMapTarget = new Map<String,Id>();
            for(Course__c so_target : database.query(splitQuery_course)){
                queryMapTarget.put((String)so_target.get('Course_Code__c'), so_target.Id);
            }
            for(Course__c so_target : newLstTarget){
                Id theId = queryMapTarget.get((String)so_target.get('Course_Code__c'));
                if(theId != null){
                    so_target.Id = theId;
                    updateMapTarget.put(theId,so_target);
                }
                else{
                    insertlstTarget.add(so_target);
                }
            }
            // Creating the map again of insert list to remove duplicates from the list
            
            Map<String, Course__c> TargetMap = new Map<String, Course__c>();
            for(Course__c c : insertlstTarget) {
                TargetMap.put(c.course_code__c, c);   
            }
            Database.SaveResult[] srLisr_target = Database.update(updateMapTarget.values(), false);
            for (Database.SaveResult sr_target : srLisr_target) {
                if (sr_target.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr_target.getErrors()) {
	                    logUtilityException.addLogEvent('STG Course', '4', err, 'processJobControlRecord');
                    }
                }
            }
            Database.SaveResult[] srInsertlstTarget = Database.insert(TargetMap.values(), false);
            
            // Iterate through each returned result
            for (Database.SaveResult srInsert_Target : srInsertlstTarget) {
                if (srInsert_Target.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : srInsert_Target.getErrors()) {
	                    logUtilityException.addLogEvent('STG Course', '5', err, 'processJobControlRecord');
                    }
                }
            }
            
        }
    }
    
    private static String getQuery(String sObjectName, String sUniqueId)
    {
        String sQuery = 'SELECT Id ';
        for(jobTriggerMapping__mdt oMDT: lstFieldMapping)
        {
            sQuery += ',' + oMDT.Source_Field__r.QualifiedApiName;   
        }
        sQuery += ' FROM Stg_Course__c' + ' WHERE Job_Code__c =: sUniqueId AND Record_Status__c !=  \'' + 'Completed' + '\'limit 2000';
        return sQuery;
    }
    
    private static sObject createNewRecordFromMapping(Stg_Course__c oStag, String sObjectName)
    {
        sObject sObjectNew = sobType.newSObject();
        for(jobTriggerMapping__mdt oMDT: lstFieldMapping)
        {
            sObjectNew.put(oMDT.Target_Field__r.QualifiedApiName, oStag.get(oMDT.Source_Field__r.QualifiedApiName));
        }
        return sObjectNew;
    }
}