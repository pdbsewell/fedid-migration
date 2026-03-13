/**
 * @author Sulung Chandra, UC Innovation
 * @date 2019-12-19
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for the Create Donation Document Link Batch and Schedule
 */
@isTest(isParallel=false)
private class PORTAL_UCIN_MoveGiftReceipt_Test {
    @isTest(SeeAllData=false) 
    static void testMoveGiftReceiptBatch() {
        ucinn_ascendv2__Review_Transaction_Prefixes__c prefix = new ucinn_ascendv2__Review_Transaction_Prefixes__c();
        prefix.ucinn_ascendv2__Record_Type_API_Name__c = 'Online Donation Transaction';
        prefix.ucinn_ascendv2__Prefix__c = 'PRAX';
        prefix.Name = 'Online Donations';
        insert prefix;
            
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        
        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '1182 Warner St';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Chico';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '95926';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;
        
        // given: review transaction used to create gift
        RecordType transactionRecordType_online = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ucinn_ascendv2__Review_Transaction_v2__c' and DeveloperName = 'Online_Donation_Transaction'];
        
        ucinn_ascendv2__Review_Transaction_v2__c rt = (ucinn_ascendv2__Review_Transaction_v2__c)TestDataFactory.createSObject(new ucinn_ascendv2__Review_Transaction_v2__c
                                                                                                                              (RecordTypeId = transactionRecordType_online.Id, ucinn_ascendv2__Contact__c = conList[0].Id, 
                                                                                                                               ucinn_ascendv2__Payment_Amount_1_1__c = 1000,ucinn_ascendv2__Payment_Date_1_1__c = Date.today(),
                                                                                                                              ucinn_ascendv2__Is_Anonymous__c = true, Gift_Comments__c = 'Test',
                                                                                                                              Source__c = 'Contact Supplied', ucinn_ascendv2__Transaction_Date__c = Date.today(),
                                                                                                                              ucinn_ascendv2__Designation_1__c = desList[0].Id, ucinn_ascendv2__Transaction_Type__c = 'Gift',
                                                                                                                              ucinn_ascendv2__Opportunity_Type__c = 'Outright', ucinn_ascendv2__Tender_Type_1__c = 'Credit Card',
                                                                                                                              ucinn_ascendv2__Campaign__c = cmpList[0].Id, ucinn_ascendv2__External_System_ID__c = 'PRAX-12345',
                                                                                                                              ucinn_ascendv2__Status__c = 'New', Moved_Gift_Receipt__c = false), true);
        

        Id giftRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Gift').getRecordTypeId();

        Opportunity testOpp = new Opportunity();
        testOpp.ucinn_ascendv2__Review_Transaction_v2__c = rt.Id;
        testOpp.RecordTypeId = giftRT;
        testOpp.ucinn_ascendv2__Contact__c = con1.Id;
        testOpp.Name = 'testGift';
        testOpp.StageName = 'Funded';
        testOpp.CloseDate = system.today();
        testOpp.Amount = 100;
        insert testOpp;
        
        ContentVersion cont = new ContentVersion();
        cont.Title = 'Gift Receipt';
        cont.PathOnClient = 'file.pdf';
        cont.VersionData = EncodingUtil.base64Decode('Test Body');
        cont.Origin = 'H';
        insert cont;

        ContentVersion cont2 = [SELECT ContentDocumentId FROM ContentVersion WHERE ID =: cont.ID];

        ContentDocumentLink contDocLink = new ContentDocumentLink();
        contDocLink.ContentDocumentId = cont2.ContentDocumentId;
        contDocLink.LinkedEntityId = rt.Id;
        contDocLink.ShareType = 'V';
        insert contDocLink;
        
        Test.startTest();
        
        PORTAL_UCIN_MoveGiftReceiptBatch bc = new PORTAL_UCIN_MoveGiftReceiptBatch();
        Database.executeBatch(bc);
        
        Test.stopTest();
        
        System.assertEquals(([Select Id From ContentDocumentLink Where LinkedEntityId = :testOpp.Id]).size(), 1);
        System.assertEquals(([Select Id,Moved_Gift_Receipt__c From ucinn_ascendv2__Review_Transaction_v2__c Where ID = :rt.Id]).Moved_Gift_Receipt__c, true);
    }

    @isTest(SeeAllData=false) 
    static void testSetAssetBatchSchedule() {
        string scheduleTime = '0 0 0 * * ?';
        string jobId = System.schedule('TEST PORTAL_UCIN_MoveGiftReceiptScheduler', scheduleTime, new PORTAL_UCIN_MoveGiftReceiptScheduler());
        DateTime nextFire = DateTime.newInstanceGmt(System.today().addDays(1), Time.newInstance(0,0,0,0));
        
        //track scheduled trigger with CronTrigger
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        
        System.assertEquals(scheduleTime, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(string.valueOfGmt(nextFire), string.valueOf(ct.NextFireTime));
    }
}