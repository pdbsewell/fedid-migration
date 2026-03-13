/**
* @description       : Test Class -  ProcessRequestForCOE_Test
* @author            : seeva.singh@monash.edu
* @group             : 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2023-03-04 - Seeva Singh     - Initial Creation
 * 1.2   2025-02-25 - Matthew Maramot - EPCP-4204 Updated API version + Assert methods
**/
@IsTest(IsParallel=true)
public with sharing class ProcessRequestForCOE_Test {
/**
* @description Create data for testing.
* @author seeva.singh@monash.edu | 04-03-2023
**/
    @testSetup
    static void setup() {
        //..Create MIX_RPA_Settings
        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);

        //..Get current user.
        User oCurrentUser = [SELECT Id FROM User WHERE Id =: System.UserInfo.getUserId()];
        
        //.. Query profile, Permset and role.
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'Base Profile'];
        PermissionSet oPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Monash_Connect_Process_COE_Request'];
        
        //.. Create user
        User oUser = new User();
        oUser.ProfileId = oProfile.Id;
        oUser.Username = CommonUtilityERDA.generateRandomString(5) + 'testingAgentUserlkj@monash.edu';
        oUser.isActive = true;
        oUser.Alias = 'test_do';
        oUser.Email='Coe_test@monash.edu';
        oUser.EmailEncodingKey='UTF-8';
        oUser.Firstname='Firstnameijk' + CommonUtilityERDA.generateRandomString(5);
        oUser.Lastname='Lastname' + CommonUtilityERDA.generateRandomString(5);
        oUser.LanguageLocaleKey='en_US';
        oUser.LocaleSidKey='en_US';
        oUser.TimeZoneSidKey='Australia/Sydney';
        
        //..Create User without Permset.
        //.. Create user
        User oUser2 = new User();
        oUser2.ProfileId = oProfile.Id;
        oUser2.Username = CommonUtilityERDA.generateRandomString(5) + 'testingAgentUser56j1@monash.edu';
        oUser2.isActive = true;
        oUser2.Alias = 'test_do';
        oUser2.Email='Coe_test2@monash.edu';
        oUser2.EmailEncodingKey='UTF-8';
        oUser2.Firstname='Firstnameijk2' + CommonUtilityERDA.generateRandomString(5);
        oUser2.Lastname='Lastname' + CommonUtilityERDA.generateRandomString(5);
        oUser2.LanguageLocaleKey='en_US';
        oUser2.LocaleSidKey='en_US';
        oUser2.TimeZoneSidKey='Australia/Sydney';
        
        System.runAs(oCurrentUser){
            Database.insert(oUser);
            Database.insert(oUser2);
            insert new PermissionSetAssignment(AssigneeId = oUser.id, PermissionSetId = oPermissionSet.Id);
        }
        System.runAs(oUser){
        //.. Create contact
        Contact oContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
        Course__c oCourse = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);
        
        Course_Attempt__c oCourseAttempt = new Course_Attempt__c();
        oCourseAttempt.Name = 'Test Course Attemptlkj';
        oCourseAttempt.Course__c = oCourse.Id;
        oCourseAttempt.Contact__c = oContact.Id;
        oCourseAttempt.Location__c = 'Clayton';
        oCourseAttempt.Course_Attempt_Status__c = 'Enrolled';
        insert oCourseAttempt;
        
        //.. Create case
        Id idRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
        Case oCase = (Case)MonConTestDataFactory.createSObject(new Case());
        oCase.SuppliedEmail = 'testEmailihg@test.edu';
        oCase.Enquiry_Type__c = 'Current Course';
        oCase.Category_Level_1__c = 'International Visa';
        oCase.Category_Level_1__c = 'COE';
        oCase.RecordTypeId = idRecordType;
        oCase.Course_Attempt__c = oCourseAttempt.Id;
        oCase.ContactId = oContact.Id;
        oCase.OwnerId=oUser.Id;
        insert oCase;
        }
    }
    
    /**
    * @description Testing COE request.
    * @author seeva.singh@monash.edu | 04-03-2023 
    **/
    @isTest
    public static void processCourseDiscontinuationTest(){
        User oDisconUser = [SELECT Id FROM User WHERE Email='Coe_test@monash.edu' LIMIT 1];
        Case oCase = [SELECT Id, OwnerId, CaseNumber, Contact_Person_ID__c FROM Case LIMIT 1];
        
        //GIVEN: We have a COE request ready to be sent by user with correct permissions
        System.runAs(oDisconUser){
            ProcessRequestForCOE.COERequest CoeRequest = new ProcessRequestForCOE.COERequest();
            CoeRequest.strCaseID = oCase.Id;
            CoeRequest.strCaseNumber = oCase.CaseNumber;
            CoeRequest.strPersonID = oCase.Contact_Person_ID__c;
            CoeRequest.strCOEReason = 'TRANSFER';
            CoeRequest.strCourseCode = 'A100';
            CoeRequest.strOfficerName = 'seeva.singh@monash.edu';
            
            Test.startTest();
            SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                                   'Complete',
                                                                   '{\n' +
                                                                   '  "queueDefinitionId": 625,\n' +
                                                                   '  "referenceKey": "57ae5730-449c-4c08-bd96-9aa7b050a327",\n' +
                                                                   '  "referenceId": "20202020-D6000",\n' +
                                                                   '  "message": "Request submitted."\n' +
                                                                   '}',
                                                                   null);
            //WHEN: The callout is initiated
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            List<String> responses = ProcessRequestForCOE.processConfirmationOfEnrolment(new List<ProcessRequestForCOE.COERequest>{CoeRequest});
            Test.stopTest(); 

            //THEN: A successful response is received
            Assert.areEqual('COE request sent to Callista for processing.', responses[0]);
        }
    }
    
