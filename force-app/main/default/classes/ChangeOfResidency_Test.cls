/**
 * @description       : Test Class for ChangeOfResidency
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 2021-01-21
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-01-21 - Angelo Rivera   - Initial Creation
 * 1.1   2025-02-25 - Matthew Maramot - EPCP-4204 Updated API version + Assert methods
**/

@isTest(isParallel=true)
private class ChangeOfResidency_Test {
    @IsTest
    static void testChangeOfResidency() {

        //GIVEN: We have Change of Residency enquiries with Contacts
        List<List_of_Values__c> lovList = new List<List_of_Values__c>();
        lovList.add(new List_of_Values__c(Name='Test1', Type__c='Change Of Residency Visa Subclass', Value__c='100', Description__c='Subclass 100', Unique_Key__c='123', System_Code__c='123'));
        lovList.add(new List_of_Values__c(Name='Test2', Type__c='Change Of Residency Faculty Name', Value__c='Jane Doe', Description__c='Faculty Of Arts', Unique_Key__c='1234', System_Code__c='1234'));
        lovList.add(new List_of_Values__c(Name='Test3', Type__c='Change Of Residency Faculty Name', Value__c='Jane Doer', Description__c='Faculty Of Engineering', Unique_Key__c='12345', System_Code__c='12345'));
        insert lovList;

        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);

        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

        Course__c crs = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);

        Course_Attempt__c ca = new Course_Attempt__c();
        ca.Name = 'Test Course Attempt';
        ca.Course__c = crs.Id;
        ca.Contact__c = testContact.Id;
        ca.Location__c = 'Clayton';
        ca.Course_Attempt_Status__c = 'Enrolled';
        insert ca;

        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.SuppliedEmail = 'testEmail@test.edu';
        cse.Enquiry_Type__c = 'Current Course';
        cse.Category_Level_1__c = 'International Visa';
        cse.Category_Level_1__c = 'Change of Residency';
        cse.RecordTypeId = caseRecType;
        cse.Course_Attempt__c = ca.Id;
        cse.ContactId = testContact.Id;
        insert cse;

        Case cse1 = (Case)MonConTestDataFactory.createSObject(new Case());
        cse1.SuppliedEmail = 'testEmail@test.edu';
        cse1.Enquiry_Type__c = 'Current Course';
        cse1.Category_Level_1__c = 'International Visa';
        cse1.Category_Level_1__c = 'Change of Residency';
        cse1.RecordTypeId = caseRecType;
        cse1.Course_Attempt__c = ca.Id;
        insert cse1;

        //WHEN: The MIX/RPA automation process is triggered 
        Test.startTest();
            ChangeOfResidency.ThisWrapper thisWrapper = ChangeOfResidency.doInit();
            String sDate = '15/03/2021', eDate = '14/03/2021', rDate = '15/03/2021', visa = 'Subclass 100', status = '301', faculty = 'Jane Doe';
            String strReturn = ChangeOfResidency.changeOfResidency(cse.Id, sDate, eDate, rDate, visa, status, faculty);
            String strReturn2 = ChangeOfResidency.changeOfResidency(cse1.Id, sDate, eDate, rDate, visa, status, faculty);
        Test.stopTest();

        //THEN: Success and fail messages are returned
        Assert.areEqual('Approved change of residency details successfully sent to Callista.', strReturn);
        Assert.areEqual('Cannot Send Request. Missing Student Info. (Course Attempt)', strReturn2);
    }
}