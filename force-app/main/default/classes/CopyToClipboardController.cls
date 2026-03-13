/*
 * @author			ayush.agrawal@monash.edu
 * @description		SA-372 Copy to clipboard implementation for only Case Unit Attempt with a set number of
 * 					fields. Future possibility to make this generic.
 * @group			Student Administration
 */

public with sharing class CopyToClipboardController {

    @AuraEnabled(cacheable=true)
    public static String getRecordDetails(Id recordId) {
        try {
            Boolean nop;
            
            Case_Unit_Attempt__c cua = [SELECT
                                        Id,
                                        Assessment_Due_Date_New__c,
                                        Assessment_Due_Date_Original__c,
                                        Assessment_Name__c,
                                        Assessment_Type__c,
                                        Unit_Attempt__c,
                                        Unit_Attempt__r.Title__c,
                                        Unit_Attempt__r.Unit_Code__c,
                                        Unit_Code__c
                                        FROM Case_Unit_Attempt__c
                                        WHERE Id = :recordId
                                        LIMIT 1];
            
            return JSON.serialize(cua);
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }
    
}