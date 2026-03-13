/*
 * @author	Davey Yu
 * @description  Timestamp log service class
 * @revision
 * Davey Yu 12-APR-25 : SMSTA-517 - Time Stamp Reporting - Adding a record when status changes
 */
public class TimestampLogger {

    // Internal class to store tracked field details
    private class TrackedField {
        public String objectName;
        public String fieldName;
    }

   /*
    * @author       Davey Yu
    * @date         23.Apr.2025
    * @description  Get the timestamp configuration metadata 
    * @return Map of the tracked fields and its configuration
    * @revision
    */
    private static Map<String, List<Timestamp_Config__mdt>> getTrackedFields() {
        Map<String, List<Timestamp_Config__mdt>> tracked = new Map<String, List<Timestamp_Config__mdt>>();
		//create a map of the tracked fields and its configuration
        for (Timestamp_Config__mdt config : [
            SELECT Object_API_Name__c, Field_API_Name__c, Active__c, Business_Hours_Name__c, Exclude_Non_Business_Hours__c, Unit__c
            FROM Timestamp_Config__mdt
            WHERE Active__c = true
        ]) {
            if(!tracked.containsKey(config.Object_API_Name__c)) {
            	tracked.put(config.Object_API_Name__c, new List<Timestamp_Config__mdt>());
            }
            tracked.get(config.Object_API_Name__c).add(config);
        }

        return tracked;
    }
	
   /*
    * @author       Davey Yu
    * @date         23.Apr.2025
    * @description  Create a timestamp log record 
    * @return 
    * @revision
    */
    public static void logChanges(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, String objectName, Boolean isUpdate, Boolean isInsert) {
        try{
            Map<String, List<Timestamp_Config__mdt>> trackedFields = getTrackedFields();
            if (!trackedFields.containsKey(objectName)) return;
            
        
            List<Timestamp_Config__mdt> fieldsToTrack = trackedFields.get(objectName);
            List<Timestamp_Log__c> logsToInsert = new List<Timestamp_Log__c>();
            List<Timestamp_Log__c> logsToUpdate = new List<Timestamp_Log__c>();
            Datetime dateToday = System.now();
            RecordType timeType = getRecordType('Timestamp_Log__c', 'Admissions');
            
           	//Map of the parent record and its latest timestamp log to update
            Map<Id, Timestamp_Log__c> latestLogsMap = getLatestLogsByParent(newMap.keyset(), timeType.id);
            
            //Business hours map
      		Map<String, Id> businessHoursMap = new Map<String, Id>();
            for (BusinessHours bh : [SELECT Id, Name FROM BusinessHours]) {
                businessHoursMap.put(bh.Name, bh.Id);
            }
    

            for (Id recordId : newMap.keySet()) {
                SObject oldRec = oldMap != null ? oldMap.get(recordId) : null;
                SObject newRec = newMap.get(recordId);
                
                //Loop through each field to track for the sobject
                for (Timestamp_Config__mdt config : fieldsToTrack) {
                    
                    Object oldVal = oldRec != null ? oldRec.get(config.Field_API_Name__c) : null;
                    Object newVal = newRec.get(config.Field_API_Name__c);
                    //compare if field value is updated
                    //the first two condition is applicable on update operation
                    //the isInsert && newVal != null condition is for insert operation               
                    if (((oldVal != newVal) && (oldVal == null || !oldVal.equals(newVal))) || (isInsert && newVal != null)) {
                        Timestamp_Log__c newLog = new Timestamp_Log__c();
                        newLog.Parent_Object_Name__c = objectName;
                        newLog.Parent_Object_Id__c = recordId;
                        newLog.Field_Name__c = config.Field_API_Name__c;
                        newLog.Field_Value__c = newVal != null ? String.valueOf(newVal) : null;
                        newLog.Old_Value__c = oldVal != null ? String.valueOf(oldVal) : null;
                        newLog.Date__c = dateToday;
                    
                        //Code below are specific to SMSTA Time Calculation
                        if(objectName == 'Application_Course_Preference__c' && config.Field_API_Name__c == 'Workflow_Status__c' 
                        && timeType.name == 'Admissions'){
                            
                            newLog.Start_Time__c = dateToday;
                            if(newVal == 'On Hold'){
                                newLog.Additional_Comments_On_Hold__c  = (String)newRec.get('OnHold_Comments__c');
                                newLog.On_Hold_Reason__c =  (String)newRec.get('On_Hold_Reason__c');
                            }
                            if(newVal == 'Released'){
                                newLog.Release_Reason__c = (String)newRec.get('Release_Reason__c');
                            }
                            newLog.Owner_Name__c = (String)newRec.get('Owner_Name__c');
                            newLog.Owner_Team__c = (String)newRec.get('Owner_Team__c');
                            User lastModifiedBy = (User)newRec.getSObject('LastModifiedBy');
                            newLog.ACP_Last_Modified_By__c = lastModifiedBy != null ? lastModifiedBy.Id : null;
                            newLog.ACP_Last_Modified_By_Name__c = lastModifiedBy != null ? lastModifiedBy.Name : null;
                            newLog.Admission_Category__c = (String)newRec.get('Admission_Category__c');
                            newLog.Application_Course_Preference__c =  recordId;
                            newLog.Application_Course_Preference_Name__c =  (String)newRec.get('Name');
                            newLog.Course_Code__c = (String)newRec.get('Course_Code__c');
                            newLog.Course_Level__c = (String)newRec.get('Course_Level__c');
                            newLog.Intake_Period__c = (String)newRec.get('Intake_Period__c');
                            newLog.Location__c = (String)newRec.get('Location_Code__c');
                            newLog.Managing_Faculty__c = (String)newRec.get('Managing_Faculty__c');
                            newLog.Person_Id__c = (String)newRec.get('Person_ID__c');
                            newLog.RecordTypeId = timeType.id;
                            Application__c application = (Application__c)newRec.getSObject('Application__r');
                            newLog.Application_No__c = application != null ? application.Name : null;                       
                        }
                        logsToInsert.add(newLog);
                        
                        //update previous time stamp log with end time and calculate the turn around time
                        Timestamp_Log__c updatePreviousTimestamp = updateTimestamp(timeType.id, recordId, config.Exclude_Non_Business_Hours__c, businessHoursMap.get(config.Business_Hours_Name__c), config.Unit__c,latestLogsMap.get(recordId));

                        if(updatePreviousTimestamp != null){
                            logsToUpdate.add(updatePreviousTimestamp);
                        }  
                    }
                }
            }

            if(!logsToInsert.isEmpty()) {
                insert logsToInsert;
            }

            if(!logsToUpdate.isEmpty()) {
                update logsToUpdate;
            }
        }catch(Exception ex){
                Nebula.Logger.error('TimestampLogger.logChanges', ex);
                Nebula.Logger.saveLog();
        }
    }

