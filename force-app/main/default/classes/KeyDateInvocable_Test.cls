@isTest (isParallel=true)
public class KeyDateInvocable_Test {
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
        
        List<KeyDateInvocable.KeyDateRequest> lstKeyDateRequest = new List<KeyDateInvocable.KeyDateRequest>();
        
        KeyDateInvocable.KeyDateRequest oRequest = new KeyDateInvocable.KeyDateRequest();
		oRequest.idKeyDateId = oKeyDate.Id;
        oRequest.dKeyDate_Date = oKeyDate.Due_Date__c;
        lstKeyDateRequest.add(oRequest);
        
        List<String> lstResponse = new List<String>();
        
        //.. WHEN
        Test.startTest();
        lstResponse = KeyDateInvocable.updateEnquiryKeyDate(lstKeyDateRequest);
        Test.stopTest();
		
        //.. THEN
        Case oCase = [SELECT Id, KeyDate_Date__c FROM Case WHERE Subject = 'Case1-Keydates' LIMIT 1];
		Assert.areEqual(oCase.KeyDate_Date__c, oKeyDate.Due_Date__c, 'Keydate update for all the enquiries');
    }

}