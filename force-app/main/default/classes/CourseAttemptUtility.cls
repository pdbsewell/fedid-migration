/**
 * @author			inderpal.dhanoa@monash.edu
 * @group			MOnash Connect
 * @description		Service class for Course_Attempt__c object operations .
 */
public with sharing class CourseAttemptUtility {
    /*
     * @author			Inderpal Dhanoa
     * @description		Auto closes OCR if Decision moves to already Enrolled
     */
    @future
    public static void closeLinkedOCRS(Set<Id> contactId){
        Id monConSuppRecTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support')?.getRecordTypeId();
        String ocrQueueDevName = 'Autoclosed_OCRs_Retention';
        String decision = 'Already Enrolled';
        String engType = 'Conversion';
        String closedCallStatus = 'Closed';
        String callResult = 'No Follow Up Required'; 
        String noCallAttempts = '0';
        List<Outbound_Call_Result__c> closeOCR = new List<Outbound_Call_Result__c>();
        Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :ocrQueueDevName LIMIT 1].Id;
        for(Outbound_Call_Result__c ocr :  [SELECT Id, OwnerId,  Call_Status__c, Call_Result__c,Retention_Status__c
                                            FROM Outbound_Call_Result__c 
                                            WHERE Contact__c IN :contactId AND
                                            Engagement_Type__c = :engType AND 
                                            RecordTypeId = :monConSuppRecTypeId AND
                                            Call_Status__c != :closedCallStatus AND
                                            Number_Of_Attempts__c = :noCallAttempts]){
            closeOCR.add(new Outbound_Call_Result__c(Id = ocr.Id, OwnerId = queueId, Call_Status__c = closedCallStatus, Call_Result__c = callResult, Retention_Status__c = decision));
        }
        // Close the linked OCR's
        if(!closeOCR.isEmpty()){
            try{
                update closeOCR;
            }Catch(Exception ex){
                Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog();
            }
        }
    }
}