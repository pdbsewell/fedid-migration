/**
 * Services class to provide Task sObject centric logical support
 * 
 * @author Carl Vescovi, PwC
 * @revision 24.Jun.2019 - APRivera - Added inner class for CTI
 * @revision 29-09-2020 APRivera - RW2-473 Added UpdateRelatedCase
 * @revision 24-06-2021 IDhanoa - ENGAGEIE-677 ValidateContactReportTask
 * @revision 18-10-2021 IDhanoa - ENGAGEIE-1004 ValidateContactReportTask
 */
public without sharing class TaskServices {
    public static final String COMPLETED = 'Completed';
    public static final String MONASH_CONNECT = 'Monash Connect%';

    public static final Id monTrackRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();
	public static final Id callLogRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Call_Log_Default').getRecordTypeId();
	public static final Id contactReportRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Contact_Report').getRecordTypeId();

    // Variable used to Bypass 'ValidateContactReportTask' if Task DML generated from FundraiserContReportRelation or ContactReportTrigger 
    // but Validation to fire in all other Task DML Scenarios 
    public static Boolean skipContactReportValidation = false;
    
    /** update task records without sharing restrictions
     * @param tsks list of task records to update
     */

    public static void updateTaskRecords(List<Task> tsks){
        update tsks;
    }

    /** delete task records without sharing restrictions
     * @param tsks list of tasks to delete
     */

    public static void deleteTaskRecords(List<Task> tsks){
        delete tsks;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         24/06/2019
    * @description  auto-links correct case to call log after each call
    * @revision     24/06/2019 - APRivera - Created
                    9/12/2024 - MMaramot - Updated to BindExtended framework
    *******************************************************************************/
    public class LinkCorrectCaseToCTICallLog extends TriggerAbstract{ 
        private List<Task> taskProcessList = new List<Task>();

        public override void process(SObject record) {
            Task t = (Task)record;

            // Process if Task is related to an inbound call 
            if(t.CallType == 'Inbound' && t.CallInitiatedTime__c != null 
                && t.CallAnsweredTime__c != null && t.WhoId != null && t.CallObject != null){
                    taskProcessList.add(t);
                }
        }

        public override void execute() {
            if(!taskProcessList.isEmpty()){
                processLinkCorrectCaseToCTICallLog(taskProcessList);
            }
        }  
    }
        
    public static void processLinkCorrectCaseToCTICallLog(List<Task> taskProcessList) {
        // Initialize variables
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setTaskIds = new Set<Id>();
        List<Task> lstTaskToUpdate = new List<Task>();
        List<Task> lstFilteredTask = new List<Task>();
        Map<Id, Task> mapTaskByContactIds = new Map<Id, Task>();

        // Get all task ids for query
        for(Task tsk : taskProcessList){
            setTaskIds.add(tsk.Id);
        }

        // Filter out tasks with owned by Monash Connect Roles (MCT-437)
        for(Task tsk : [SELECT Id, WhoId, WhatId, Owner.UserRole.Name FROM Task WHERE Id IN: setTaskIds AND (NOT Owner.UserRole.Name LIKE :MONASH_CONNECT )]){
            lstFilteredTask.add(tsk);
        }

        // Process 
        for(Task tsk : lstFilteredTask){
            setContactIds.add(tsk.WhoId);
            mapTaskByContactIds.put(tsk.WhoId, tsk);
        }
        if(!setContactIds.isEmpty()){
            Map<Id, Id> mapCaseIdByContactIds = retrieveMapCaseIdByContactIds(setContactIds);

            for(Id contactId : mapTaskByContactIds.keySet()){
                Id caseId = mapCaseIdByContactIds.get(contactId);
                Task tsk = mapTaskByContactIds.get(contactId);
                if(tsk.WhatId != caseId){
                    Task taskToUpdate = new Task();
                    taskToUpdate.Id = tsk.Id;
                    taskToUpdate.WhatId = caseId;
                    lstTaskToUpdate.add(taskToUpdate);
                }
            }

            try{
                if(!lstTaskToUpdate.isEmpty()){
                    update lstTaskToUpdate; // update first response date time
                }
            } catch (Exception ex){
                nebula.logger.error('TaskServices - unable to link case to task');
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
            
        }
    }

    public static Map<Id, Id> retrieveMapCaseIdByContactIds(Set<Id> setContactIds){
        Map<Id, Id> mapCaseIdByContactIds = new Map<Id, Id>();
        for(Contact con : [SELECT Id, (SELECT CaseNumber FROM Cases ORDER BY CreatedDate DESC limit 1)
        FROM Contact WHERE Id IN: setContactIds]){
            if(!con.Cases.isEmpty()) mapCaseIdByContactIds.put(con.Id, con.Cases.get(0).Id);
        }
        return mapCaseIdByContactIds;
    }

    /** copy fields from contact record over to Task, if Task is of a specific record type.
     * This is used specifically where standard reporting cannot aggregate information from multiple objects i.e.
     * MonTrack Round - to Task - to Contact.
    */
    public class considerTaskFieldMappings implements Triggers.Handler {
        public void run(){
            // copy mapped fields from Contact to task record depending on task record type
            List<Contact_to_Task_Field_Mapping__mdt> fieldMappings =
                    new List<Contact_to_Task_Field_Mapping__mdt>([ SELECT Id,
                            Contact_field_API_name__c,
                            Task_field_API_name__c,
                            Task_Record_Type__c
                    FROM Contact_to_Task_Field_Mapping__mdt limit 400]);

            // build a map of task record type ids
            Map<id,string> recordTypeIds = new Map<id,string>();
            for(Recordtype rt : [select id, developerName from RecordType where SObjectType = 'Task' limit 50])
                recordTypeIds.put(rt.id,rt.developername.tolowercase());

            // build a query string to ensure retrieval of all fields that may be wanted from contact if mapping to be done
            string qry = 'select ';
            for(Contact_to_Task_Field_Mapping__mdt fld : fieldMappings) {
              	qry += fld.Contact_field_API_name__c + ',';  
            } 
            qry += 'Id from contact where id in:contactIds limit 200';

            // retrieve contacts linked to tasks via whoId
            Set<id> contactIds = new Set<id>();
            for(task tsk : (List<Task>)Trigger.new) { if(tsk.whoId != null) contactIds.add(tsk.whoId); }

            Map<id,Contact> contacts = new Map<id,contact>();

            for(Contact c : Database.query(qry)) { contacts.put(c.id,c); }

            // loop through tasks, consider record type and if there are mappings then map
            for(Task tsk : (List<Task>)Trigger.new){
                if(tsk.whoId != null && contacts.containsKey(tsk.whoId) ){
                    // check mappings for possibles
                    for(Contact_to_Task_Field_Mapping__mdt mapping : fieldMappings){
                        if(recordTypeIds.get(tsk.recordTypeId) == mapping.Task_Record_Type__c.tolowercase())
                            tsk.put(mapping.Task_field_API_Name__c,contacts.get(tsk.whoId).get(mapping.Contact_field_API_name__c));
                    }
                }
            }
        }
    }

    /** if is a wrap up task (inserted by workflow action) then set the Type to 'Wrap up'
     * This is done via trigger so that can insert a normally unavailable value into picklist field - cannot be achieved via config
    */

    public class considerWrapUpTasks implements Triggers.Handler {
        public void run(){
            for(Task tsk : (List<task>)Trigger.new){
                if(tsk.Subject == 'Wrap Up Task' && tsk.Description == 'Enquiry wrapped up') tsk.Type = 'Wrap Up';
            }
        }
    }

    /*******************************************************************************
    * @description  handles all after update events. Filter event criteria here
    * @param        newMap - Trigger.newMap context variable
    *               oldMap - Trigger.oldMap context variable
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void handleAfterUpdate(Map<Id, Task> newMap, Map<Id, Task> oldMap) {

        //filters out and process MonTrack tasks
        List<Task> lstTasksWithUpdatedCallOutcome = new List<Task>();
        List<Task> lstMonTrackTasks = new List<Task>();
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setCampaignIds = new Set<Id>();
        filterOutMonTrackTasks(lstMonTrackTasks, lstTasksWithUpdatedCallOutcome, setContactIds, setCampaignIds, newMap, oldMap);
        if(!lstTasksWithUpdatedCallOutcome.isEmpty()) processMonTrackTaskToBeDeleted(lstTasksWithUpdatedCallOutcome, setCampaignIds);
        if(!lstMonTrackTasks.isEmpty()) processMonTrackTasks(lstMonTrackTasks, setContactIds);
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Filter out MonTrack tasks
    * @parameter    List<Task> lstMonTrackTasks, List<Task> lstTasksWithUpdatedCallOutcome,
    *               Set<Id> setContactIds,Map<Id, Task> newMap, Map<Id, Task> oldMap
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void filterOutMonTrackTasks(List<Task> lstMonTrackTasks, List<Task> lstTasksWithUpdatedCallOutcome,
            Set<Id> setContactIds, Set<Id> setCampaignIds,
            Map<Id, Task> newMap, Map<Id, Task> oldMap){
        for(Task newTask : newMap.values()){
            Task oldTask = oldMap.get(newTask.Id);
            //filter outs MonTrack tasks
            if(newTask.RecordTypeId == monTrackRecordTypeId){
                if(newTask.Offer_Status__c != oldTask.Offer_Status__c && newTask.Offer_Status__c != null){
                    lstMonTrackTasks.add(newTask);
                    setContactIds.add(newTask.WhoId);
                }
                if(newTask.Offer_Status__c != oldTask.Offer_Status__c && oldTask.Status == COMPLETED){
                    lstTasksWithUpdatedCallOutcome.add(newTask);
                    setCampaignIds.add(newTask.WhatId);
                }
            }
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Build map of campaign Id and map of tasks by whoId
    * @parameter    Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds, Task tsk
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void buildMapOfCampaignIdMapTasksByWhoIds(Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds, Task tsk){
        //build map of campaign ids and map of tasks by whoId(campaignMember)
        if(!mapCampaignIdMapTasksByWhoIds.containsKey(tsk.WhatId))
            mapCampaignIdMapTasksByWhoIds.put(tsk.WhatId, new Map<Id,Task>());
        mapCampaignIdMapTasksByWhoIds.get(tsk.WhatId).put(tsk.WhoId, tsk);
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Build map of campaign Id and map of tasks by whoId
    * @parameter    Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds, Task tsk
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void buildMapOfCampaignIdMapListTasksByWhoIds(Map<Id,Map<Id,List<Task>>> mapCmpIdMapLstTasksByWhoIds, Task tsk){
        //build map of campaign ids and map of tasks by whoId(campaignMember)
        if(!mapCmpIdMapLstTasksByWhoIds.containsKey(tsk.WhatId))
            mapCmpIdMapLstTasksByWhoIds.put(tsk.WhatId, new Map<Id,List<Task>>());
        if(!mapCmpIdMapLstTasksByWhoIds.get(tsk.WhatId).containsKey(tsk.WhoId))
            mapCmpIdMapLstTasksByWhoIds.get(tsk.WhatId).put(tsk.WhoId, new List<Task>());
        mapCmpIdMapLstTasksByWhoIds.get(tsk.WhatId).get(tsk.WhoId).add(tsk);
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Process MonTrack tasks
    * @parameter    List<Task> lstMonTrackTasks, Set<Id> setContactIds
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void processMonTrackTasks(List<Task> lstMonTrackTasks, Set<Id> setContactIds){
        Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds = new Map<Id,Map<Id,Task>>();
        List<Contact> lstContactsToBeUpdated = new List<Contact>();
        //retrieves contacts
        Map<Id, Contact> mapIdContacts = retrieveContactsByIds(setContactIds);
        for (Task tsk : lstMonTrackTasks){
            //build map of campaign ids and map of tasks by whoId(campaignMember)
            buildMapOfCampaignIdMapTasksByWhoIds(mapCampaignIdMapTasksByWhoIds, tsk);
            //process possible updates on contact
            if(!mapIdContacts.isEmpty()) contactMonTrackOptOut(lstContactsToBeUpdated, mapIdContacts, tsk);
        }
        performDMLs(lstContactsToBeUpdated, null, mapCampaignIdMapTasksByWhoIds, null, 'Update');
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Process MonTrack tasks to be deleted
    * @parameter    List<Task> lstTasksWithUpdatedCallOutcome
    * @revision     13/08/2018 - APRivera - Created
    *******************************************************************************/
    public static void processMonTrackTaskToBeDeleted(List<Task> lstTasksWithUpdatedCallOutcome, Set<Id> setCampaignIds){
        Map<Id,Map<Id,List<Task>>> mapCmpIdMapLstTasksByWhoIds = new Map<Id,Map<Id,List<Task>>>();
        Map<Id, List<Task>> mapCampaignIdListTasks = retrieveMapCmpIdLstTasks(setCampaignIds);
        if(!mapCampaignIdListTasks.isEmpty()){
            for(Id cmpId : setCampaignIds){
                for(Task tsk : mapCampaignIdListTasks.get(cmpId)){
                    //build map of campaign ids and map of tasks by whoId(campaignMember)
                    buildMapOfCampaignIdMapListTasksByWhoIds(mapCmpIdMapLstTasksByWhoIds, tsk);
                }
            }
            performDMLs(null, lstTasksWithUpdatedCallOutcome, null, mapCmpIdMapLstTasksByWhoIds, 'Delete');
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         13/08/2018
    * @description  performs DMLs
    * @parameter    List<Contact> lstContactsToBeUpdated, List<Task> lstTasksWithUpdatedCallOutcome,
                    Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds, String dmlType
    * @revision     13/08/2018 - APRivera - Created
    *******************************************************************************/
    public static void performDMLs(List<Contact> lstContactsToBeUpdated, List<Task> lstTasksWithUpdatedCallOutcome,
            Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds, Map<Id,Map<Id,List<Task>>> mapCmpIdMapLstTasksByWhoIds,
            String dmlType){
        if(dmlType == 'Update'){
            //updates campaign member's status
            if(!mapCampaignIdMapTasksByWhoIds.isEmpty()) completeMonTrackCampaignMemberStatus(mapCampaignIdMapTasksByWhoIds);
            //updates MonTrack Opt out and Reason on contacts
            if(!lstContactsToBeUpdated.isEmpty()) updateContactMonTrackOptOut(lstContactsToBeUpdated);
        }else if(dmlType == 'Delete'){
            //deletes MonTrack Tasks
            if(!lstTasksWithUpdatedCallOutcome.isEmpty()) deleteMonTrackTasks(lstTasksWithUpdatedCallOutcome, mapCmpIdMapLstTasksByWhoIds);
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         13/08/2018
    * @description  Deletes MonTrack tasks generated by previous call attempts.
    * @parameter    List<Task> lstTasksWithUpdatedCallOutcome, Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds
    * @revision     13/08/2018 - APRivera - Created
    *******************************************************************************/
    public static void deleteMonTrackTasks(List<Task> lstTasksWithUpdatedCallOutcome, Map<Id,Map<Id,List<Task>>> mapCmpIdMapLstTasksByWhoIds){
        List<Task> lstTaskToBeDeleted = new List<Task>();
        for(Task tsk : lstTasksWithUpdatedCallOutcome){
            if(mapCmpIdMapLstTasksByWhoIds.containsKey(tsk.WhatId) && mapCmpIdMapLstTasksByWhoIds.get(tsk.WhatId).containsKey(tsk.WhoId)){
                for(Task tskRecord : mapCmpIdMapLstTasksByWhoIds.get(tsk.WhatId).get(tsk.WhoId)){
                    if(tskRecord.CreatedDate > tsk.CreatedDate){
                        lstTaskToBeDeleted.add(tskRecord);
                    }
                }
            }
        }
        if(!lstTaskToBeDeleted.isEmpty()) deleteTaskRecords(lstTaskToBeDeleted);
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Process possible updates on contact - MonTrack Opt out and Opt out reason
    * @parameter    List<Contact> lstContactsToBeUpdated, Map<Id, Contact> mapIdContacts, Task tsk
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void contactMonTrackOptOut(List<Contact> lstContactsToBeUpdated, Map<Id, Contact> mapIdContacts, Task tsk){
        Contact con = mapIdContacts.get(tsk.WhoId);
        if(con.MonTrack_Opt_Out__c != tsk.MonTrack_Opt_Out_c__c || con.MonTrack_Opt_Out_Reason__c != tsk.MonTrack_OptOut_Reason__c ){
            con.MonTrack_Opt_Out__c = tsk.MonTrack_Opt_Out_c__c;
            con.MonTrack_Opt_Out_Reason__c = tsk.MonTrack_OptOut_Reason__c;
            lstContactsToBeUpdated.add(con);
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Updates campaign member's status (Montrack)
    * @parameter    List<Task> lstMonTrackTasks, Set<Id> setContactIds
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void completeMonTrackCampaignMemberStatus(Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds){
        Map<Id, List<CampaignMember>> mapRetrievedCmpIdLstCmpMemberIds = new Map<Id, List<CampaignMember>>();
        List<CampaignMember> lstCmpMembersToUpdate = new List<CampaignMember>();

        //retrieves existing campaign and campaign members
        mapRetrievedCmpIdLstCmpMemberIds = retrieveMonTrackCampaignMembers(mapCampaignIdMapTasksByWhoIds.keySet());

        //generates the list of campaign members to be updated
        lstCmpMembersToUpdate = generateListCmpMembersToBeUpdated(mapRetrievedCmpIdLstCmpMemberIds, mapCampaignIdMapTasksByWhoIds);

        //updates MonTrack CampaignMember status
        if(!lstCmpMembersToUpdate.isEmpty()) updateMonTrackCampaignMember(lstCmpMembersToUpdate);
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Generates list of campaign members to be updated (Status to 'Called')
    * @parameter    List<Task> lstTaskToInsert
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static List<CampaignMember> generateListCmpMembersToBeUpdated(Map<Id, List<CampaignMember>> mapRetrievedCmpIdLstCmpMemberIds,
            Map<Id,Map<Id,Task>> mapCampaignIdMapTasksByWhoIds){
        List<CampaignMember> lstCmpMembersToUpdate = new List<CampaignMember>();
        //iterates over the list of campaign related to triggered tasks
        for(Id cmpId : mapCampaignIdMapTasksByWhoIds.keySet()){
            Map<Id, CampaignMember> mapRetrievedCmpMemberIds = new Map<Id, CampaignMember>();
            for(CampaignMember cmpMember : mapRetrievedCmpIdLstCmpMemberIds.get(cmpId)){
                mapRetrievedCmpMemberIds.put(cmpMember.ContactId, cmpMember);
            }
            for(Id cmpMemberId : mapCampaignIdMapTasksByWhoIds.get(cmpId).keySet()){
                CampaignMember cmpMember = mapRetrievedCmpMemberIds.get(cmpMemberId);
                //assign Task's call outcome to campaign members status
                cmpMember.Status = mapCampaignIdMapTasksByWhoIds.get(cmpId).get(cmpMemberId).Offer_Status__c;
                lstCmpMembersToUpdate.add(cmpMember);
            }
        }
        return lstCmpMembersToUpdate;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Retrieves contact ids in context of updated MonTrack tasks
    * @parameter    Set<Id> contactIds
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static Map<Id, Contact> retrieveContactsByIds(Set<Id> setContactIds){
        Map<Id, Contact> mapIdContacts = new Map<Id, Contact>();
        for(Contact con : [Select Id, MonTrack_Opt_Out__c, MonTrack_Opt_Out_Reason__c
        from Contact where Id in: setContactIds]){
            mapIdContacts.put(con.Id, con);
        }
        return mapIdContacts;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Retrieves map of campaign id and List of campaign members
    * @parameter    Set<Id> campaignIds
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static Map<Id, List<CampaignMember>> retrieveMonTrackCampaignMembers(Set<Id> campaignIds){
        Map<Id, List<CampaignMember>> mapCmpIdLstCmpMemberIds = new Map<Id, List<CampaignMember>>();
        List<Campaign> lstCampaign = [Select Id, (Select Id, ContactId, Name, Status from CampaignMembers) from Campaign where Id in: campaignIds];
        for(Campaign cmp : lstCampaign){
            mapCmpIdLstCmpMemberIds.put(cmp.Id, cmp.CampaignMembers);
        }
        return mapCmpIdLstCmpMemberIds;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Retrieves map of campaign Id and List of Tasks
    * @parameter    Set<Id> campaignIds
    * @revision     13/08/2018 - APRivera - Created
    *******************************************************************************/
    public static Map<Id, List<Task>> retrieveMapCmpIdLstTasks(Set<Id> campaignIds){
        Map<Id, List<Task>> mapCampaignIdListTasks = new Map<Id, List<Task>>();
        List<Campaign> lstCampaign = [Select Id, (Select Subject, Id, WhatId, WhoId, CreatedDate,
                Offer_Status__c, Call_Attempt__c from Tasks)
        from Campaign where Id in: campaignIds];
        for(Campaign cmp : lstCampaign){
            mapCampaignIdListTasks.put(cmp.Id, cmp.Tasks);
        }
        return mapCampaignIdListTasks;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Updates campaign members
    * @parameter    List<CampaignMember> lstCampaignMembers
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void updateMonTrackCampaignMember(List<CampaignMember> lstCampaignMembers){
        try {
            Database.update(lstCampaignMembers);
        }catch (exception ex){
            ExLog.write('TaskServices','updateMontrackCampaignMember','Updating Campaign Member Status',ex.getMessage());
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Updates Contact if MonTrack Opt Out and Opt Out Reason is updated when called
    * @parameter    List<Task> lstTaskToInsert
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
    public static void updateContactMonTrackOptOut(List<Contact> lstContactsToBeUpdated){
        try {
            Database.update(lstContactsToBeUpdated);
        }catch (exception ex){
            ExLog.write('TaskServices','updateContactMonTrackOptOut','Updating Contacts Montrack Opt out',ex.getMessage());
        }
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         15/05/2018
    * @description  This processes duplicate wrap up task.
    *               Deletes newly created wrap up task (duplicate) if there's existing tasks
                    Updates the existing task - Changing the ActivityDate and Adding Comments.
    * @revision    APRivera - 14/05/2018 - DCXCRM-1730 - Fix for the wrap up tasks duplicate creation
    *******************************************************************************/
    public class processDuplicateWrapUpTasks implements Triggers.Handler {
        public void run(){
            set<Id> caseIds = new set<Id>();
            for(Task tsk : (List<task>)Trigger.new){
                if(tsk.Subject == 'Wrap Up Task'){                  //filters out wrap up task
                    caseIds.add(tsk.whatId);                        //creates the set of CaseIds from these wrap up tasks
                }
            }

            if(!caseIds.isEmpty()){
                List<Task> lstTasksToDelete = new List<Task>();
                List<Task> lstTasksToUpdate = new List<Task>();
                Map<id,case> mapCases = retrieveCases(caseIds);     //retrieves cases and wrap up tasks linked to it
                //for(Id cseId : caseIds){                            //iterates over the set of case Ids
                for(Case cseRecord : mapCases.values()){          //iterates over the list of Case records to process wrap up tasks
                    if(cseRecord.Tasks.size() > 1){                 //checks if case has more than one wrap up tasks
                        for(Integer ctr=0; ctr<cseRecord.Tasks.size(); ctr++){  //iterate on tasks
                            if(ctr != 1){
                                Task tskDelete = cseRecord.Tasks[ctr];
                                lstTasksToDelete.add(tskDelete);          //adds the latest created task for deletion
                            }else{
                                Task tskUpdate = cseRecord.Tasks[ctr];
                                tskUpdate.ActivityDate = System.today();
                                tskUpdate.Description = tskUpdate.Description + '\n'
                                        + 'Enquiry Status: ' + cseRecord.Status
                                        +'. Last modified by: '
                                        + cseRecord.Last_Updated_By__c
                                        + '. - ' + getLocalTime(cseRecord.LastModifiedDate);
                                lstTasksToUpdate.add(tskUpdate);          //adds the existing one to the list of tasks to be updated
                            }
                        }
                    }
                }
                //}

                try{
                    if(!lstTasksToDelete.isEmpty()){
                        Database.delete(lstTasksToDelete);              //Wrap up Tasks deletion
                    }
                    if(!lstTasksToUpdate.isEmpty()){
                        Database.update(lstTasksToUpdate);              //Wrap up Tasks Update
                    }
                } catch (exception ex){
                    ExLog.write('TaskServices','processDuplicateWrapUpTasks','Updating/Deleting wrap up tasks.',ex.getMessage());
                }
            }
        }

        /*******************************************************************************
       * @author       Angelo Rivera
       * @date         14/05/2018
       * @description  Method to get the correct time format
       * @parameter    DateTime timeToConvert
       * @revision     APRivera - 18/05/2018 - Initial Version
       *******************************************************************************/
        public DateTime getLocalTime(DateTime timeToConvert){
            DateTime localTime;
            if(timeToConvert != null){
                TimeZone tz = UserInfo.getTimeZone();
                localTime = timeToConvert.AddSeconds(tz.getOffset(timeToConvert)/1000);
            }
            return localTime;
        }

        /*******************************************************************************
        * @author       Angelo Rivera
        * @date         14/05/2018
        * @description  Method to retrieve existing case
        * @parameter    Set<Id> setCaseIds
        * @revision     APRivera - 14/05/2018 - Initial Version
        *******************************************************************************/
        public Map<id,case> retrieveCases(Set<Id> setCaseIds){
            Map<id,case> mapCases = new Map<id,Case>();
            if(!setCaseIds.isEmpty()){
                mapCases = new Map<id,Case>([SELECT Id, Status, Last_Updated_By__c, LastModifiedDate,
                (SELECT Id, CreatedDate, ActivityDate, Description FROM Tasks
                WHERE Type = 'Wrap Up' ORDER BY CreatedDate DESC)
                FROM Case
                WHERE Id IN:setCaseIds
                ]);
            }
            return mapCases;
        }
    }

    /** if is a Service Level Agreement task (inserted by workflow action) then set the Type to 'Service Level Agreement' 
     * This is done via trigger so that can insert a normally unavailable value into picklist field - cannot be achieved via config
     */
    public class considerServiceLevelAgreementTasks implements Triggers.Handler {
        public void run(){
            for(Task tsk : (List<task>)Trigger.new){
                if(tsk.Subject == 'Service Level Agreement'){
                    tsk.Type = 'Service Level Agreement';
                }
            }
        }
    }
    
    /*
     * @author:			ayush.agrawal@monash.edu
     * @date:			28-09-2020
     * @description:	Rolls up the count of Task records with record type 'Call Log - Default' to Case.
     */
    public class rollUpCallCountToCase implements Triggers.Handler {
        public void run() {
            Set<Id> caseIds = new Set<Id>();
            List<Task> tasks = new List<Task>();
            if(Trigger.isInsert) {
                tasks = (List<Task>)Trigger.new;
            } else if(Trigger.isDelete) {
                tasks = (List<Task>)Trigger.old;
            }
            
            Id callLogTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Call_Log_Default').getRecordTypeId();

            for(Task t : tasks) {
                if(t.RecordTypeId != callLogTaskRecordTypeId) {
                    continue;
                }
                
                if(String.isBlank(t.WhatId) || !String.valueOf(t.WhatId).startsWith('500')) {
                    continue;
                }
                
                caseIds.add(t.WhatId);
            }
            
            List<Case> cases = [SELECT
                                Id,
                                Number_of_Calls__c,
                                (
                                    SELECT
                                    Id
                                    FROM Tasks
                                    WHERE RecordTypeId = :callLogTaskRecordTypeId AND WhatId IN :caseIds
                                )
                                FROM Case
                                WHERE Id IN :caseIds
                               ];

            for(Case c : cases) {
                c.Number_of_Calls__c = c.Tasks.size();
            }
            
            if(!cases.isEmpty()) {
                update cases;
            }
        }
    }
    
    /*
     * @author:			APRivera
     * @date:			29-09-2020
     * @description:	Updates the CallBack Date Time in Enquiry
     */
    public class UpdateRelatedCase extends TriggerAbstract {
        
        public Map<Id, Task> mapTaskByCaseId = new Map<Id, Task>();
       
        public override void process(SObject record, SObject oldRec){
            Task newTask = (Task)record;
            Task oldTask = (Task)oldRec;
            
            if(newTask.RecordTypeId == callLogRecordTypeId && (String.isBlank(newTask.WhatId) || newTask.Whatid.getSobjectType() == Case.SObjectType)
                  	&& (newTask.Call_Back_Date_Time__c != oldTask.Call_Back_Date_Time__c || newTask.Call_Back_Date_Time__c != null) ) {
                    mapTaskByCaseId.put(newTask.WhatId,newTask);
            }
        }
        public override void execute() {
            //Checks if there are records to be processed
            if(!mapTaskByCaseId.isEmpty()){
                List<Case> lstCasesToBeUpdated = new List<Case>();
                
                for(Case c : [SELECT Id, CallBack_Date_Time__c FROM Case WHERE Id IN :mapTaskByCaseId.keySet()]) {
                	c.CallBack_Date_Time__c = mapTaskByCaseId.get(c.Id).Call_Back_Date_Time__c;
                	lstCasesToBeUpdated.add(c);
            	}
            
                 if(!lstCasesToBeUpdated.isEmpty()) {
                    update lstCasesToBeUpdated;
                }
            }
            LogUtilityException.getLimits();
        }
    }

	/*
     * @author:			IDhanoa idha0002
     * @date:			18-10-2021
     * @description:	Validate Contact_Report rec Type Tasks to be edited by Sys Admins only
     */
    public class ValidateContactReportTask extends TriggerAbstract {      
        public override void process(SObject record, SObject oldRec){
            records.add(record);
        }

        public override void process(SObject record) {
            //Process all records
            records.add(record);
        }

        public override void execute() {
            //Checks if there are records to be processed
            List<User> runningUser = [SELECT Id, Profile.Name FROM User WHERE Id =:Userinfo.getUserId()];
            if(!runningUser.isEmpty()){
                for(Task newTask : (List<Task>)records){
                    if(!skipContactReportValidation && newTask.RecordTypeId == contactReportRecordTypeId && runningUser[0].Profile.Name != 'System Administrator') {
                        newTask.addError(System.Label.ContactReportTaskValidation); 
                    }
                }
            }  
        }
    }	

    /*
     * @author:			JPadda jpad0005
     * @date:			11-09-2023
     * @description:	Adds Case Teams based on Case Team Creation rules
     */
    public class AddCaseTeam extends TriggerAbstract {
        public override void process(SObject record) {
            Task task = (Task) record;

            if (task.WhatId?.getSObjectType() == Case.SObjectType) {
                records.add(record);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Task task = (Task) record;
            Task oldTask = (Task) oldRec;

            if (
                task.WhatId?.getSObjectType() == Case.SObjectType &&
                task.OwnerId != oldTask.OwnerId
            ) {
                records.add(record);
            }
        }

        public override void execute() {
            Set<Id> caseIds = new Set<Id>();
            for (Task newTask : (List<Task>) records) {
                caseIds.add(newTask.WhatId);
            }

            Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, RecordType.DeveloperName FROM Case WHERE Id IN :caseIds]);

            if(records.isEmpty() == false ){
                if(FeatureManagement.checkPermission('Run_Case_Team_Creation_Rules')){
                    CaseTeamServices.runCaseTeamCreationRules(records, caseMap, 'WhatId');
                }
            }
        }
    }

    /*******************************************************************************
    * @author       Sethu Venna
    * @date         28/01/2025
    * @description  execute methiod to finalize and log exceptions
    * @param        context of the executable
    * @revision     28/01/2025 - Initial Version
    *******************************************************************************/
    public class CopyACPId implements Triggers.Handler {
        public void run()
        {
            for(Task taskRec : (List<task>)Trigger.new)
            {
                if(taskRec.WhatId != null && taskRec.WhatId.getSObjectType().getDescribe().getName() == 'Application_Course_Preference__c')
                {
                    taskRec.Application_Course_Preference__c = taskRec.WhatId;
                }
            }
        }
    }

    /*******************************************************************************
    * @author       Sethu Venna
    * @date         28/01/2025
    * @description  execute methiod to finalize and log exceptions
    * @param        context of the executable
    * @revision     28/01/2025 - Initial Version
    *******************************************************************************/
    public class CopyTaskType implements Triggers.Handler {
        public void run()
        {   
            Map<Id, Task> taskOldMap = (Map<Id, Task>)Trigger.oldMap;
            for(Task taskRec : (List<task>)Trigger.new)
            {
                if(taskRec.RecordTypeId == Schema.SObjectType.Task.getRecordTypeInfosByName().get('Admissions').getRecordTypeId()) {
                    if(Trigger.isInsert) {
                        taskRec.Type__c = taskRec.Type;
                    }
                    else if(taskRec.Type__c != taskOldMap.get(taskRec.Id).Type__c){
                        taskRec.Type = taskRec.Type__c;
                    }
                }
            }
        }
    }
}