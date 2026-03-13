/**
 * Created by ariv0002 on 22/10/2018.
 */

@isTest(isParallel=true)
private class Console_OffSystemEmail_CEv2_Test {
    @IsTest
    static void testBehavior() {
        TestHelper.calabrioSetUp();
        List<Contact> testContacts = TestHelper.createStudentContacts(1, null);
        insert testContacts;

        List<Case> webToCaseForms = TestHelper.webToCaseForms(1);
        webToCaseForms[0].contactId = testContacts[0].id;
        insert webToCaseForms;

        insert TestHelper.createAttachments(10, webToCaseForms[0].id);

        insert TestHelper.createTasks(10, testContacts[0].id, webToCaseForms[0].id);

        insert TestHelper.createEmailMessages( 6,webToCaseForms[0].id,'Test Monash', 'test@f.e.monash.edu','testonly@monash.edu');


        Test.startTest();
            List<Id> lstAttIds = new List<Id>();
            Id cseId = [Select Id from case].Id;
            Console_OffSystemEmail_CEv2.init(cseId);
            Console_OffSystemEmail_CEv2.initiateSendingEmail(cseId, 'testonly@monash.edu', lstAttIds, 'true', 'This is a test');
        	Console_OffSystemEmail_CEv2.initiateSendingEmail(cseId, 'testonly@monash.edu', lstAttIds, 'false', 'This is a test');
        Test.stopTest();

    }
}