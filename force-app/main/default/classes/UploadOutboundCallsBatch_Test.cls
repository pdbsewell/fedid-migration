/**
 * @author			RANAND updated existing methods to incorporate new parameters and test bulk creation of Pre-App OCRs
 * @group			SRA (Student Recruitment and Admissions) - BabyShark
 * @description		EPBBS-3177 Test class for the custom upload process of SRA outbound calls.
 * @revision		
 *                  
 */
@isTest(isParallel=true)
private class UploadOutboundCallsBatch_Test {
	@testSetup static void setup() {
        // Campaign
        Campaign campaign_1 = new Campaign(
        	Name = 'One',
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Outbound_Call').getRecordTypeId(),
        	StartDate = Date.today(),
            Type = 'International Pre App'
        );
        
        insert new Campaign[]{campaign_1};
        
        //Setup Contact and Lead in org for OCR creation
        List<Contact> conList = new List<Contact>();
        List<Lead> leadList = new List<Lead>();
        for(Integer i=1; i<50; i++){
            Contact contact_1 = new Contact(
                                    LastName = 'LastNameTest'+i,
                                    Person_Id_Unique__c = String.valueOf(10+i));
            conList.add(contact_1);
        }
        TriggerCommon.disableTrigger('Contact');
        insert conList;
        TriggerCommon.enableTrigger('Contact');
        
        for(Contact con: conList){
            Lead leadRec = TestHelper.createLeads(1)[0];
            leadRec.LastName = con.LastName;
            leadRec.Active_Lead_Contact_Id__c = con.Id;
            leadRec.Contact__c = con.Id;
            leadList.add(leadRec);
        }
        TriggerCommon.disableTrigger('Lead');
        insert leadList;
        TriggerCommon.enableTrigger('Lead');
        
    }
    /**
	* @description EPBBS-3177 - Test UploadOutboundCallBatch execute method for Case Creation in case of Pre App OCRs 
	**/
    @IsTest static void test_UploadOutboundCallBatchExecute() {
        
        //Given - Contact and Campaign already present in org
        Campaign campaign_1 = [SELECT Id FROM Campaign WHERE Type = 'International Pre App' LIMIT 1];
        
        UploadOutboundCallsController.Records records = new UploadOutboundCallsController.Records();
        List<UploadOutboundCallsController.Record> recList = new List<UploadOutboundCallsController.Record>();
        for(Contact objCon : [SELECT ID FROM Contact]){
            UploadOutboundCallsController.Record r1 = new UploadOutboundCallsController.Record();
        	r1.contact_reference_id = objCon.Id;
            recList.add(r1);
        }
        records.records = recList;
        
        //When - serialized list of contact id with campaign is received then the calling method should create Outbpud calls against each contact
        Test.startTest();
        UploadOutboundCallsBatch batchContext = new UploadOutboundCallsBatch(JSON.serialize(records), campaign_1.Id);
        Database.executeBatch(batchContext);
        Test.stopTest();
        
        //Then -  Compare the outcome of against number of record inserted
       	Assert.areEqual(49, [SELECT Count() FROM Outbound_Call_Result__c WHERE Case__c != null]);
        Assert.areEqual(49, [SELECT Count() FROM Case WHERE RecordType.Name ='Outbound Call']);
       
    }

}