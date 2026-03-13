/**
 * @description contains the queries for APNG Webservices
 * @author      Nick Guia
 * @since       25/09/2023
 * @group       Admissions
 */
public with sharing class APNG_WebServiceSelector {

    public APNG_WebServiceSelector() { }

    /**
     * @description query case details based on the case number
     * @param caseNumber 
     * @return `Case`
     */
    public Case selectCaseDetailsByCaseNumber(String caseNumber) {
        return [SELECT
                    Id, // --- Case Details
                    Origin,
                    CaseNumber,
                    Status,
                    Subject,
                    RecordTypeId,
                    RecordType.Name,
                    Enquiry_Type__c,
                    Category_Level_1__c,
                    Category_Level_2__c,
                    Owner.Name,
                    Flag_Owner_Is_Queue__c,
                    IsClosed,
                    CreatedDate,
                    Createdby.Name,
                    LastModifiedDate,
                    Description,
                    Uuid__c,
                    ContactId, // --- Applicant Details
                    Contact.Crm_id__c,
                    Contact.Name,
                    Contact.First_Name__c,
                    Contact.Last_Name__c,
                    Contact.Person_Id__c,
                    Application_Course_Preference__c, // --- ACP and Application Details
                    Application_Course_Preference__r.Name,
                    Application_Course_Preference__r.Application__c,
                    Application_Course_Preference__r.ACP_Id__c,
                    Application_Course_Preference__r.Application__r.Name,
                    External_Stakeholder__c, // --- Agency Details
                    External_Stakeholder__r.Name, 
                    External_Stakeholder__r.Email__c,
                    External_Stakeholder__r.Callista_Org_Unit_Code__c, 
                    Initiated_By__c, // --- Agent Details
                    Initiated_By__r.Name, 
                    Initiated_By__r.Email, 
                    Initiated_By__r.Account_Name__c 
            FROM Case
            WHERE CaseNumber = :caseNumber
                AND is_Visible_to_External_Stakeholder__c = true // hidden enquiries
            LIMIT 1];
    }

    /**
     * @description query CaseFeed and FeedComments related to the Case
     * @param caseNumber 
     * @return `List<CaseFeed>`
     */
    public List<CaseFeed> selectCaseFeedByCaseNumber(String caseNumber) {
        return [SELECT 
                    Id, 
                    CreatedBy.FirstName, 
                    CreatedBy.LastName, 
                    Body, 
                    CreatedDate, 
                    LastModifiedDate
                FROM CaseFeed
                WHERE Parent.CaseNumber = :caseNumber
                AND Visibility = 'AllUsers'
                AND Type = 'TextPost'];
    }
}