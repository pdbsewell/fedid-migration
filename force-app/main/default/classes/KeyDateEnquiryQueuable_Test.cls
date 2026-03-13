@isTest (isParallel=true)
public class KeyDateEnquiryQueuable_Test {   
    @isTest
    public static void testSyncKeyDatesforEnquiry(){
		//.. GIVEN
        Key_Date__c oKeyDate = new Key_Date__c ();
        oKeyDate.Due_Date__c = System.today();
        oKeyDate.Name = 'KeyDate for MRO Team';
        insert oKeyDate;
        
		Case oCase1 = new Case();
        oCase1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
        oCase1.Subject = 'Case1-Keydates';
        oCase1.Description = 'KeyDates Sync';
		oCase1.Enquiry_Key_Date__c = oKeyDate.Id;
        
        TriggerCommon.disableTrigger('Case');
        insert oCase1;        
        TriggerCommon.enableTrigger('Case');
        
        //.. WHEN
        Test.startTest();
        System.enqueueJob(new KeyDateEnquiryQueuable(oKeyDate.Id, oKeyDate.Due_Date__c));
        Test.stopTest();
		
        //.. THEN
        Case oCase = [SELECT Id, KeyDate_Date__c FROM Case WHERE Subject = 'Case1-Keydates' LIMIT 1];
		Assert.areEqual(oCase.KeyDate_Date__c, oKeyDate.Due_Date__c, 'Keydate update for all the enquiries');
    }
}