/**
* Handler Class to check/uncheck has_attachment checkbox on cases when an attachment is added/deleted on a case. 
* 
* @author Veera, PwC
* 
*/
public class AttachmentTriggerHandler {

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         19.May.2017       
    * @description  method to handle after insert logic on Attachments
    * @revision         
    *******************************************************************************/

    public static void handleAfterInsert(list<attachment> triggerNew) {
        list<case> caseUpdateList =new list<case>();
        Map<id,case> caseRecMap = getCaseRecords(triggerNew);

        if(!caseRecMap.isEmpty()) {
            for(case cas: caseRecMap.values()) {
                if(cas.Has_Attachment__c==false) {
                    cas.Has_Attachment__c = true;
                }
                caseUpdateList.add(cas);
            }
        }

        if(!caseUpdateList.isEmpty()) {
            Database.SaveResult[] srList = database.update(caseUpdateList,false);

            for(database.SaveResult sr: srList) {
                if(!sr.issuccess()) {
                    for(database.Error err: sr.getErrors()){
						nebula.logger.error(err.getMessage(), sr);
                    }
                }
            }
            nebula.logger.saveLog();
        }

        //DCXCRM-1950 - Decommission Workflow: Created - Web - Research Deferral Request and include attachment on sending email to Faculty
        AttachmentTriggerHandler.mgeDefaultValuesIncludeAttachmentOnEmailToFaculty(triggerNew);
    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         19.May.2017       
    * @description  method to handle after delete logic on Attachments
    * @revision     
    *******************************************************************************/
    public static void handleAfterDelete(list<attachment> triggerOld) {
        list<case> caseUpdateList =new list<case>();
        set<string> casRecordtypeSet = getCaseRecordtypes();
        set<id> caseIdSet = new set<id>();
        //Map<id,case> caseRecMap = getCaseRecords(triggerOld);
        //
        if(!triggerOld.isEmpty()) {
            for(attachment att: triggerOld) {
                if(string.valueOf(att.parentId.getSObjectType())=='Case') {
                    caseIdSet.add(att.ParentId);
                }
            }
        }

        if(!caseIdSet.isEmpty()) {
            for(case cas:[select id,Has_Attachment__c,(select id from attachments) from case where id in :caseIdSet and recordtype.name in :casRecordtypeSet]) {
                if(cas.attachments.size() == 0 && cas.Has_Attachment__c == true) {
                    cas.Has_Attachment__c = false;
                    caseUpdateList.add(cas);
                }
            }
        }

        if(!caseUpdateList.isEmpty()) {
            Database.SaveResult[] srList = database.update(caseUpdateList,false);

            for(database.SaveResult sr: srList) {
                if(!sr.issuccess()){
                    for(database.Error err: sr.getErrors()) {
						nebula.logger.error(err.getMessage(), sr);
                    }
                }
            }
            nebula.logger.saveLog();
        }

    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         19.May.2017       
    * @description  method to return case records required to update check.
    * @revision     
    *******************************************************************************/
    static map<id,case> getCaseRecords(List<attachment> attList) {
        map<id,case> caseMap = new map<id,case>();
        set<id> caseIdSet = new set<id>();
        set<string> casRecordtypeSet = getCaseRecordtypes();

        for(Attachment att:attList) {
            if(string.valueOf(att.parentId.getSObjectType())=='Case') {
                caseIdSet.add(att.parentId);
            }
        }

        if(!caseIdSet.isEmpty()) {
            for(case cas:[select id,Has_Attachment__c from case where id in :caseIdSet and recordtype.name in :casRecordtypeSet]) {
                caseMap.put(cas.id,cas);
            }
        }

        return caseMap;
    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         19.May.2017       
    * @description  method to return case records type developer name from custom setting.
    * @revision     
    *******************************************************************************/

    static set<string> getCaseRecordtypes() {
        set<string> casRecordtypeSet = new set<string>();
        for(Case_RecordType_CS__c hasAttach: Case_RecordType_CS__c.getAll().values()) {
            if(hasAttach.Has_Attachment_Trigger__c == true) {
                casRecordtypeSet.add(hasAttach.Recordtype_Name__c);
            }
        }
        return casRecordtypeSet;
    }

    /**
     * @author                  Kristian Vegerano
     * @description             Method that sends an email to faculty which includes the attachment submitted from the form
     * @param attachmentList    Trigger.new context variable
     */
    public static void mgeDefaultValuesIncludeAttachmentOnEmailToFaculty(List<Attachment> attachmentList) {
        //Initialize Variables
        Set<Id> parentEnquiryIds = new Set<Id>();
        List<Case> enquiryMgroList = new List<Case>();

        //Retrieve attachment parent enquiry ids
        for(Attachment loopAttachment : attachmentList){
            parentEnquiryIds.add(loopAttachment.parentId);
        }

        //Filter records on the trigger context
        //Check if there is a file uploaded from the mgro form - email send was not handled on case trigger so that this attachment service would handle email send
        for(Case loopCase : [SELECT Id, Origin, RecordTypeId, Faculty_Email__c, Supplied_Supervisors_Email__c, ContactId, File_Attachment__c
        FROM Case
        WHERE Id IN :parentEnquiryIds
        AND RecordType.DeveloperName = 'MGE_Enquiry'
        AND Origin = 'Web - Research Deferral Request'
        AND File_Attachment__c != null]){
            //Include filtered enquiries submitted via mgro form
            enquiryMgroList.add(loopCase);
        }

        //Process enquiries
        if(enquiryMgroList.size() > 0){
            //Queue sending faculty email to include attachments
            Queueable queueItem = new CaseServices.mgeSendEmailToFacultyQueueable(enquiryMgroList);
            ID jobID = System.enqueueJob(queueItem);
        }
    }
}