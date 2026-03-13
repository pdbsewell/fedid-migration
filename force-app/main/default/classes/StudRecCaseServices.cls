/**
 * @description Student Recruitment Services class to provide Case sObject centric logical support
 * @revision
 *  MAR.01.2019     APRivera    - Created
 */
public class StudRecCaseServices {

    public static Id POST_APPLICATION_RECTYPEID {
        get {
            if(POST_APPLICATION_RECTYPEID == null) POST_APPLICATION_RECTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Application_Enquiry').getRecordTypeId();
            return POST_APPLICATION_RECTYPEID;
        }
        set;
    }

    //Associated the enquiry to a contact record via the Monash Student ID field
    public static void associateContactToPostApplicationEnquiries(List<Case> lstCases, Set<String> setMonashStudentIds, Set<String> setApplicationIds){
        //Retrieve contacts
        Map<String, Contact> contactIdsMap = new Map<String, Contact>();
        if(setMonashStudentIds.size() > 0){
            for(Contact loopContact : [SELECT Id, Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c IN :setMonashStudentIds]){
                contactIdsMap.put(loopContact.Person_ID_unique__c, loopContact);
            }
        }
        Map<String, Application_Course_Preference__c> applicationToContactMap = new Map<String, Application_Course_Preference__c>();
        if(setApplicationIds.size() > 0){
            for(Application_Course_Preference__c loopACP : [SELECT Id, Callista_Applicant_Id__c, ContactId__c FROM Application_Course_Preference__c WHERE Callista_Applicant_Id__c IN :setApplicationIds]){
                applicationToContactMap.put(loopACP.Callista_Applicant_Id__c, loopACP);
            }
        }

        //Associate contact
        for(Case caseRecord : lstCases){
            if(caseRecord.Monash_Student_Form_ID__c != null && contactIdsMap.containsKey(caseRecord.Monash_Student_Form_ID__c)){
                caseRecord.ContactId = contactIdsMap.get(caseRecord.Monash_Student_Form_ID__c).Id;
            }
            if(caseRecord.Monash_Application_ID__c != null && applicationToContactMap.containsKey(caseRecord.Monash_Application_ID__c)){
                caseRecord.ContactId = applicationToContactMap.get(caseRecord.Monash_Application_ID__c).ContactId__c;
            }
        }

    }


}