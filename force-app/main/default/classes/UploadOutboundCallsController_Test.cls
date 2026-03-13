/**
 * @author			Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group			SRA (Student Recruitment and Admissions) - BabyShark
 * @description		EPBBS-1220 Test class for the custom upload process of SRA outbound calls.
 * @revision		ayush.agrawal@monash.edu - EPBBS-1337 - Support for Contact ID during upload process.
 *                  RANAND updated existing methods to incorporate new parameters and test bulk creation of Pre-App OCRs
 */

@isTest(isParallel=true)
private class UploadOutboundCallsController_Test {

    @testSetup
    static void setup() {
        // Campaign
        Campaign campaign_1 = new Campaign(
        	Name = 'One',
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Outbound_Call').getRecordTypeId(),
        	StartDate = Date.today(),
            Type = 'International Pre App'
        );
        Campaign campaign_2 = new Campaign(
            Name = 'Two',
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Outbound_Call').getRecordTypeId(),
            StartDate = Date.today(),
            Type = 'International Post App'
        );
        insert new Campaign[]{campaign_1, campaign_2};
        
        // Contact
        Contact contact_1 = new Contact(
            LastName = 'LastName',
            Person_Id_Unique__c = '1'
        );
        insert contact_1;
        Lead leadRec = TestHelper.createLeads(1)[0];
        leadRec.Active_Lead_Contact_Id__c = contact_1.Id;
        leadRec.Contact__c = contact_1.Id;
        
        TriggerCommon.disableTrigger('Lead');
        insert leadRec;
        TriggerCommon.enableTrigger('Lead');
    }

    @IsTest
    static void testGetCampaignType() {
        Test.startTest();

        String campaignType = UploadOutboundCallsController.getCampaignType([
            SELECT Id FROM Campaign WHERE Type = 'International Pre App' LIMIT 1].Id
        );

        Test.stopTest();

        System.assertEquals('International Pre App',
            campaignType,
            'getCampaignType is not functioning properly.');
    }

    @IsTest
    static void testPreApp() {
        Campaign campaign_1 = [SELECT Id FROM Campaign WHERE Type = 'International Pre App' LIMIT 1];
        UploadOutboundCallsController.Record r1 = new UploadOutboundCallsController.Record();
        r1.contact_reference_id = '1';
        UploadOutboundCallsController.Records records = new UploadOutboundCallsController.Records();
        records.contact_reference_type = 'person_id';
        records.records = new UploadOutboundCallsController.Record[]{r1};

        Test.startTest();
        
        UploadOutboundCallsController.uploadOutboundCalls(campaign_1.Id, JSON.serialize(records));
        
        Test.stopTest();

        System.assertEquals(true, UploadOutboundCallsController.testSuccess);
        System.assertEquals(1,
                            [SELECT Id FROM Outbound_Call_Result__c WHERE Campaign__c = :campaign_1.Id].size(),
                            'Outbound calls are not being uploaded.');
        System.assertEquals('1', UploadOutboundCallsController.testRecords.records[0].contact_reference_id);
        System.assertEquals('OK', UploadOutboundCallsController.testRecords.records[0].result);
    }

    @IsTest static void testPostApp() {
        // Arrange
        insert new Application_Course_Preference__c();
        Application_Course_Preference__c acp = [SELECT ACP_ID__c FROM Application_Course_Preference__c LIMIT 1];
        Campaign postCampaign = [SELECT Id FROM Campaign WHERE Type = 'International Post App' LIMIT 1];

        UploadOutboundCallsController.Record r1 = new UploadOutboundCallsController.Record();
        r1.contact_reference_id = '1';
        r1.acp_id = acp.ACP_ID__c;
        UploadOutboundCallsController.Record r2 = new UploadOutboundCallsController.Record();
        r2.contact_reference_id = '1';
        r2.acp_id = acp.ACP_ID__c;
        UploadOutboundCallsController.Records recordsGood = new UploadOutboundCallsController.Records();
        recordsGood.contact_reference_type = 'person_id';
        recordsGood.records = new UploadOutboundCallsController.Record[]{r1,r2};

        UploadOutboundCallsController.Record r3 = new UploadOutboundCallsController.Record();
        r3.contact_reference_id = '1';
        r3.acp_id = acp.ACP_ID__c + 'XX'; // does not exist
        UploadOutboundCallsController.Records recordsBad = new UploadOutboundCallsController.Records();
        recordsBad.contact_reference_type = 'person_id';
        recordsBad.records = new UploadOutboundCallsController.Record[]{r3};

        // Act
        UploadOutboundCallsController.uploadOutboundCallsNow(postCampaign.Id, recordsGood.records, recordsGood.contact_reference_type);
        // Assert
        System.assertEquals(true, UploadOutboundCallsController.testSuccess);
        System.assertEquals('OK', UploadOutboundCallsController.testRecords.records[0].result);
        System.assertEquals('Skipped - Duplicate', UploadOutboundCallsController.testRecords.records[1].result);

        // Act
        UploadOutboundCallsController.uploadOutboundCallsNow(postCampaign.Id, recordsBad.records, recordsGood.contact_reference_type);
        // Assert
        System.assertEquals(true, UploadOutboundCallsController.testSuccess);
        System.assertNotEquals('OK', UploadOutboundCallsController.testRecords.records[0].result);
        System.debug(UploadOutboundCallsController.testRecords.records[0].result);
    }