	/*
    * @author       Davey Yu
    * @date         23.Apr.2025
    * @description  Create map of the parent record and its latest timestamp log
    * @return Map of parent record and latest timestamp log
    * @revision
    */
    public static Map<Id, Timestamp_Log__c> getLatestLogsByParent(Set<Id> parentIds, Id recordTypeId) {
        Map<Id, Timestamp_Log__c> latestLogsMap = new Map<Id, Timestamp_Log__c>();
    
        if (parentIds == null || parentIds.isEmpty()) return latestLogsMap;
    
        List<Timestamp_Log__c> latestLogs = [
            SELECT Id, Turn_Around_Time__c, End_Time__c, Start_Time__c, Parent_Object_Id__c 
            FROM Timestamp_Log__c 
            WHERE RecordTypeId = :recordTypeId 
            AND Parent_Object_Id__c IN :parentIds 
            ORDER BY CreatedDate DESC
        ];
    
        Set<Id> seenParentIds = new Set<Id>();
        for (Timestamp_Log__c log : latestLogs) {
            if (!seenParentIds.contains(log.Parent_Object_Id__c)) {
                latestLogsMap.put(log.Parent_Object_Id__c, log);
                seenParentIds.add(log.Parent_Object_Id__c);
            }
        }
    
        return latestLogsMap;
	}   
    	
   /*
    * @author       Davey Yu
    * @date         23.Apr.2025
    * @description  Update the previous time stamp record with the turn around time
    * @return Timestamp log record
    * @revision
    */
    public static Timestamp_Log__c updateTimestamp(String typeId, String recordId, Boolean excludeNonBusinesssHours, Id businessHoursId, String unit, Timestamp_Log__c previousTimeLog){
        
        Timestamp_Log__c updateTimeStamp = null;
       
       if (previousTimeLog == null) return null;
      
        Datetime enddateTime = System.now();
        Datetime startDateTime = previousTimeLog.start_time__c;
        Integer timeDiffInDays = 0;
        Long timeDifferenceInMillis  = 0;
        Decimal dateDifference = 0;
        if(excludeNonBusinesssHours){//consider business hours in calculation
            timeDifferenceInMillis = BusinessHours.diff(businessHoursId, startDateTime, endDateTime);
        }else{
            timeDifferenceInMillis = endDateTime.getTime() - startDateTime.getTime();
        }            
        dateDifference = calculateTimeDifference(unit, timeDifferenceInMillis);
        previousTimeLog.Turn_Around_Time__c = dateDifference;
        previousTimeLog.End_Time__c = enddateTime;
        updateTimeStamp = previousTimeLog;
        
       return updateTimeStamp;
    }
    
    /*
    * @author       Davey Yu
    * @date         23.Apr.2025
    * @description  Calculate Time difference between two dates 
    * @return hourse difference between two dates
    * @revision
    */
    public static Decimal calculateTimeDifference(String unit, Long timeDifferenceInMillis){
    	Decimal dateDifference = 0;
         if(unit == 'Hours'){
         	dateDifference = timeDifferenceInMillis / (1000 * 60 * 60.0);
         }else{
            dateDifference =  Math.floor(timeDifferenceInMillis / (1000 * 60 * 60.0 * 24));
         }
        return dateDifference;

    }
    
   /*
    * @author       Davey Yu
    * @date         23.Apr.2025
    * @description  Retrieve record type details
    * @return Record Type Name
    * @revision
    */
    public static RecordType getRecordType(String objectName, String recordTypeName) {
        RecordType rt = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = :objectName 
              AND Name = :recordTypeName 
              LIMIT 1
        ];
        return rt;
    }
}