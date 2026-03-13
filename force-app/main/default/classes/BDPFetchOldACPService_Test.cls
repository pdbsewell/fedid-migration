/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BDPFetchOldACPService class
 * @group       Bulk Data Processing 
 * @revision    06/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BDPFetchOldACPService_Test {

    @isTest static void whenSuccess(){
        //Account Createion
        TriggerCommon.disableTrigger('Account');
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        TriggerCommon.disableTrigger('Contact');
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c='123456'), true);
        
        Bulk_Data_Processing__c[] bdpList = new Bulk_Data_Processing__c[]{(Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(Applicant__c = contact.Id), 'TestDataFactorySettings.BulkDataProcessingDefaults', false)};

        Test.startTest();
            BDPFetchOldACPService service = new BDPFetchOldACPService();
            IPromise pro = service.init();
            service.courseAttemptSelector = (CourseAttemptsSelector) Test.createStub(CourseAttemptsSelector.class, new CourseAttemptsSelectorMock());
            service.execute(bdpList);
        Test.stopTest();
        System.assert(bdpList[0].Transfer_From__c != null);
        System.assert(bdpList[0].Log__c == null);
    }
    
    @isTest static void whenCourseAttemptNotFound(){
        Bulk_Data_Processing__c[] bdpList = new Bulk_Data_Processing__c[]{(Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false)};

        Test.startTest();
            BDPFetchOldACPService service = new BDPFetchOldACPService();
            IPromise pro = service.init();
            service.execute(bdpList);
        Test.stopTest();
        System.assert(bdpList[0].Transfer_From__c == null);
        System.assert(bdpList[0].Log__c != null);
    }

    private class CourseAttemptsSelectorMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            Contact con = [SELECT Id FROM Contact WHERE Lastname='Con1' LIMIT 1];
            if ('selectActiveByContactIdAndCourseCode'.equals(stubbedMethodName)) {
                return (Course_Attempt__c[]) JSON.deserialize('[{"attributes":{"type":"Course_Attempt__c","url":"/services/data/v49.0/sobjects/Course_Attempt__c/a3R4Y0000000TEhUAM"},"Id":"a3R4Y0000000TEhUAM","Name":"28115120/C2001","Contact__c":"'+con.Id+'","Course_Code__c":"C2001","Course__c":"a0B4Y000000BQwyUAG","Course_Attempt_Status__c":"Enrolled","Location__c":"MALAYSIA","Application_Course_Preference__c":"a204Y0000009RoNQAU","Course__r":{"attributes":{"type":"Course__c","url":"/services/data/v49.0/sobjects/Course__c/a0B4Y000000BQwyUAG"},"Id":"a0B4Y000000BQwyUAG","Name":"C2001"},"Application_Course_Preference__r":{"attributes":{"type":"Application_Course_Preference__c","url":"/services/data/v49.0/sobjects/Application_Course_Preference__c/a204Y0000009RoNQAU"},"Id":"a204Y0000009RoNQAU"}}]', List<Course_Attempt__c>.class);
            }
            return null;
        }

    }
}