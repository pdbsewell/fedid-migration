/**
* @author Inderpal Dhanoa
* @date 10.Feb.2024
* @group Monash Connect
* @description  Class to submit Provide Enrolment Info
*/
public with sharing class ProvideEnrolmentInfoController {
    /*
     * Method Name: submitEnquiryDetails
     * @param  s_description - Enquiry Description
     * @param  s_staffOrgUnit - Enquiry Staff Org Unit
     * @param  s_reqType - Enquiry Req Type
     * @param  s_howManyIndivStudents - Enquiry how Many Indiv Students
     * @param  s_details - Enquiry details
     * @param  s_caseRecId - Enquiry Case Id
     * Description: method to Submit Case details
    */
    @AuraEnabled
    public static string submitEnquiryDetails(String s_description, String s_staffOrgUnit, String s_reqType, String s_howManyIndivStudents, String s_details, String s_caseRecId){
        try {
            Case linkedEnq = [SELECT Id, Staff_Organisation_Unit__c, Request_Type__c, How_many_individual_student_records__c, Details__c, Description,Rich_Description__c
                             FROM CASE 
                             WHERE Id = : Id.valueOf(s_caseRecId)];
            linkedEnq.Staff_Organisation_Unit__c = s_staffOrgUnit;
            linkedEnq.Request_Type__c = s_reqType;
            linkedEnq.How_many_individual_student_records__c = Integer.valueOf(s_howManyIndivStudents);
            linkedEnq.Details__c = s_details;
            if(String.isBlank(linkedEnq.Description)){
                linkedEnq.Description = s_description;
            }else{
                linkedEnq.Description = linkedEnq.Description + '\n \n' + '---------------------------------' + '\n \n' + s_description;
            }            
            linkedEnq.Rich_Description__c = String.valueOf(Label.MC_Enrolment_Details);
            update linkedEnq;
            return 'Success';
        } catch (Exception e) {
            LogUtilityException.logException(e,'ProvideEnrolmentInfoController submitEnquiryDetails');throw e;
        }
    }

    /*
     * Method Name: retrieveEnquiryDetails
     * @param  s_caseRecId - Enquiry Case Id
     * Description: method to retrieve Case details
    */
    @AuraEnabled
    public static EnquiryWrapper retrieveEnquiryDetails(String s_caseRecId){
        try {
            Case linkedEnq = [SELECT Id, Staff_Organisation_Unit__c, Request_Type__c, How_many_individual_student_records__c, Details__c
                             FROM CASE 
                             WHERE Id = : Id.valueOf(s_caseRecId)];
            EnquiryWrapper o_EnqWrap = new EnquiryWrapper();
            o_EnqWrap.details = linkedEnq.Details__c;
            o_EnqWrap.indivStudentsRecd = linkedEnq.How_many_individual_student_records__c;
            o_EnqWrap.reqType = linkedEnq.Request_Type__c;
            o_EnqWrap.staffOrgUnit = linkedEnq.Staff_Organisation_Unit__c;
            return o_EnqWrap;
        } catch (Exception e) {
            LogUtilityException.logException(e,'ProvideEnrolmentInfoController retrieveEnquiryDetails');throw e;
        }
    }

    public class EnquiryWrapper{
        @AuraEnabled
        public String staffOrgUnit;
        @AuraEnabled
        public String reqType;
        @AuraEnabled
        public Decimal indivStudentsRecd;
        @AuraEnabled
        public String details;
    }
}