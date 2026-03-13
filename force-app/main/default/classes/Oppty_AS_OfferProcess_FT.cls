/* Test class for Opportunity : AS : Offer Process Flow 
* @author   :   Vinothraja
* @date     :   23/07/2025
* @group    :   Platforms
* @description This class is used to test the Oppty_BS_Handle_Oppty_Updates_FT class
* @revision
*  23-07-2025      Vinothraja    - Initial creation
*/
@isTest(isParallel = false) // Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class Oppty_AS_OfferProcess_FT {
    private static final Id APPLICANT_ENROLMENT_RT = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Applicant Enrolment' LIMIT 1].Id;

    @TestSetup
    static void makeData() {
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(Name = 'testCreateExternalAccount', Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c='123456'), true);
        //Application Creation
        TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id), true);
        TestDataFactory.createSObject(new Country_Attribute__c(Name = 'MALAYSIA'), true);
        //Calendar creation
        Calendar__c calendar = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(), 'TestDataFactorySettings.CalendarDefaults', false);
        insert calendar; 

        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
    }
    // Test method to verify the flow handles opportunity - Generate Offer - during creation correctly
    @isTest
    private static void testGenerateOfferOnOpportunityCreates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                StageName = 'Processing Offer',
                                Bulk_Gen__c = false,
                                NextStep = 'Generate Offer',
                                CloseDate = Date.today().addDays(1)
                            ), false);

        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            insert opp;
        Test.stopTest();    

        // THEN
        // Verify that the Platform Event for Offer Generation was created successfully
        Assert.areEqual('OpportunityEventTrigger', [SELECT Name FROM EventBusSubscriber WHERE Topic='Opportunity_Event__e' AND Type='ApexTrigger' LIMIT 1]?.Name, 'The Apex Trigger - OpportunityEventTrigger - for Opportunity Event should be registered');
    }
    // Test method to verify the flow handles opportunity - Generate Offer - during updation correctly
    @isTest
    private static void testGenerateOfferOnOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                StageName = 'Processing Offer',
                                Bulk_Gen__c = false,
                                CloseDate = Date.today().addDays(1)
                            ), true);

        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            opp.NextStep = 'Generate Offer';
            update opp;
        Test.stopTest();    

        // THEN
        // Verify that the Platform Event for Offer Generation was created successfully
        Assert.areEqual('OpportunityEventTrigger', [SELECT Name FROM EventBusSubscriber WHERE Topic='Opportunity_Event__e' AND Type='ApexTrigger' LIMIT 1]?.Name, 'The Apex Trigger - OpportunityEventTrigger - for Opportunity Event should be registered');
    }
    // Test method to verify the flow handles opportunity - Bulk Publish - during creation correctly
    @isTest
    private static void testBulkPublishOnOpportunityCreates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = true,
                                CloseDate = Date.today().addDays(1)
                            ), false);

        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            insert opp;
        Test.stopTest();    

        // THEN
        // Verify that the Stage Name is set to Publish
        opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Publish', opp.StageName, 'Stage Name should be set to Publish');
    }
    // Test method to verify the flow handles opportunity - Bulk Publish - during updation correctly
    @isTest
    private static void testBulkPublishOnOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                CloseDate = Date.today().addDays(1)
                            ), true);

        // WHEN
        // Update the opportunity to trigger the flow
        Test.startTest();
            opp.Published__c = true;
            update opp;
        Test.stopTest();    

        // THEN
        // Verify that the Stage Name is set to Publish
        opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Publish', opp.StageName, 'Stage Name should be set to Publish');
    }
    // Test method to verify the flow handles opportunity - Publish Offer - during updation correctly
    // @isTest
    // private static void testPublishOfferOnOpportunityUpdates() {
    //     TriggerCommon.disableTrigger('Opportunity');
    //     TriggerCommon.disableTrigger('User');
    //     SBQQ.TriggerControl.disable();
    //     // GIVEN
    //     Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
    //     // A valid opportunity
    //     Opportunity opp = (Opportunity)TestDataFactory.createSObject(
    //                         new Opportunity(
    //                             Name = 'testCreateEnterpriseOpportunity',
    //                             AccountId = acc.Id,
    //                             RecordTypeId = APPLICANT_ENROLMENT_RT,
    //                             Published__c = false,
    //                             CloseDate = Date.today().addDays(1)
    //                         ), true);
    //     // A valid Quote
    //     ContentVersion cv = new ContentVersion(
    //         Title = 'Test',
    //         PathOnClient = 'Test.jpg',
    //         VersionData = Blob.valueOf('Test'),
    //         IsMajorVersion = true
    //     );
    //     insert cv;
    //     SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(
    //                                 new SBQQ__Quote__c(Sub_Status__c = 'Details completed',
    //                                     SBQQ__Status__c = 'In Review',
    //                                     SBQQ__Opportunity2__c = opp.Id,
    //                                     Latest_Preview_Version_Id__c = cv.Id
    //                                 ), true);
    //     // WHEN
    //     // Update the opportunity to trigger the flow
    //     Test.startTest();
    //         opp = [SELECT SBQQ__PrimaryQuote__c, StageName, Published__c FROM Opportunity WHERE Id = :opp.Id];
    //         opp.SBQQ__PrimaryQuote__c = quote.Id; // Set the primary quote  
    //         opp.StageName = 'Publish';
    //         opp.Published__c = true;
    //         update opp;
    //     Test.stopTest();    
    //     SBQQ.TriggerControl.enable();
    //     TriggerCommon.enableTrigger('User');
    //     TriggerCommon.enableTrigger('Opportunity');
    //     // THEN
    //     // Verify that the Stage Name is set to Publish
    //     opp = [SELECT Published_date__c, SBQQ__PrimaryQuote__r.SBQQ__Status__c, SBQQ__PrimaryQuote__r.Sub_Status__c FROM Opportunity WHERE Id = :opp.Id];
    //     Assert.areEqual('Published', opp.SBQQ__PrimaryQuote__r.SBQQ__Status__c, 'Primary Quote Status should be set to Published');
    //     Assert.areEqual('Preview Released', opp.SBQQ__PrimaryQuote__r.Sub_Status__c, 'Primary Quote Sub Status should be set to Preview Released');
    //     Assert.areEqual(Date.today(), opp.Published_date__c, 'Published date should be set to today\'s date');
    // }
    // Test method to verify the flow handles opportunity - BDP Offer - during creation correctly
    @isTest
    private static void testBDPOfferOnOpportunityCreates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid Bulk Data Processing record
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
        bdp.isLocked__c = true;
        bdp.Status__c = 'Processing Offer';
        bdp.Person_ID__c = '123456';
        insert bdp;
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                StageName = 'Review Offer',
                                Bulk_Data_Processing__c = bdp.Id,
                                CloseDate = Date.today().addDays(1)
                            ), false);
        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            insert opp;
        Test.stopTest();    

        // Verify that the Bulk Data Processing record is updated correctly
        bdp = [SELECT Id, Status__c, isLocked__c FROM Bulk_Data_Processing__c WHERE Id = :bdp.Id];
        Assert.areEqual('Offer Created', bdp.Status__c, 'Bulk Data Processing Status should be set to Offer Created');
        Assert.isFalse(bdp.isLocked__c, 'Bulk Data Processing should not be locked after Offer Creation');
    }
    // Test method to verify the flow handles opportunity - BDP Offer - during updation correctly
    @isTest
    private static void testBDPOfferOnOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid Bulk Data Processing record
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
        bdp.isLocked__c = true;
        bdp.Status__c = 'Processing Offer';
        bdp.Person_ID__c = '123456';
        insert bdp;
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                Bulk_Data_Processing__c = bdp.Id, // Associate the BDP record
                                CloseDate = Date.today().addDays(1)
                            ), true);
        // Negative Test
        // BDP Record should not be updated
        bdp = [SELECT Id, Status__c, isLocked__c FROM Bulk_Data_Processing__c WHERE Id = :bdp.Id];
        Assert.areEqual('Processing Offer', bdp.Status__c, 'Bulk Data Processing Status should be Processing Offer before update');
        Assert.isTrue(bdp.isLocked__c, 'Bulk Data Processing should be locked before update');
        // WHEN
        // Update the opportunity to trigger the flow
        Test.startTest();
            opp.StageName = 'Review Offer';
            update opp;
        Test.stopTest();    

        // THEN
        // Verify that the Bulk Data Processing record is updated correctly
        bdp = [SELECT Id, Status__c, isLocked__c FROM Bulk_Data_Processing__c WHERE Id = :bdp.Id];
        Assert.areEqual('Offer Created', bdp.Status__c, 'Bulk Data Processing Status should be set to Offer Created');
        Assert.isFalse(bdp.isLocked__c, 'Bulk Data Processing should not be locked after Offer Creation');
    }
    // Test method to verify the flow handles opportunity - QA Required - during creation correctly
    @isTest
    private static void testQARequiredOnOpportunityCreates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                StageName = 'Specialist Review',
                                CloseDate = Date.today().addDays(1)
                            ), false);
        // A valid Quote
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test'),
            IsMajorVersion = true
        );
        insert cv;

        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(
                                    new SBQQ__Quote__c(Sub_Status__c = 'Details completed',
                                        SBQQ__Status__c = 'In Review',
                                        SBQQ__Opportunity2__c = opp.Id,
                                        Latest_Preview_Version_Id__c = cv.Id
                                    ), true);
        SBQQ.TriggerControl.enable();
        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            insert opp;
        Test.stopTest();    

        // THEN
        // Verify that the Quote's Sub Status is set to 'Business request review'
        quote = [SELECT Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        // Assert.areEqual('Business request review', quote.Sub_Status__c, 'Quote Sub Status should be set to Business request review');
    }
    // Test method to verify the flow handles opportunity - QA Required - during updation correctly
    @isTest
    private static void testQARequiredOnOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                CloseDate = Date.today().addDays(1)
                            ), true);
        // A valid Quote
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test'),
            IsMajorVersion = true
        );
        insert cv;

        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(
                                    new SBQQ__Quote__c(Sub_Status__c = 'Details completed',
                                        SBQQ__Status__c = 'In Review',
                                        SBQQ__Opportunity2__c = opp.Id,
                                        Latest_Preview_Version_Id__c = cv.Id
                                    ), true);
        // Negative Test
        // Quote should not be updated
        quote = [SELECT Sub_Status__c FROM SBQQ__Quote__c WHERE  Id = :quote.Id];
        Assert.areEqual('Details completed', quote.Sub_Status__c, 'Quote Sub Status should be Details completed before update');
        
        // WHEN
        // Update the opportunity to trigger the flow
        Test.startTest();
            opp.StageName = 'Specialist Review';
            opp.SBQQ__PrimaryQuote__c = quote.Id; // Set the primary quote
            update opp;
        Test.stopTest();    

        // THEN
        // Verify that the Quote's Sub Status is set to 'Business request review'
        quote = [SELECT Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        // Assert.areEqual('Business request review', quote.Sub_Status__c, 'Quote Sub Status should be set to Business request review');
    }
    // Test method to verify the flow handles opportunity - Rejected - during updation correctly
    @isTest
    private static void testRejectedOnOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                CloseDate = Date.today().addDays(1)
                            ), true);
        // A valid Quote
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test'),
            IsMajorVersion = true
        );
        insert cv;

        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(
                                    new SBQQ__Quote__c(Sub_Status__c = 'Details completed',
                                        SBQQ__Status__c = 'In Review',
                                        SBQQ__Opportunity2__c = opp.Id,
                                        Latest_Preview_Version_Id__c = cv.Id
                                    ), true);
        // Negative Test
        // Quote should not be updated
        quote = [SELECT SBQQ__Status__c, Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.areEqual('Details completed', quote.Sub_Status__c, 'Quote Sub Status should be Details completed before update');
        
        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            opp.StageName = 'Canceled/Rejected';
            opp.Closed_Reason__c = 'Rejected';
            opp.Closed_Reason_Details__c = 'Rejected for any reason';
            opp.SBQQ__PrimaryQuote__c = quote.Id; // Set the primary quote
            update opp;
        Test.stopTest();    

        // THEN
        // Verify that the Quote's Status and Sub Status are set to Rejected
        quote = [SELECT SBQQ__Status__c, Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.areEqual('Rejected', quote.SBQQ__Status__c, 'Quote Status should be set to Rejected');
        Assert.areEqual('Rejected by Assessor', quote.Sub_Status__c, 'Quote Sub Status should be set to Rejected by Assessor');
    }
    // Test method to verify the flow handles opportunity - Cancelled - during updation correctly
    @isTest
    private static void testCancelledOnOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                CloseDate = Date.today().addDays(1)
                            ), true);
        // A valid Quote
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test'),
            IsMajorVersion = true
        );
        insert cv;

        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(
                                    new SBQQ__Quote__c(Sub_Status__c = 'Details completed',
                                        SBQQ__Status__c = 'Cancelled',
                                        SBQQ__Opportunity2__c = opp.Id,
                                        Latest_Preview_Version_Id__c = cv.Id
                                    ), true);
        // Negative Test
        // Quote should not be updated
        quote = [SELECT SBQQ__Status__c, Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.areEqual('Details completed', quote.Sub_Status__c, 'Quote Sub Status should be Details completed before update');
        
        // WHEN
        // Update the opportunity to trigger the flow
        Test.startTest();
            opp.StageName = 'Canceled/Rejected';
            opp.Closed_Reason__c = 'Cancelled';
            opp.Closed_Reason_Details__c = 'Canceled for any reason';
            opp.SBQQ__PrimaryQuote__c = quote.Id; // Set the primary quote
            update opp;
        Test.stopTest();    

        // THEN
        // Verify that the Quote's Status and Sub Status are set to Rejected
        quote = [SELECT SBQQ__Status__c, Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.areEqual('Cancelled', quote.SBQQ__Status__c, 'Quote Status should be set to Cancelled');
        // Assert.areEqual('Rejected by Assessor', quote.Sub_Status__c, 'Quote Sub Status should be set to Rejected by Assessor');
    }
    // Test method to verify the flow handles opportunity - Deferred - during updation correctly
    @isTest
    private static void testDeferredOnOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                CloseDate = Date.today().addDays(1)
                            ), true);
        // A valid Quote
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test'),
            IsMajorVersion = true
        );
        insert cv;

        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(
                                    new SBQQ__Quote__c(Sub_Status__c = 'Details completed',
                                        SBQQ__Status__c = 'In Review',
                                        SBQQ__Opportunity2__c = opp.Id,
                                        Latest_Preview_Version_Id__c = cv.Id
                                    ), true);
        // Negative Test
        // Quote should not be updated
        quote = [SELECT SBQQ__Status__c, Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.areEqual('Details completed', quote.Sub_Status__c, 'Quote Sub Status should be Details completed before update');
        
        // WHEN
        // Update the opportunity to trigger the flow
        Test.startTest();
            opp.StageName = 'Canceled/Rejected';
            opp.Closed_Reason__c = 'Deferred';
            opp.Closed_Reason_Details__c = 'Deferred for any reason';
            opp.SBQQ__PrimaryQuote__c = quote.Id; // Set the primary quote
            update opp;
        Test.stopTest();    

        // THEN
        // Verify that the Quote's Status and Sub Status are set to Rejected
        quote = [SELECT SBQQ__Status__c, Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.areEqual('Deferred', quote.SBQQ__Status__c, 'Quote Status should be set to Deferred');
        Assert.isNull(quote.Sub_Status__c, 'Quote Sub Status should be set to Rejected by Assessor');
    }
    // Test method to verify the flow handles opportunity - Manually Signed - during updation correctly
    @isTest
    private static void testManuallySignedOnOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                CloseDate = Date.today().addDays(1)
                            ), true);
        // A valid Quote
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test'),
            IsMajorVersion = true
        );
        insert cv;

        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(
                                    new SBQQ__Quote__c(Sub_Status__c = 'Details completed',
                                        SBQQ__Status__c = 'In Review',
                                        SBQQ__Opportunity2__c = opp.Id,
                                        Latest_Preview_Version_Id__c = cv.Id
                                    ), true);
        // Negative Test
        // Quote should not be updated
        quote = [SELECT SBQQ__Status__c, Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.areEqual('Details completed', quote.Sub_Status__c, 'Quote Sub Status should be Details completed before update');
        
        // WHEN
        // Update the opportunity to trigger the flow
        Test.startTest();
            opp.Manual_ISCA_Edit_Stage__c = 'Signed by all parties';
            opp.SBQQ__PrimaryQuote__c = quote.Id; // Set the primary quote
            update opp;
        Test.stopTest();    

        // THEN
        // Verify that the Quote's Status and Sub Status are set to Rejected
        quote = [SELECT SBQQ__Status__c, Sub_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.areEqual('Signed', quote.SBQQ__Status__c, 'Quote Status should be set to Signed');
        Assert.areEqual('Signed and locked', quote.Sub_Status__c, 'Quote Sub Status should be set to Signed and locked');
        // Verify that the Opportunity's Stage is set to Signed
        opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Signed', opp.StageName, 'Opportunity Stage should be set to Signed');
    }
    // Test method to verify the flow handles opportunity - BDP Completed - during creation correctly
    @isTest
    private static void testBDPCompletedOnOpportunityCreates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        // A valid Bulk Data Processing record
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
        bdp.isLocked__c = false;
        bdp.Status__c = 'Offer Error';
        bdp.Person_ID__c = '123456';
        insert bdp;
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = APPLICANT_ENROLMENT_RT,
                                Published__c = false,
                                StageName = 'Signed',
                                Bulk_Data_Processing__c = bdp.Id,
                                CloseDate = Date.today().addDays(1)
                            ), false);
        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            insert opp;
        Test.stopTest();    

        // Verify that the Bulk Data Processing record is updated correctly
        bdp = [SELECT Status__c FROM Bulk_Data_Processing__c WHERE Id = :bdp.Id];
        Assert.areEqual('Completed', bdp.Status__c, 'Bulk Data Processing Status should be set to Completed');
    }
}