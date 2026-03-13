/**
 * @author Ibrahim Rumi
 * @date 27-08-2020
 * @group Event Management
 * @description Trigger handler for BTStaffTrigger (Blackthorn)
 * @revision
 * Ver   Date         Author         Modification
 * 1.0   14-03-2022   RANAND         Added autoCreateEventStaff to create Event staffs if Event Group is populated
 **/
public class BTStaffTriggerHandler { 

    /**
    * @description Share Event and related sObjects available in BTStaffServices.shareObjMap to the staff
    */
    public class ShareStaffRelatedRecords extends TriggerAbstract {
        
        private List<conference360__Staff__c> newStaffRecs = new List<conference360__Staff__c>();
        private List<conference360__Staff__c> oldStaffRecs = new List<conference360__Staff__c>();
        private Set<Id>userIdSet = new Set<Id>();
        
        /**
         * @description process records in the after insert logic
         */
        public override void process(SObject sobj) {

            conference360__Staff__c newObj = (conference360__Staff__c) sobj;
           		this.useridset.add(newObj.conference360__User__c);
                this.newStaffRecs.add(newObj);
        }
        
        /**
         * @description process records in the after update logic
         */
        public override void process(SObject sobj, SObject oldRec) {

            conference360__Staff__c newObj = (conference360__Staff__c) sobj;
            conference360__Staff__c oldObj = (conference360__Staff__c) oldRec;

           			this.useridset.add(newObj.conference360__User__c);
            		this.newStaffRecs.add(newObj);
            		this.oldStaffRecs.add(oldObj);
        }

        public override void execute() {
             
            BTStaffShareManager btShare = new BTStaffShareManager();
            
            /**
             * insert new staff records
             */
            if(!this.newStaffRecs.isEmpty()) {
                btShare.processStaffInsert(this.newStaffRecs);
            }
            
            /**
             * delete sharing for updated user record relating to the satff
             */
            if(!this.oldStaffRecs.isEmpty()){
                btShare.processStaffDelete(this.oldStaffRecs);
            }
            BTStaffShareManager.asyncPermissionSetGroupAssignment(this.userIdSet);
        }
    }
    
    /**
    * @description prevent duplicate staff creation for Event or Event Group
    */
    public class ValidateStaff extends TriggerAbstract{
        private List<conference360__Staff__c> staffRecs = new List<conference360__Staff__c>();
        private Set<Id> eventIds = new Set<Id>();
        
        /**
         * @description process records in the insert logic
         */
        public override void process(Sobject sobj){
            conference360__Staff__c newobj = (conference360__Staff__c)sobj;
            if(newObj.conference360__User__c != null && (newObj.Event_Group__c != null || newObj.conference360__Event__c != null)) 
            {
                this.staffRecs.add(newObj);
            }
        }
        
        /**
         * @description process records in the update logic
         */
        public override void process(SObject sobj, SObject oldRec) {

            conference360__Staff__c newObj = (conference360__Staff__c) sobj;
            conference360__Staff__c oldObj = (conference360__Staff__c) oldRec;
            if(newObj.conference360__User__c != null && ( newObj.Event_Group__c != null || newObj.conference360__Event__c != null))
            {
                this.staffRecs.add(newObj);
            }
        }
        
        public override void execute(){
            /**
             * validate if the user already exists in the Event/Event group
             */
            new BTStaffShareManager().validateStaff(this.staffRecs);
        }
    }
    
    /**
     * @description delete Share records related to the staff
     */
    public class PurgeStaffRelatedShareRecords extends TriggerAbstract {
        
        private List<conference360__Staff__c> staffRecs = new List<conference360__Staff__c>();
        
        public override void process(SObject sobj) {

            conference360__Staff__c newObj = (conference360__Staff__c) sobj;
            
            //PROCESS IF: user rec is not null
            if(newObj.conference360__User__c != null && newObj.conference360__Event__c != null) 
            {
                this.staffRecs.add(newObj);
            }
        }


        public override void execute() {
             /**
             * delete Share records related to the staff
             */
            BTStaffShareManager btShare = new BTStaffShareManager();
            
            if(!this.staffRecs.isEmpty()) {
                btShare.processStaffDelete(this.staffRecs);
            }
            
        }
    }

    /**
     * @description automatically create Event Staff records whenever a new staff is mapped with Event Group
     */
    public class autoCreateEventStaff extends TriggerAbstract {
        List<conference360__Staff__c> groupStaffList = new List<conference360__Staff__c>();
        Set<Id> groupIds = new Set<Id>();

        // new records always have to be processed if Event_Group__c is not null
        public override void process(SObject newRecord) {
            conference360__Staff__c objStaff = (conference360__Staff__c) newRecord;
            if(String.isNotBlank(objStaff.Event_Group__c)){
                groupIds.add(objStaff.Event_Group__c);
            }
        }

        // records to be processed if Event_Group__c or User is changed on existing record
        public override void process(SObject sobj, SObject oldRec) {
            conference360__Staff__c newStaff = (conference360__Staff__c) sobj;
            conference360__Staff__c oldStaff = (conference360__Staff__c) oldRec;
            if(String.isNotBlank(newStaff.Event_Group__c) && (newStaff.conference360__User__c != oldStaff.conference360__User__c || newStaff.Event_Group__c != oldStaff.Event_Group__c)){
                groupIds.add(oldStaff.Event_Group__c);
                groupIds.add(newStaff.Event_Group__c);
            }
        }

        public override void execute() {
            try {
                //Manage Staff records when Event is created with Event Group 
                BTStaffServices service = new BTStaffServices();
                service.manageEventStaffForGroup(groupIds);
            } 
            catch(Exception e) {
                LogUtilityException.logException(e);
            } 
            finally {
                LogUtilityException.getLimits();
            }
        }
    }
}