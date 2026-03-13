/*******************************************************************************
* @author       Russell Cadapan
* @date         24/08/2022
* @description  test class for CloneEmailMessageBatch class
* @revision     1.0
*               Russell Cadapan 24.AUG.2022 - Created
*******************************************************************************/
@IsTest(IsParallel=true)
public class CloneEmailMessageBatch_Test {

    @testSetup static void dataSetup() {
        Case testEnquiry = new case();
        testEnquiry.status = 'Open';
        testEnquiry.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard Enquiry').getRecordTypeId();
        insert testEnquiry;

        EmailMessage emailMessage =  new EmailMessage(relatedToId = testEnquiry.id,
                FromAddress = 'testfrom@testmonash.edu',
                FromName = 'testSender',
                HTMLBody = 'test',
                Subject = 'testSubject',
                TextBody = 'test body',
                Status = '0',
                MessageIdentifier = '<'+testEnquiry.id + '@sfdc.net>',
                ToAddress = 'testEndpoint@monash.edu',
                Incoming = true);
        insert emailMessage;
    }
    @isTest
    public static void flushHTMLContent_Test(){
        Integer currentYear = Date.today().year();
        test.startTest();
        CloneEmailMessageBatch testbatch = new CloneEmailMessageBatch(currentYear,currentYear, true, false, '1', true);
        Database.executeBatch(testbatch, 200);
        test.stopTest();

        List<EmailMessage> cleansedEmailMessages = [SELECT Id, HtmlBody, Is_HTML_Content_Flushed__c FROM EmailMessage];

        System.assertEquals(1, cleansedEmailMessages.size());
        System.assert(cleansedEmailMessages[0].Is_HTML_Content_Flushed__c);
        System.assertEquals(null, cleansedEmailMessages[0].HtmlBody);
    }
}