/**
* @description Testing CoE request.
* @author seeva.singh@monash.edu | 01-03-2023 
**/
    @isTest
    public static void processConfirmationOfEnrolment_failed(){
        User oNonDisconUser = [SELECT Id FROM User WHERE Email='Coe_test2@monash.edu' LIMIT 1];
        Case oCase = [SELECT Id, OwnerId, CaseNumber, Contact_Person_ID__c FROM Case LIMIT 1];
        oCase.OwnerId = oNonDisconUser.Id;
        update oCase;
        
        //GIVEN: We have a COE request ready to be sent by a user with incorrect permissions
        System.runAs(oNonDisconUser){
            ProcessRequestForCOE.COERequest CoeRequest = new ProcessRequestForCOE.COERequest();
            CoeRequest.strCaseID = oCase.Id;
            CoeRequest.strCaseNumber = oCase.CaseNumber;
            CoeRequest.strPersonID = oCase.Contact_Person_ID__c;
            CoeRequest.strCourseCode = 'A100';
            CoeRequest.strCOEReason = 'TRANSFER';
            CoeRequest.strOfficerName = 'seeva.singh@monash.edu';
            
            Test.startTest();
            SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                                   'Complete',
                                                                   '{\n' +
                                                                   '  "queueDefinitionId": 625,\n' +
                                                                   '  "referenceKey": "57ae5735-449c-4c08-bd96-9aa7b050a327",\n' +
                                                                   '  "referenceId": "20202020-D6000",\n' +
                                                                   '  "message": "Request submitted."\n' +
                                                                   '}',
                                                                   null);

            //WHEN: The callout is initiated
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            List<String> responses = ProcessRequestForCOE.processConfirmationOfEnrolment(new List<ProcessRequestForCOE.COERequest>{CoeRequest});
            Test.stopTest(); 

            //THEN: Access denied response is received
            Assert.areEqual('Access denied as the user does not have access to the Case record or this feature.', responses[0]);
        }
    }
}