    @IsTest static void testErrors() {
        // Arrange
        Campaign campaign_1 = [SELECT Id FROM Campaign WHERE Type = 'International Pre App' LIMIT 1];
        UploadOutboundCallsController.Record r1 = new UploadOutboundCallsController.Record();
        r1.contact_reference_id = '1';
        UploadOutboundCallsController.Record r2 = new UploadOutboundCallsController.Record();
        r2.contact_reference_id = '2';
        UploadOutboundCallsController.Records records = new UploadOutboundCallsController.Records();
        records.contact_reference_type = 'person_id';
        records.records = new UploadOutboundCallsController.Record[]{r1,r2};

        // Act
        UploadOutboundCallsController.uploadOutboundCallsNow(campaign_1.Id, records.records, records.contact_reference_type);

        // Assert
        System.assertEquals(false, UploadOutboundCallsController.testSuccess);
        System.assertEquals('OK', UploadOutboundCallsController.testRecords.records[0].result);
        System.assertNotEquals('OK', UploadOutboundCallsController.testRecords.records[1].result);
        System.debug(UploadOutboundCallsController.testRecords.records[1].result);
    }

    @IsTest static void validateCSV() {
        // Arrange
        UploadOutboundCallsController.Record r1 = new UploadOutboundCallsController.Record();
        r1.contact_reference_id = '111_1';
        r1.acp_id = '111_2';
        r1.result = 'Skipped';
        UploadOutboundCallsController.Record r2 = new UploadOutboundCallsController.Record();
        r2.contact_reference_id = '222_1';
        r2.acp_id = '222_2';
        r2.result = '';
        UploadOutboundCallsController.Records records = new UploadOutboundCallsController.Records();
        records.contact_reference_type = 'contact_id';
        records.records = new UploadOutboundCallsController.Record[]{r1,r2};

        // Act
        String csv01 = UploadOutboundCallsController.generateCSV(records, true);
        records.contact_reference_type = 'person_id';
        String csv02 = UploadOutboundCallsController.generateCSV(records, true);
        String csv03 = UploadOutboundCallsController.generateCSV(records, false);

        // Assert
        System.assertEquals('contact_id, acp_id, result\n111_1,111_2,Skipped\n222_1,222_2,', csv01);
        System.assert(csv02.startsWith('person_id'), 'Incorrect column in header: ' + csv02.substringBefore('\n'));
        System.assert(csv03.startsWith('person_id, result\n'), 'Incorrect column in header: ' + csv03.substringBefore('\n'));
    }
    /**Testing Outbound call record creation for pre app including automated creation of Case scenario */
    @IsTest static void test_BulkOCR() {
        //Given - Contact and Campaign already present in org
        List<Contact> conList = new List<Contact>();
        for(Integer i=1; i<50; i++){
            Contact contact_1 = new Contact(
                                    LastName = 'LastNameTest'+i,
                                    Person_Id_Unique__c = String.valueOf(10+i));
            conList.add(contact_1);
        }
        TriggerCommon.disableTrigger('Contact');
        insert conList;
        TriggerCommon.enableTrigger('Contact');
        
        Campaign campaign_1 = [SELECT Id FROM Campaign WHERE Type = 'International Pre App' LIMIT 1];
        
        UploadOutboundCallsController.Records records = new UploadOutboundCallsController.Records();
        List<UploadOutboundCallsController.Record> recList = new List<UploadOutboundCallsController.Record>();
        for(Contact objCon : conList){
            UploadOutboundCallsController.Record r1 = new UploadOutboundCallsController.Record();
        	r1.contact_reference_id = objCon.Id;
            recList.add(r1);
        }
        records.records = recList;
        
        //When - serialized list of contact id with campaign is received then the calling method should create Outbpud calls against each contact
        Test.startTest();
        UploadOutboundCallsController.uploadOutboundCalls(campaign_1.Id, JSON.serialize(records));
        Test.stopTest();
        
        //Then -  Compare the outcome of calling method
       	Assert.areEqual(true, UploadOutboundCallsController.testSuccess);
        Assert.areEqual('OK', UploadOutboundCallsController.testRecords.records[0].result);

    }

}