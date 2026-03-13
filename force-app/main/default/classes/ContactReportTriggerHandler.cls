/**
 * @description       : Trigger Handler to manage all DML and events on Contact Report
 * @author            : Inderpal Dhanoa
 * @group             : Engage Enterprise 
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   2021-06-22 - Inderpal Dhanoa -   Added a functionality to handle Insert and Delete for Contact Reports
**/
public without sharing class ContactReportTriggerHandler {
    /**
     * @author      Inderpal Dhanoa
     * @description Sync details of the Contact Report to a Task whenever a Contact report is created
     * @revision    22/06/2021 - Inderpal Dhanoa - Created
     */
    public class SyncInsertTasks extends TriggerAbstract {
        /**
        * Handle after insert event checking and filtering
        */
        public override void process(SObject record) { 
            //Process all records
            records.add(record);
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
			TaskServices.skipContactReportValidation = true;
            Boolean hasLockRow = false;
            List<Task> l_relatedTasks = new List<Task>();
            for(ucinn_ascendv2__Contact_Report__c contactReport : (List<ucinn_ascendv2__Contact_Report__c>)records){
                Task syncedTask = new Task();
                syncedTask.RecordTypeId = TaskServices.contactReportRecordTypeId;
                syncedTask.OwnerId = contactReport.OwnerId;
                syncedTask = ContactReportTriggerHelper.syncTask(syncedTask, contactReport);
                l_relatedTasks.add(syncedTask);
            }
            if(!l_relatedTasks.isEmpty()){
                try{
                    insert l_relatedTasks;
                } catch(Exception e) {
                    LogUtilityException.logException(e);
                    hasLockRow = e.getMessage().contains('UNABLE_TO_LOCK_ROW');
                    if(hasLockRow == false) {
                        throw e; 
                    }else{
                        //Implement a retry as possible for Locking due to DML on same Task by FundraiserContReportRelationTrigger
                        System.debug('!!@@##: Has Lock Row Error:');
                        insert l_relatedTasks;
                    }
                }                
            }
        }
    }

    /**
     * @author      Inderpal Dhanoa
     * @description Sync details of the Contact Report to a Task whenever a Contact report is updated
     * @revision    03/02/2021 - Inderpal Dhanoa - Created
     */
    public class SyncUpdateTasks extends TriggerAbstract {
        /**
        * Handle after insert event checking and filtering
        */
        public override void process(SObject record) { 
            //Process all records
            records.add(record);
        }

        public override void process(SObject record, SObject oldRec) { 
            //Process all records
            ucinn_ascendv2__Contact_Report__c contReportReln = (ucinn_ascendv2__Contact_Report__c)record;
            ucinn_ascendv2__Contact_Report__c oldContReportReln = (ucinn_ascendv2__Contact_Report__c)oldRec;
            if(contReportReln.ucinn_ascendv2__Contact__c != oldContReportReln.ucinn_ascendv2__Contact__c || 
               contReportReln.ucinn_ascendv2__Account__c != oldContReportReln.ucinn_ascendv2__Account__c ||
               contReportReln.ucinn_ascendv2__Proposal__c != oldContReportReln.ucinn_ascendv2__Proposal__c ||
               contReportReln.ucinn_ascendv2__Date__c != oldContReportReln.ucinn_ascendv2__Date__c ||
               contReportReln.ucinn_ascendv2__Description__c != oldContReportReln.ucinn_ascendv2__Description__c ||
               contReportReln.ucinn_ascendv2__Contact_Method__c != oldContReportReln.ucinn_ascendv2__Contact_Method__c){
                records.add(record);
            }
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
			TaskServices.skipContactReportValidation = true;
            Boolean hasLockRow = false;
            List<Task> l_existTasks = new List<Task>();
            Set<Id> s_contRepIds = new Set<Id>();
            List<Task> l_newTasks = new List<Task>();
            Map<Id, Task> m_contReportTask = new Map<Id, Task>();
            for(ucinn_ascendv2__Contact_Report__c contReport : (List<ucinn_ascendv2__Contact_Report__c>)records){
                s_contRepIds.add(contReport.Id);
            }
            // Create a Map with Contact Report and all linked Tasks
            for(Task reltask : [SELECT Id,Type,Contact_Report__c,Status,Completed_Date_Time__c,WhatId,Subject,WhoId FROM Task WHERE Contact_Report__c IN :s_contRepIds]){
                m_contReportTask.put(reltask.Contact_Report__c, reltask);
            }
            for(ucinn_ascendv2__Contact_Report__c contReport : (List<ucinn_ascendv2__Contact_Report__c>)records){
                if(m_contReportTask.containsKey(contReport.Id)){
                    // Tasks exist, update the values from Contact Report
                    Task relTask = m_contReportTask.get(contReport.Id);
                    reltask = ContactReportTriggerHelper.syncTask(relTask, contReport);
                    l_existTasks.add(reltask);                 
                }else{
                    Task insertTask = new Task();
                    insertTask.RecordTypeId = TaskServices.contactReportRecordTypeId;
                    insertTask.OwnerId = contReport.OwnerId;
                    insertTask = ContactReportTriggerHelper.syncTask(insertTask, contReport);
                    l_newTasks.add(insertTask);
                }
            }

            if(!l_existTasks.isEmpty()){
                try{
                    update l_existTasks;
                } catch(Exception e) {
                    LogUtilityException.logException(e);
                    hasLockRow = e.getMessage().contains('UNABLE_TO_LOCK_ROW');
                    if(hasLockRow == false) {
                        throw e; 
                    }else{
                        //Implement a retry as possible for Locking due to DML on same Task by FundraiserContReportRelationTrigger
                        System.debug('!!@@##: Has Lock Row Error:');
                        update l_existTasks;
                    }
                }                
            }
            if(!l_newTasks.isEmpty()){
                try{
                    insert l_newTasks;
                } catch(Exception e) {
                    LogUtilityException.logException(e);
                }                
            }            
        }
    }


    /**
     * @author      Inderpal Dhanoa
     * @description Sync details of the Contact Report to a Task whenever a Contact report is created
     * @revision    03/02/2021 - Inderpal Dhanoa - Created
     */
    public class SyncDeleteTasks extends TriggerAbstract {

        /**
        * Handle after insert event checking and filtering
        */
        public override void process(SObject record) {
            //Process all records
            records.add(record);
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
			TaskServices.skipContactReportValidation = true;
            Set<Id> s_deletedRecord = new Set<Id>();
            for(ucinn_ascendv2__Contact_Report__c contactReport : (List<ucinn_ascendv2__Contact_Report__c>)records){
                s_deletedRecord.add(contactReport.Id);
            }
            List<Task> l_relatedTasks = [SELECT Id FROM TASK WHERE RecordType.Id = :TaskServices.contactReportRecordTypeId AND Contact_Report__c in :s_deletedRecord];
            if(!l_relatedTasks.isEmpty()){
                delete l_relatedTasks;
            }
        }
    }
}