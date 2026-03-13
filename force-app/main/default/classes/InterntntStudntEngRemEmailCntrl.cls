/**
 * @author Inderpal Dhanoa
 * @date 15.Sep.2023
 * @description Class for Monash Connect to send out Bulk Reminder mails for U18 Students.
 * @group Monash Connect
 * @revision    Inderpal D, 15.Sep.2023 - Initial Version
 */
public with sharing class InterntntStudntEngRemEmailCntrl {
    /*
     * Method Name: sendReminderEmail
     * @param  String for campaignRecordId
     * @param  List<String> for caseRecordId
     * Description: method to initiate reminder Email
    */
    @AuraEnabled
    public static String sendReminderEmail(String campaignRecordId, List<String> l_revisedCaseIdList){
        try{
            Set<Id> s_revisedCaseIdList = new Set<Id>();
            for(String contId : l_revisedCaseIdList){
                s_revisedCaseIdList.add(Id.valueOf(contId));
            }
            if(!s_revisedCaseIdList.isEmpty()){
                // Batch Size Limited to 1 : First exception on row 1; first error: LIMIT_EXCEEDED, System.LimitException: Too many queueable jobs added to the queue: 2
                BatchMCISERemndrNotifcn obj = new BatchMCISERemndrNotifcn(Id.valueOf(campaignRecordId), s_revisedCaseIdList);
                Database.executeBatch(obj, 1);
            }
            return 'Success';
        }catch(Exception ex){
            throw ex;
        }        
    }

    /*
     * Method Name: filterRecepients
     * @param  String for campaignRecordId
     * Description: method to filter Recepients based on whether Invites have been accepted
    */
    @AuraEnabled
    public static List<Id> filterRecepients(String campaignRecordId){
        // Check all Enquiries for which Calendly Events are not accepted
        Set<Id> s_allEnqs = new Set<Id>();
        Set<Id> s_enqWithEvntsBkd = new Set<Id>();
        Id campId = Id.ValueOf(campaignRecordId);
        Set<Id> s_enqWithEvntsBkngPending = new Set<Id>();
        String S_EVENT_TAG = String.ValueOf(Label.MC_ISE_Calendly_Link), S_ISE_CAMP_RECTYPE_DEVNAME = 'International_Students_Engagement',
                            S_ISE_ENQ_RECTYPE_DEVNAME = 'SS_InternationalStudentEngagement', S_ENQ_TYPE = 'Current Course', S_CATG_LEVEL_1 = 'Under 18s', 
                            S_CATG_LEVEL_2 = 'Welfare meetings', ENQ_STATUS = 'Open';
        for(Case enq : [SELECT Id, ContactId, Contact.Email, First_Name_case_corrected__c 
                        FROM CASE 
                        WHERE Campaign__c = :campId 
                        AND Campaign__r.RecordType.DeveloperName = :S_ISE_CAMP_RECTYPE_DEVNAME AND RecordType.DeveloperName = :S_ISE_ENQ_RECTYPE_DEVNAME 
                        AND Enquiry_Type__c = :S_ENQ_TYPE AND Category_Level_1__c = :S_CATG_LEVEL_1 
                        AND Category_Level_2__c = :S_CATG_LEVEL_2 AND Status = :ENQ_STATUS]){
            s_allEnqs.add(enq.Id);
        }
        // Check Enquiries created by Booking conf
        for(Event_Booking__c evtBkd : [SELECT Id,Case__c, Case__r.ContactId, Case__r.Contact.name, Case__r.Contact.Email 
                                       FROM Event_Booking__c 
                                       WHERE Case__c IN :s_allEnqs]){
            s_enqWithEvntsBkd.add(evtBkd.Case__c);
        }
        // Check Enq with no Evnts bkd
        for(Id caseId : s_allEnqs){
            if(!s_enqWithEvntsBkd.contains(caseId)){
                s_enqWithEvntsBkngPending.add(caseId);
            }
        }
        if(s_enqWithEvntsBkngPending.isEmpty()){
            return null;
        }else{
            return new List<Id>(s_enqWithEvntsBkngPending);
        }
    }
}