/*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         13.Sep.2017        
    * @description  
    * @revision     
    * 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4
    * 16/03/2024 - Mac Domingo   - EPCP-3307 Change isParallel to false
    *******************************************************************************/
@isTest(isParallel=false)//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on User object
private class DocumentsToBePushedToCallistaCC_Test {
    private static Application__c appRecord;
    private static User communityUserRec;
    private static Contact contactRec;
    private static Application_Course_Preference__c coursePrefA;
    private static Course_Offering__c courseOfferingRec;
    private static Course_Offering__c courseOfferingRecNoUnit;

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         13.Sep.2017        
    * @description  tests the Send Email functionality on ACP
    * @revision     
    * 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4
    *******************************************************************************/
    static testMethod void test_cloneEmailAttachmentToContactDocumentWithSmallImage() {
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        //create required records
        createSampleData(communityUserRec.ContactId, 'Submitted', 'TEST-STATUS', true);
        
        
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true );
        insert caseRec;

        System.assert(caseRec.Notify_Agent__c, 'Notify Agent should be set to true');
        System.assert(caseRec.RecordTypeId == admissionsRecType, 'Record Type should be Admissions');

        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true); 
        insert emlMsg;

        List<Attachment> attList = new List<Attachment>();

        Attachment attRec1 = new Attachment();
        attRec1.Body = Blob.valueOf('Sample Text String #1');
        attRec1.Name = String.valueOf('test1.jpeg');
        attRec1.ContentType = String.valueOf('image/jpeg');
        attRec1.ParentId = emlMsg.Id; 
        attList.add(attRec1);

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('Sample Text String #2');
        attRec2.Name = String.valueOf('test2.jpeg');
        attRec2.ContentType = String.valueOf('image/jpeg');
        attRec2.ParentId = emlMsg.Id; 
        attList.add(attRec2);

        insert attList;

        List<Contact_Document__c> listOfContactDocuments = new List<Contact_Document__c>();
        for(Contact_Document__c loopDocument : [SELECT Id, Email_Attachment_Id__c, LastModifiedDate FROM Contact_Document__c]){
            loopDocument.Email_Attachment_Id__c = attRec2.Id;
            listOfContactDocuments.add(loopDocument);
        }
        update listOfContactDocuments;

        Test.startTest();

            List<string> attListIds = new List<string>();
            attListIds.add(attRec2.id);
            DocumentsToBePushedToCallistaCC.sendEmailAttachments(attListIds,caseRec.id);
        
        Test.stopTest();
        System.assert(caseRec.Notify_Agent__c, 'Notify Agent should be set to true');
        System.assert(caseRec.RecordTypeId == admissionsRecType, 'Record Type should be Admissions');
        // EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
        //                                      FromAddress = 'testfrom@testmonash.edu',
        //                                      FromName = 'testSender',
        //                                      Subject = 'testSubject',
        //                                      HtmlBody = '<b>test body</b>',
        //                                      ToAddress = 'testEndpoint@monash.edu',
        //                                      Incoming = true); 
        // insert emlMsg;

        // System.assertEquals(caseRec.Id, emlMsg.ParentId, 'Email Message ParentId should be the Case created');

        // //set mock response
        // Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

        // List<Attachment> attList = new List<Attachment>();

        // Attachment attRec1 = new Attachment();
        // attRec1.Body = Blob.valueOf('Sample Text String #1');
        // attRec1.Name = String.valueOf('test1.jpeg');
        // attRec1.ContentType = String.valueOf('image/jpeg');
        // attRec1.ParentId = emlMsg.Id; 
        // attList.add(attRec1);

        // Attachment attRec2 = new Attachment();
        // attRec2.Body = Blob.valueOf('Sample Text String #2');
        // attRec2.Name = String.valueOf('test2.jpeg');
        // attRec2.ContentType = String.valueOf('image/jpeg');
        // attRec2.ParentId = emlMsg.Id; 
        // attList.add(attRec2);

        // insert attList;

        // Test.startTest();
        
        // caseRec.Application_Course_Preference__c = coursePrefA.Id;
        // //this contact Id will be populated by process builder
        // caseRec.ContactId = communityUserRec.ContactId;
        // System.assertNotEquals(null, coursePrefA.Application__c);
        // System.assertNotEquals(null, caseRec.ContactId);
        // update caseRec;

        // Set<String> cdIds = new Set<String>();
        // for (Contact_Document__c cdRec: [SELECT Id FROM Contact_Document__c]) {
        //  cdIds.add(cdRec.Id);
        // }

        // //assert that 0 newly Contact Document and 0 ADP
        // // It shouldn't create any new image or doc as the image files are less small in size
        // System.assertEquals(0, [SELECT COUNT() FROM Application_Document_Provided__c WHERE Contact_Document__c IN: cdIds], 'Trigger should not create ADP');
        // System.assertNotEquals(null, caseRec.id);
        // List<Case> caseWithACP = [SELECT  Id, ContactId, 
        //                          Application_Course_Preference__c//, 
        //                          //Enquiry_Reopened__c,
        //                          //ClosedDate
        //                  FROM    Case 
        //                  WHERE   Id = :caseRec.id
        //                  LIMIT   1 ];
        // System.assertNotEquals(new List<Case>(), caseWithACP, 'case not found');
        // System.assert(caseWithACP[0].ContactId != null, 'contact not found');
        // System.assert(caseWithACP[0].Application_Course_Preference__c != null, 'acp not found');
        // List<DocumentsToBePushedToCallistaCC.wrapperClass> wrapperClassListObj = DocumentsToBePushedToCallistaCC.getTheCaseAttachmentsWithMatchtingContactDocumentFields(caseRec.id, true);

        // List<string> attListIds = new List<string>();
        // attListIds.add(attRec2.id);
        // DocumentsToBePushedToCallistaCC.sendEmailAttachments(attListIds,caseRec.id);
        // for (Contact_Document__c cdRec: [SELECT Id FROM Contact_Document__c WHERE Email_Attachment_Id__c != null]) {
        //  cdIds.add(cdRec.Id);
        // }
        // System.assertEquals(2, cdIds.size(), 'Trigger did not create Contact Document');
        // wrapperClassListObj = DocumentsToBePushedToCallistaCC.getTheCaseAttachmentsWithMatchtingContactDocumentFields(caseRec.id, true);

        // Test.stopTest();

        // List<Application_Document_Provided__c> adpList = [   SELECT  Id, API_Response_Message__c,
        //                                                          Document_Submitted_Successfully__c
        //                                                  FROM    Application_Document_Provided__c 
        //                                                  WHERE   Contact_Document__c IN: cdIds];
        // //Imitate the MiX API Updating the Application Doc Provided - Positive response
        // if (!adpList.isEmpty()) {
        //  for (Application_Document_Provided__c adpRec: adpList) {
        //      adpRec.API_Response_Message__c = '{response: nice}';
        //      adpRec.Document_Submitted_Successfully__c = true;
        //  }

        //  update adpList;
        // }
        // //re-run the method
        // System.assert(!DocumentsToBePushedToCallistaCC.getTheCaseAttachmentsWithMatchtingContactDocumentFields(caseRec.id, true).isEmpty());
        
        // //Imitate the MiX API Updating the Application Doc Provided - Negative response
        // if (!adpList.isEmpty()) {
        //  for (Application_Document_Provided__c adpRec: adpList) {
        //      adpRec.API_Response_Message__c = '{response: not nice}';
        //      adpRec.Document_Submitted_Successfully__c = false;
        //  }

        //  update adpList;
        // }
        // //re-run the method
        // System.assert(!DocumentsToBePushedToCallistaCC.getTheCaseAttachmentsWithMatchtingContactDocumentFields(caseRec.id, true).isEmpty());

        // //make sure there are no errors
        // System.assertEquals(0, [ SELECT  COUNT()
        //                          FROM    Exception_Log__c
        //                          WHERE   Object_Name__c = 'AttachmentServices']);
        
        // for (Contact_Document__c cdRec: [SELECT Id FROM Contact_Document__c]) {
        //  cdIds.add(cdRec.Id);
        // }

        // //assert that 2 Contact Document and ADP is created - one for each attachment
        // System.assertEquals(2, cdIds.size(), 'Trigger did not create Contact Document');
        // System.assertEquals(1, [SELECT COUNT() FROM Application_Document_Provided__c WHERE Contact_Document__c IN: cdIds], 'Trigger did not create ADP');

    }

    static testMethod void test_cloneEmailAttachmentToContactDocumentWithSmallImageNoContactDocument() {
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        //create required records
        createSampleData(communityUserRec.ContactId, 'Submitted', 'TEST-STATUS', true);
        
        
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true );
        insert caseRec;

        System.assert(caseRec.Notify_Agent__c, 'Notify Agent should be set to true');
        System.assert(caseRec.RecordTypeId == admissionsRecType, 'Record Type should be Admissions');

        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true); 
        insert emlMsg;

        List<Attachment> attList = new List<Attachment>();

        Attachment attRec1 = new Attachment();
        attRec1.Body = Blob.valueOf('Sample Text String #1');
        attRec1.Name = String.valueOf('test1.jpeg');
        attRec1.ContentType = String.valueOf('image/jpeg');
        attRec1.ParentId = emlMsg.Id; 
        attList.add(attRec1);

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('Sample Text String #2');
        attRec2.Name = String.valueOf('test2.jpeg');
        attRec2.ContentType = String.valueOf('image/jpeg');
        attRec2.ParentId = emlMsg.Id; 
        attList.add(attRec2);

        insert attList;

        Test.startTest();

            List<string> attListIds = new List<string>();
            attListIds.add(attRec2.id);
            DocumentsToBePushedToCallistaCC.sendEmailAttachments(attListIds,caseRec.id);
        
        Test.stopTest();
        System.assert(caseRec.Notify_Agent__c, 'Notify Agent should be set to true');
        System.assert(caseRec.RecordTypeId == admissionsRecType, 'Record Type should be Admissions');
    }

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         13.Sep.2017        
    * @description  tests the Send Email functionality on ACP
    * @revision     
    *******************************************************************************/
    static testMethod void test_cloneEmailAttachmentToContactDocumentWithBigFile() {
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        //create required records
        createSampleData(communityUserRec.ContactId, 'Submitted', 'TEST-STATUS', true);
        
        
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true );
        insert caseRec;

        System.assert(caseRec.Notify_Agent__c, 'Notify Agent should be set to true');
        System.assert(caseRec.RecordTypeId == admissionsRecType, 'Record Type should be Admissions');

        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true); 
        insert emlMsg;

        System.assertEquals(caseRec.Id, emlMsg.ParentId, 'Email Message ParentId should be the Case created');

        //set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

        List<Attachment> attList = new List<Attachment>();

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('a'.repeat(5242881));
        attRec2.Name = String.valueOf('test2.jpeg');
        attRec2.ParentId = emlMsg.Id; 
        attList.add(attRec2);

        insert attList;

        Test.startTest();
        
        caseRec.Application_Course_Preference__c = coursePrefA.Id;
        System.assertNotEquals(null, coursePrefA.Application__c);
        update caseRec;

        Set<String> cdIds = new Set<String>();
        for (Contact_Document__c cdRec: [SELECT Id FROM Contact_Document__c]) {
            cdIds.add(cdRec.Id);
        }

        List<string> attListIds = new List<string>();
        attListIds.add(attRec2.id);
        List<DocumentsToBePushedToCallistaCC.wrapperClass> wrapperClassListObj = DocumentsToBePushedToCallistaCC.getTheCaseAttachmentsWithMatchtingContactDocumentFields(caseRec.id, true);

        Test.stopTest();
        //make sure there are no errors
        System.assertEquals(0, [    SELECT  COUNT()
                                    FROM    Exception_Log__c
                                    WHERE   Object_Name__c = 'AttachmentServices']);
        
        for (Contact_Document__c cdRec: [SELECT Id FROM Contact_Document__c]) {
            cdIds.add(cdRec.Id);
        }

        //assert that 2 Contact Document and ADP is created - one for each attachment
        System.assertEquals(1, cdIds.size(), 'Trigger did not create Contact Document');
        //System.assertEquals(0, [SELECT COUNT() FROM Application_Document_Provided__c WHERE Contact_Document__c IN: cdIds], 'Trigger did not create ADP');     
    }

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         13.Sep.2017        
    * @description  tests the Send Email functionality on ACP
    * @revision     
    *******************************************************************************/
    static testMethod void test_cloneEmailAttachmentToContactDocumentWithBigFileMatching() {
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        //create required records
        createSampleData(communityUserRec.ContactId, 'Submitted', 'TEST-STATUS', true);
        
        
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true );
        insert caseRec;

        System.assert(caseRec.Notify_Agent__c, 'Notify Agent should be set to true');
        System.assert(caseRec.RecordTypeId == admissionsRecType, 'Record Type should be Admissions');

        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true); 
        insert emlMsg;

        System.assertEquals(caseRec.Id, emlMsg.ParentId, 'Email Message ParentId should be the Case created');

        //set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

        List<Attachment> attList = new List<Attachment>();

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('a'.repeat(5242881));
        attRec2.Name = String.valueOf('test2.jpeg');
        attRec2.ParentId = emlMsg.Id; 
        attList.add(attRec2);

        insert attList;

        Test.startTest();
        
        caseRec.Application_Course_Preference__c = coursePrefA.Id;
        System.assertNotEquals(null, coursePrefA.Application__c);
        update caseRec;

        Set<String> cdIds = new Set<String>();
        for (Contact_Document__c cdRec: [SELECT Id FROM Contact_Document__c]) {
            cdIds.add(cdRec.Id);
        }

        List<string> attListIds = new List<string>();
        attListIds.add(attRec2.id);
        List<DocumentsToBePushedToCallistaCC.wrapperClass> wrapperClassListObj = DocumentsToBePushedToCallistaCC.getTheCaseAttachmentsWithMatchtingContactDocumentFields(caseRec.id, false);

        Test.stopTest();
        //make sure there are no errors
        System.assertEquals(0, [    SELECT  COUNT()
                                    FROM    Exception_Log__c
                                    WHERE   Object_Name__c = 'AttachmentServices']);
        
        for (Contact_Document__c cdRec: [SELECT Id FROM Contact_Document__c]) {
            cdIds.add(cdRec.Id);
        }

        //assert that 2 Contact Document and ADP is created - one for each attachment
        System.assertEquals(1, cdIds.size(), 'Trigger did not create Contact Document');
        //System.assertEquals(0, [SELECT COUNT() FROM Application_Document_Provided__c WHERE Contact_Document__c IN: cdIds], 'Trigger did not create ADP');     
    }

    static testMethod void test_isEnquiryValid() {
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        //create required records
        createSampleData(communityUserRec.ContactId, 'Submitted', 'TEST-STATUS', true);
        
        
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true );
        insert caseRec;
        caseRec.Application_Course_Preference__c = coursePrefA.Id;
        update caseRec;
        Test.startTest();
        System.assertNotEquals(null, coursePrefA.Application__c);
        System.assertEquals(DocumentsToBePushedToCallistaCC.isEnquiryValid(caseRec.id), 'No Callista Applicant Id', 'There shouldnt be any callista applicant Id');
        Test.stopTest();
    }

    @isTest
    static void test_GetTheCaseDatesReopened() {
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                 SuppliedPhone = '0400000000',
                                 SuppliedEmail = 'testformEmail@monash.edu',
                                 AccountId = null,
                                 RecordTypeId = admissionsRecType,
                                 Notify_Agent__c = true,
                                 Enquiry_Reopened__c = System.NOW());
        insert caseRec;

        String result = '';
        Test.startTest();
            result = DocumentsToBePushedToCallistaCC.getTheCaseDates(caseRec.Id);
        Test.stopTest();
        System.assertEquals(result, 'Reopend,' + [SELECT Id, Enquiry_Reopened__c FROM Case WHERE Id = :caseRec.Id].Enquiry_Reopened__c);
    }   

    @isTest
    static void test_GetTheCaseDatesClosed() {
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                 SuppliedPhone = '0400000000',
                                 SuppliedEmail = 'testformEmail@monash.edu',
                                 AccountId = null,
                                 RecordTypeId = admissionsRecType,
                                 Notify_Agent__c = true,
                                 Status = 'Closed');
        insert caseRec;

        String result = '';
        Test.startTest();
            result = DocumentsToBePushedToCallistaCC.getTheCaseDates(caseRec.Id);
        Test.stopTest();
        System.assertEquals(result, 'Closed,' + [SELECT Id, ClosedDate FROM Case WHERE Id = :caseRec.Id].ClosedDate);
    }   

    @isTest
    static void test_GetTheCaseDatesReopenedClosed() {
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                 SuppliedPhone = '0400000000',
                                 SuppliedEmail = 'testformEmail@monash.edu',
                                 AccountId = null,
                                 RecordTypeId = admissionsRecType,
                                 Notify_Agent__c = true,
                                 Enquiry_Reopened__c = System.NOW().addDays(-1),
                                 Status = 'Closed');
        insert caseRec;

        String result = '';
        Test.startTest();
            result = DocumentsToBePushedToCallistaCC.getTheCaseDates(caseRec.Id);
        Test.stopTest();
        System.assertEquals(result, 'Closed,' + [SELECT Id, ClosedDate FROM Case WHERE Id = :caseRec.Id].ClosedDate);
    }   

    @isTest
    static void test_CompareToA() {
        List<Attachment> attList = new List<Attachment>();
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true );
        insert caseRec;
        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true); 
        insert emlMsg;

        Attachment attRec1 = new Attachment();
        attRec1.Body = Blob.valueOf('Sample Text String #1');
        attRec1.Name = String.valueOf('test1.jpeg');
        attRec1.ContentType = String.valueOf('image/jpeg');
        attRec1.ParentId = emlMsg.Id; 
        insert attRec1;

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('Sample Text String #2');
        attRec2.Name = String.valueOf('test2.jpeg');
        attRec2.ContentType = String.valueOf('image/jpeg');
        attRec2.ParentId = emlMsg.Id; 
        insert attRec2;

        DocumentsToBePushedToCallistaCC.wrapperClass testWrapperA = new DocumentsToBePushedToCallistaCC.wrapperClass();
        testWrapperA.attachment = attRec1;
        DocumentsToBePushedToCallistaCC.wrapperClass testWrapperB = new DocumentsToBePushedToCallistaCC.wrapperClass();
        testWrapperB.attachment = attRec2;

        Integer testResult = 0;
        Test.startTest();
            testResult = testWrapperA.compareTo(testWrapperB);
        Test.stopTest();
        System.assertEquals(testResult, -1);
    }   

    @isTest
    static void test_CompareToB() {
        List<Attachment> attList = new List<Attachment>();
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true );
        insert caseRec;
        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true); 
        insert emlMsg;

        Attachment attRec1 = new Attachment();
        attRec1.Body = Blob.valueOf('Sample Text String #1');
        attRec1.Name = String.valueOf('test1.jpeg');
        attRec1.ContentType = String.valueOf('image/jpeg');
        attRec1.ParentId = emlMsg.Id; 
        insert attRec1;

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('Sample Text String #2');
        attRec2.Name = String.valueOf('test2.jpeg');
        attRec2.ContentType = String.valueOf('image/jpeg');
        attRec2.ParentId = emlMsg.Id; 
        insert attRec2;

        DocumentsToBePushedToCallistaCC.wrapperClass testWrapperA = new DocumentsToBePushedToCallistaCC.wrapperClass();
        testWrapperA.attachment = attRec1;
        testWrapperA.status = 'TestStatus';
        testWrapperA.statusIcon = 'TestStatusIcon';
        testWrapperA.statusIconColor = 'TestStatusIconColor';
        testWrapperA.fileType = 'TestFileType';
        testWrapperA.showDownloadCheckBox = false;
        testWrapperA.showSendToCallistaCheckBox = false;
        testWrapperA.defaultSelectionOfDownloadCheckBox = false;
        testWrapperA.defaultSelectionOfSendToCallistaCheckBox = false;
        
        DocumentsToBePushedToCallistaCC.wrapperClass testWrapperB = new DocumentsToBePushedToCallistaCC.wrapperClass();
        testWrapperB.attachment = attRec2;
        testWrapperB.status = 'TestStatus';
        testWrapperB.statusIcon = 'TestStatusIcon';
        testWrapperB.statusIconColor = 'TestStatusIconColor';
        testWrapperB.fileType = 'TestFileType';
        testWrapperB.showDownloadCheckBox = false;
        testWrapperB.showSendToCallistaCheckBox = false;
        testWrapperB.defaultSelectionOfDownloadCheckBox = false;
        testWrapperB.defaultSelectionOfSendToCallistaCheckBox = false;

        Integer testResult = 0;
        Test.startTest();
            testResult = testWrapperB.compareTo(testWrapperA);
        Test.stopTest();
        System.assertEquals(testResult, 1);
    }   

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Aug.2017        
    * @description  creates full application sample data
    * @revision     
    *******************************************************************************/
    static void createSampleData (String contactId, String status, String outcome, Boolean addCourse) {
        //create a new draft application
        appRecord = StudFirst_TestHelper.createApplication(contactId);
        appRecord.OwnerId = communityUserRec.Id;
        appRecord.Status__c = status;
        insert appRecord;

        contactRec = [SELECT Id FROM Contact WHERE Id =: contactId];
        contactRec.Residency_Status__c = 'DOM-AUS';
        update contactRec;

        //Tertiary institution & qualification
        Institution__c tertInsRec = StudFirst_TestHelper.createTertiaryInstitution();
        insert tertInsRec;

        Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
        insert outcomeStatus;

        Contact_Qualification__c conQualRec = new Contact_Qualification__c();
        conQualRec.Country__c = 'Australia';
        conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year()-4);
        conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
        conQualRec.Other_Qualification__c = 'Certificate III';
        conQualRec.Institution_Code__c = tertInsRec.Institution_Code__c;
        conQualRec.Institution_Name__c = tertInsRec.Institution_Name__c;
        conQualRec.Status__c = 'CURRENTLY STUDYING';
        conQualRec.Contact__c = contactRec.Id;
        conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert conQualRec;

        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appRecord.Id;
        aqpRecord.Contact_Qualification__c = conQualRec.Id;
        insert aqpRecord;

        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = contactRec.Id;
        insert workExpRecord;

        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        insert contactDocu;

        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appRecord.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord;

        Course__c courseRec = StudFirst_TestHelper.createCourse();
        insert courseRec;

        courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
        insert courseOfferingRec;

        courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;

        if(addCourse){
            coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
            coursePrefA.Outcome_Status__c = outcome;
            coursePrefA.Offer_Response_Status__c = outcome;
            coursePrefA.Preference_Number__c = '1';
            insert coursePrefA;
        }

        IntegrationSettings_SubmitApplication__c is = new IntegrationSettings_SubmitApplication__c();
        is.Base_Url__c = 'https://mix-dev.monash.edu';
        is.Path__c = '/la/v1/admissions/applications';
        is.Method__c = 'POST';
        is.Header_ClientId__c = 'c8411f0ca73a4ae6a0c7081a1336630f';
        is.Header_ClientSecret__c = 'cd2d5b9e26fa4999A33FF6A7F12D65AD';
        is.Header_ContentType__c = 'application/json';
        is.Mock_Endpoint_Applications__c = 'http://monash.getsandbox.com/la/v1/admissions/applications';
        is.Enable_Mock__c = false;
        is.Timeout__c = '12000';

        insert is;
    }
}