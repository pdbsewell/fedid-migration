/**
* @description       : Test Class - CourseDiscontinuation
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 28-06-2022
* @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest
public with sharing class CourseDiscontinuation_Test {
    /**
* @description Create data for testing.
* @author rajesh.punjabi@monash.edu | 07-06-2022 
**/
    @testSetup
    static void setup() {
        //.. Create Mix Setting.
        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);
        
        //..Get current user.
        User oCurrentUser = [SELECT Id FROM User WHERE Id =: System.UserInfo.getUserId()];
        
        //.. Query profile, Permset and role.
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'Base Profile'];
        PermissionSet oPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'SS_EnquiryManagementCourseDiscontinuation'];
        
        //.. Create user
        User oUser = new User();
        oUser.ProfileId = oProfile.Id;
        oUser.Username = CommonUtilityERDA.generateRandomString(5) + 'testingAgentUser1@monash.edu';
        oUser.isActive = true;
        oUser.Alias = 'test_do';
        oUser.Email='discon_test@monash.edu';
        oUser.EmailEncodingKey='UTF-8';
        oUser.Firstname='Firstname' + CommonUtilityERDA.generateRandomString(5);
        oUser.Lastname='Lastname' + CommonUtilityERDA.generateRandomString(5);
        oUser.LanguageLocaleKey='en_US';
        oUser.LocaleSidKey='en_US';
        oUser.TimeZoneSidKey='Australia/Sydney';
        
        //..Create User without Permset.
        //.. Create user
        User oUser2 = new User();
        oUser2.ProfileId = oProfile.Id;
        oUser2.Username = CommonUtilityERDA.generateRandomString(5) + 'testingAgentUser1@monash.edu';
        oUser2.isActive = true;
        oUser2.Alias = 'test_do';
        oUser2.Email='discon_test2@monash.edu';
        oUser2.EmailEncodingKey='UTF-8';
        oUser2.Firstname='Firstname' + CommonUtilityERDA.generateRandomString(5);
        oUser2.Lastname='Lastname' + CommonUtilityERDA.generateRandomString(5);
        oUser2.LanguageLocaleKey='en_US';
        oUser2.LocaleSidKey='en_US';
        oUser2.TimeZoneSidKey='Australia/Sydney';
        
        System.runAs(oCurrentUser){
            Database.insert(oUser);
            Database.insert(oUser2);
            insert new PermissionSetAssignment(AssigneeId = oUser.id, PermissionSetId = oPermissionSet.Id);
        }
        
        //.. Create contact
        Contact oContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
        Course__c oCourse = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);
        
        Course_Attempt__c oCourseAttempt = new Course_Attempt__c();
        oCourseAttempt.Name = 'Test Course Attempt';
        oCourseAttempt.Course__c = oCourse.Id;
        oCourseAttempt.Contact__c = oContact.Id;
        oCourseAttempt.Location__c = 'Clayton';
        oCourseAttempt.Course_Attempt_Status__c = 'Enrolled';
        insert oCourseAttempt;
        
        //.. Create case
        Id idRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
        Case oCase = (Case)MonConTestDataFactory.createSObject(new Case());
        oCase.SuppliedEmail = 'testEmail@test.edu';
        oCase.Enquiry_Type__c = 'Current Course';
        oCase.Category_Level_1__c = 'Enrolment - Current Course';
        oCase.Category_Level_1__c = 'Discontinue';
        oCase.RecordTypeId = idRecordType;
        oCase.Course_Attempt__c = oCourseAttempt.Id;
        oCase.ContactId = oContact.Id;
        oCase.OwnerId=oUser.Id;
        insert oCase;
    }
    
    /**
    * @description Testing Discontinuation request.
    * @author rajesh.punjabi@monash.edu | 07-06-2022 
    **/
    @isTest
    public static void processCourseDiscontinuationTest(){
        User oDisconUser = [SELECT Id FROM User WHERE Email='discon_test@monash.edu' LIMIT 1];
        Case oCase = [SELECT Id, OwnerId, CaseNumber, Contact_Person_ID__c FROM Case LIMIT 1];
        
        System.runAs(oDisconUser){
            CourseDiscontinuation.CourseDiscontinuationRequest oCourseDiscontinuationRequest = new CourseDiscontinuation.CourseDiscontinuationRequest();
            oCourseDiscontinuationRequest.strCaseID = oCase.Id;
            oCourseDiscontinuationRequest.strCaseNumber = oCase.CaseNumber;
            oCourseDiscontinuationRequest.strPersonID = oCase.Contact_Person_ID__c;
            oCourseDiscontinuationRequest.strCourseCode = 'A100';
            oCourseDiscontinuationRequest.dtDiscontinDate = System.today() - 5;
            oCourseDiscontinuationRequest.strDiscontinReason = 'Reason to Disconnect Course';
            oCourseDiscontinuationRequest.SubmissionDate = System.today() - 1;
            oCourseDiscontinuationRequest.strOfficerName = 'rajeshpunjabi@monash.edu';
            
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
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            CourseDiscontinuation.processCourseDiscontinuation(new List<CourseDiscontinuation.CourseDiscontinuationRequest>{oCourseDiscontinuationRequest});
            Test.stopTest(); 
        }
    }
    
    /**
    * @description Testing Discontinuation request.
    * @author rajesh.punjabi@monash.edu | 07-06-2022 
    **/
    @isTest
    public static void processCourseDiscontinuationTest_failed(){
        User oNonDisconUser = [SELECT Id FROM User WHERE Email='discon_test2@monash.edu' LIMIT 1];
        Case oCase = [SELECT Id, OwnerId, CaseNumber, Contact_Person_ID__c FROM Case LIMIT 1];
        oCase.OwnerId = oNonDisconUser.Id;
        update oCase;
        
        System.runAs(oNonDisconUser){
            CourseDiscontinuation.CourseDiscontinuationRequest oCourseDiscontinuationRequest = new CourseDiscontinuation.CourseDiscontinuationRequest();
            oCourseDiscontinuationRequest.strCaseID = oCase.Id;
            oCourseDiscontinuationRequest.strCaseNumber = oCase.CaseNumber;
            oCourseDiscontinuationRequest.strPersonID = oCase.Contact_Person_ID__c;
            oCourseDiscontinuationRequest.strCourseCode = 'A100';
            oCourseDiscontinuationRequest.dtDiscontinDate = System.today() - 5;
            oCourseDiscontinuationRequest.strDiscontinReason = 'Reason to Disconnect Course';
            oCourseDiscontinuationRequest.SubmissionDate = System.today() - 1;
            oCourseDiscontinuationRequest.strOfficerName = 'rajeshpunjabi@monash.edu';
            
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
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            CourseDiscontinuation.processCourseDiscontinuation(new List<CourseDiscontinuation.CourseDiscontinuationRequest>{oCourseDiscontinuationRequest});
            Test.stopTest(); 
        }
    }
}