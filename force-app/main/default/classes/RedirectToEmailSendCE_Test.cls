/*******************************************************************************
* @author       Anterey Custodio
* @date         2.Mar.2017         
* @description  test class for RedirectToEmailSendCE
* @revision     
*******************************************************************************/
@isTest(isParallel=true)
public class RedirectToEmailSendCE_Test {
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         2.Mar.2017         
    * @description  test the constructor that checks the custom setting
    * @revision     
    *******************************************************************************/
    static testMethod void test_checkExclusionList() {
        TestHelper.calabrioSetUp();
        
        //add an email to the exclusion custom setting
        Enquiry_Email_Exclusion_List__c exclusionEmail = new Enquiry_Email_Exclusion_List__c(Name = 'excludedemail@testmonash.edu');
        insert exclusionEmail;
        
        List<Contact> studentList = TestHelper.createStudentContacts(1, null);
        insert studentList;
        
        String caseSchoolEnquiryRT = CommonServices.recordTypeId('Case', 'School_Enquiry');
        //insert 2 cases, one that is in the exclusion list and another one that's not
        List<Case> caseRecord = TestHelper.webToCaseForms(2);
        caseRecord[0].SuppliedEmail = 'legitemail@testmonash.edu';
        caseRecord[0].RecordTypeId = caseSchoolEnquiryRT;
        caseRecord[1].SuppliedEmail = 'excludedemail@testmonash.edu';
        caseRecord[1].RecordTypeId = caseSchoolEnquiryRT;
        caseRecord[1].ContactId = studentList[0].Id;
        insert caseRecord;
        
        //Scenario 1, use the web email because it is not in the exclusion list
        ApexPages.StandardController sc = new ApexPages.StandardController(caseRecord[0]);
        RedirectToEmailSendCE extension = new RedirectToEmailSendCE(sc);
        system.assertEquals('legitemail@testmonash.edu', extension.emailToUse);
        
        //Scenario 2, use the contact email because the web email is in the exclusion list
        sc = new ApexPages.StandardController(caseRecord[1]);
        extension = new RedirectToEmailSendCE(sc);
        system.assertNotEquals('excludedemail@testmonash.edu', extension.emailToUse);
        system.assertEquals(studentList[0].Monash_Email_Address__c, extension.emailToUse);
    }
}