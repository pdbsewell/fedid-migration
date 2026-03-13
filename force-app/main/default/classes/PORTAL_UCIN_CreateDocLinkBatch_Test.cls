/**
 * @author Sulung Chandra, UC Innovation
 * @date 2019-12-19
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for the Create Donation Document Link Batch and Schedule
 * @revision
 * Date         Author              Modification
 * 18/07/2022   Chaldrin Cruz       Replaced rt with rtv2
*/
@isTest(isParallel=false)
private class PORTAL_UCIN_CreateDocLinkBatch_Test {
    @isTest(SeeAllData=false) 
    static void testCreateDocLinkBatch() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        
        // given: donor
        // Create Constituents
        Contact con1 = (Contact)TestDataFactory.createSObject(new Contact(
            Firstname = 'Contact',
            Lastname = guid,
            ucinn_ascendv2__Preferred_Address_Line_1__c = '1182 Warner St',
            ucinn_ascendv2__Preferred_Address_City__c = 'Chico',
            ucinn_ascendv2__Preferred_Address_State__c = 'CA',
            ucinn_ascendv2__Preferred_Address_Postal_Code__c = '95926'), true);
        
        // given: appeal used for gift
        // Create Appeal Codes
        Campaign cmp = (Campaign)TestDataFactory.createSObject(new Campaign(
            Name = 'A-'+guid,
            IsActive = true,
            Status = 'Planned',
            ucinn_ascendv2__Motivation_Code__c = 'A-'+guid), true);
        
        // given: designation used for gift
        // Create Designations
        ucinn_ascendv2__Designation__c des1 = (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation__c(
            Name = 'D-'+guid+'1',
            ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1',
            ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1),
            ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1),
            ucinn_ascendv2__Program_Code__c = 'GL_Acc', // 7 char
            ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack', // 6 char
            ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD', // 6 char
            Tax_Status_Code__c = 'S1'), true);
        
        // given: review transaction used to create gift
        ucinn_ascendv2__Review_Transaction_v2__c rt = (ucinn_ascendv2__Review_Transaction_v2__c)TestDataFactory.createSObject(new ucinn_ascendv2__Review_Transaction_v2__c (
            Name = 'PRAX-12345',
            ucinn_ascendv2__Status__c = 'New',
            RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Review_Transaction_v2__c.getRecordTypeInfosByDeveloperName().get('Online_Donation_Transaction').getRecordTypeId(),
            ucinn_ascendv2__Contact__c = con1.Id,
            ucinn_ascendv2__Payment_Amount_1_1__c = 1000,
            ucinn_ascendv2__Payment_Date_1_1__c = Date.today(),
            ucinn_ascendv2__Is_Anonymous__c = true,
            Gift_Comments__c = 'Test',
            Source__c = 'Contact Supplied',
            ucinn_ascendv2__Transaction_Date__c = Date.today(),
            ucinn_ascendv2__Designation_1__c = des1.Id,
            ucinn_ascendv2__Transaction_Type__c = 'Gift',
            ucinn_ascendv2__Opportunity_Type__c = 'Outright',
            ucinn_ascendv2__Tender_Type_1__c = 'Credit Card',
            ucinn_ascendv2__Campaign__c = cmp.Id,
            ucinn_ascendv2__External_System_ID__c = 'PRAX-12345'), true);
        
        // given: receipt to attach to review transaction
        ContentVersion cont = (ContentVersion)TestDataFactory.createSObject(new ContentVersion(
            Title = 'Gift Receipt',
            PathOnClient = 'file.pdf',
            VersionData = EncodingUtil.base64Decode('Test Body'),
            Origin = 'H'), true);

        // given: link receipt to review transaction
        ContentVersion cont2 = [SELECT ContentDocumentId FROM ContentVersion WHERE ID =: cont.ID];
        
        PORTAL_UCIN_Donation_Raw_Document_Link__c drdl = (PORTAL_UCIN_Donation_Raw_Document_Link__c)TestDataFactory.createSObject(new PORTAL_UCIN_Donation_Raw_Document_Link__c(
            Review_Transaction_v2__c = rt.Id,
            ContentDocumentId__c = cont2.ContentDocumentId), true);
        
        // when: receipt is attached to review transaction
        Test.startTest();
        
        PORTAL_UCIN_CreateDocLinkBatch bc = new PORTAL_UCIN_CreateDocLinkBatch();
        Database.executeBatch(bc);
        
        Test.stopTest();
        
        // then: verify receipt is attached to review transaction
        System.assertEquals(([Select Id From ContentDocumentLink Where LinkedEntityId = :rt.Id]).size(), 1);
    }

    @isTest(SeeAllData=false) 
    static void testSetAssetBatchSchedule() {
        // when: batch to attach receipts to review transactions are scheduled
        string scheduleTime = '0 0 0 * * ?';
        string jobId = System.schedule('TEST PORTAL_UCIN_CreateDocLinkScheduler', scheduleTime, new PORTAL_UCIN_CreateDocLinkScheduler());
        DateTime nextFire = DateTime.newInstanceGmt(System.today().addDays(1), Time.newInstance(0,0,0,0));
        
        //track scheduled trigger with CronTrigger
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
 
        // then: verify that batch is scheduled
        System.assertEquals(scheduleTime, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(string.valueOfGmt(nextFire), string.valueOf(ct.NextFireTime));
    }
}