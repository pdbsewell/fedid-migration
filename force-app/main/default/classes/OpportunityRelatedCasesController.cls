/**
* @author Inderpal Dhanoa
* @date 25 03 2021
* @description Class retrieves Related Enquiries on an Opportunity
**/
public with sharing class OpportunityRelatedCasesController {
    /**
    * @author Inderpal Dhanoa
    * @date 25 03 2021
    * @description Method checks access on an Opportunity and then retrieves   
    **/
    @AuraEnabled
    public static List<Case> getRelatedCases(Id opportunityId) {
        try {
            List<Case> l_relatedCases = new List<Case>();
            List<Opportunity> l_relatedOpportunity = [SELECT Id FROM Opportunity WHERE Id = :opportunityId];
            if(!l_relatedOpportunity.isEmpty() && l_relatedOpportunity.size() == 1){
                GetAllEnterpriseCases enterpriseCases = new  GetAllEnterpriseCases();
                l_relatedCases = enterpriseCases.getOpportunityCases(opportunityId);
            }
            system.debug('@@@@l_casesWithAccess'+l_relatedCases);
            return l_relatedCases;
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }

    /**
    * @author Inderpal Dhanoa
    * @date 31 03 2021
    * @description Class retrieves in Without sharing all Related Enterprise Enquiries on an Opportunity
    **/
    public without sharing class GetAllEnterpriseCases{
        public List<Case> getOpportunityCases(Id opportunityId) {
            Id enterperisePrivateCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(); 
            return [SELECT Id,CaseNumber,Case_Owner_String__c,Type,MonashCollege_Outcome__c,Status FROM Case WHERE Opportunity__c = :opportunityId
                    AND RecordTypeId = :enterperisePrivateCaseRecordTypeId ORDER BY CreatedDate DESC];
        }
    } 
}