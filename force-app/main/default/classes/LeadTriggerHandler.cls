/**
 * @description       : Trigger handler for Lead object
 * @author            : Nick Guia
 * @group             : Commons
 * @last modified on  : 13-10-2022
 * @last modified by  : NG
 * @revision
 *  OCT.13.2022     Nick Guia   - Deleted ComputeForcastedStartDate. This will now be populated through the Lead Grading integration 
**/
public with sharing class LeadTriggerHandler {

    public static Boolean runOnce = true;
    /**
     * @description Update fields required for lead nurturing matching & duplicate rules:
     * 1. Active_Lead_Contact_Id__c: Is populated with the Contact Id only if the Lead status 
     *    is Active (that is either Open or Contacted), otherwise the field is not populated.
     * 2. Lead_Record_Type_Id__c: copy recordTypeId to field (to be used in matching/duplicate rule)
    **/ 
    public class PopulateLeadNurturingFields extends TriggerAbstract {

        LeadServices service = new LeadServices();

        public override void process(SObject sobj) {
            Lead newRecord = (Lead) sobj;
            service.toggleActiveLead(newRecord);
            newRecord.Lead_Record_Type_Id__c = newRecord.recordTypeId; //default
        }

        public override void process(SObject sobj, SObject oldRec) {
            Lead newRecord = (Lead) sobj;
            Lead oldRecord = (Lead) oldRec;

            //if status changed, re-process active lead
            if(newRecord.Status != oldRecord.Status) {
                service.toggleActiveLead(newRecord);
            }
            //if record type changed, re-process custom record type id field
            if(newRecord.recordTypeId != oldRecord.recordTypeId) {
                newRecord.Lead_Record_Type_Id__c = newRecord.recordTypeId;
            }
            if(newRecord.Primary_Course_Master_Associated__c != oldRecord.Primary_Course_Master_Associated__c) {
                newRecord.Last_Course_Associated_Date__c = DateTime.Now();
            }
        }

    }
    /**
     * @author : [Babyshark]
     * @description : 
     * - CascadeUpdatesOnContact - Below class will roll up Email and Mobile field values to associated Contact when updated
     * @date : 21/11/2024
     * @rev
     * 
     */
    public class CascadeUpdatesOnContact extends TriggerAbstract{
        List<Lead> leadstoProcess = new List<Lead>();
        public override void process(SObject sobj, SObject oldRec) {
            Lead newRecord = (Lead) sobj;
            Lead oldRecord = (Lead) oldRec;
            //Check if Email or Mobile field is updated and there is an active Contact associated on Lead
            if(newRecord.Active_Lead_Contact_Id__c != null && (newrecord.Email != oldRecord.Email || newRecord.MobilePhone != oldRecord.MobilePhone)){
                leadstoProcess.add(newRecord);
            }
        }

        public override void execute() {
            List<Contact> contactsToUpdate = new List<Contact>();
            for(Lead objLead : leadstoProcess){
                //Setup Contact with updated values from Lead 
                contactsToUpdate.add(new Contact(Id = objLead.Active_Lead_Contact_Id__c, Personal_Email__c = objLead.Email, MobilePhone = objLead.MobilePhone));
            }
            try{
                if(!contactsToUpdate.isEmpty()){
                    update contactsToUpdate;
                }
            }
            catch(Exception e) {
				nebula.logger.exception(e.getMessage(), e);
			}
        }

    }
    /**
     * @author : [Babyshark]
     * @description : 
     * - ManageLCAOnCourseChange - Create LCA record automatically when Primary Course on Lead is updated
     * @date : 21/11/2024
     * @rev
     * 
     */
    public class ManageLCAOnCourseChange extends TriggerAbstract{

        List<Lead> leadstoProcess = new List<Lead>();
        Map<String, Lead_Course_Association__c> existingLCAs =  new Map<String, Lead_Course_Association__c>();
        Map<Id,Id> leadCourseMap = new Map<Id,Id>();
        //Check for change in Primary Course Asssociate field on Lead
        public override void process(SObject sobj, SObject oldRec) {
            Lead newRecord = (Lead) sobj;
            Lead oldRecord = (Lead) oldRec;
            if(runOnce && (newrecord.Primary_Course_Master_Associated__c != oldRecord.Primary_Course_Master_Associated__c) &&  newrecord.Primary_Course_Master_Associated__c != null){
                leadstoProcess.add(newRecord);
                leadCourseMap.put(newRecord.Id, newRecord.Primary_Course_Master_Associated__c);
            }
        }
        public override void execute() {
            List<Lead_Course_Association__c> lcasToUpdate = new List<Lead_Course_Association__c>();
            List<Lead> leadList = [SELECT Id, Last_Course_Associated_Date__c, Primary_Course_Master_Associated__c,Number_of_Associated_Courses__c,
								(SELECT Id, IsLatestCourseAssociation__c, CreatedDate, Course_Master__c,
								 		IsLatestPrimary__c, Last_Associated_Rank__c, Lead__c
								 FROM Lead_Courses_Association__r
								 )
								FROM Lead
								WHERE Id IN :leadstoProcess];
            List<Lead> leadsToUpdate = new List<Lead>();
            for(Lead objLead : leadList){
                Boolean courseFound = false;
                Decimal maxRank = 0;
                /**
                 * Checks for existing LCAs associated and update below
                 * 1. Update existing LCA as Primary if already present
                 * 2. Update last associated, primary field on other LCAs
                 * 3. Create New LCA if not already present on Lead
                 */ 
                for(Lead_Course_Association__c objLCA : objLead.Lead_Courses_Association__r){
                    if(leadCourseMap.containsKey(objLead.Id) && leadCourseMap.get(objLead.Id) == objLCA.Course_Master__c){
                        courseFound = true;
                        lcasToUpdate.add(new Lead_Course_Association__c(Id=objLCA.Id,
                            IsLatestPrimary__c = true,
                            IsLatestCourseAssociation__c = true,
                            Associated_Date__c =  System.now()));
                    }else{
                        lcasToUpdate.add(new Lead_Course_Association__c(Id=objLCA.Id,
                            IsLatestPrimary__c = false,
                            IsLatestCourseAssociation__c = false));
                    }
                    //Calculate maximum rank available on LCA
                    maxRank = maxRank < objLCA.Last_Associated_Rank__c ? objLCA.Last_Associated_Rank__c : maxRank;
                }
                if(!courseFound){
                    lcasToUpdate.add(new Lead_Course_Association__c(
                        Course_Master__c = objLead.Primary_Course_Master_Associated__c, 
                        Lead__c = objLead.Id,
                        IsLatestPrimary__c = true,
                        Associated_Date__c =  System.now(),
                        IsLatestCourseAssociation__c = true,
                        Last_Associated_Rank__c = maxRank+1));
                    leadsToUpdate.add(new Lead(Id=objLead.Id, Number_of_Associated_Courses__c = objLead.Number_of_Associated_Courses__c+1));
                }
            }
            try{
                runOnce = false;
                if(!lcasToUpdate.isEmpty()){
                    /**Diable LCA Triggers as this is not applicablw while Business User is overriding the LCA functionality 
                     * with Primary_Course_Master_Associated__c field */
                    TriggerCommon.disableTrigger('Lead_Course_Association__c');
                    upsert lcasToUpdate;
                    if(!leadsToUpdate.isEmpty())
                    update leadsToUpdate;
                    TriggerCommon.enableTrigger('Lead_Course_Association__c');
                }
            }
            catch(Exception e) {
				nebula.logger.exception(e.getMessage(), e);
			}
        }
    }
}