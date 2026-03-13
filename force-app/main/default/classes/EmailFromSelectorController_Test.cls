/**
* @description	: Test class for EmailFromSelectorController
* @author				: Angelo Rivera
* @group				: Test Class
* @last modified on  : 22/10/2018
* @last modified by  : Angelo Rivera
* Modifications Log
* Ver   Date         Author          Modification
* 1.0   22/10/2018 - Angelo Rivera - Initial Creation
* 1.0   02/06/2021 - Angelo Rivera - Fix test class
* 1.1   28/11/2023 - Jitender Padda - Update test class for Faculty filter
* 1.2   27/05/2024 - Davey Yu - Update test class for Faculty School filter
**/
@IsTest(IsParallel=true)
public class EmailFromSelectorController_Test {
    /**
* @description - Test default behaviour of From Address
*/
    @IsTest
    static void testDefaultBehavior() {
        // GIVEN
        Id standardEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Standard Enquiry')
            .getRecordTypeId();
        Case testCase = new Case(RecordTypeId = standardEnquiryRecordTypeId);
        TriggerCommon.disableTrigger('Case');
        insert testCase;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
        // WHEN
            EmailFromSelectorController.ThisWrapperClass wrapperResult = EmailFromSelectorController.init(testCase.Id);
            Test.stopTest();
        //THEN
            System.assert(wrapperResult.lstEmailFrom.size() > 0,'List of Email returned records');
        }
    }
    /**
* @description - Test Faculty Enquiry filter for From Address
*/
    @IsTest
    static void testFacultyFilter() {
        // GIVEN
        Id facultyGradResearchRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Faculty_Graduate_Research')
            .getRecordTypeId();
        Case testCase = new Case(RecordTypeId = facultyGradResearchRecordTypeId, Faculty__c = 'Business and Economics');
        TriggerCommon.disableTrigger('Case');
        insert testCase;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
        // WHEN
            EmailFromSelectorController.ThisWrapperClass wrapperResult = EmailFromSelectorController.init(testCase.Id);
            Test.stopTest();
        // THEN
            System.assert(wrapperResult.lstEmailFrom.size() == 1,'List of Email returned 1 records');
            System.assert(wrapperResult.lstEmailFrom[0].From_Address__c == 'buseco-research.degrees@f.e.monash.edu','From Address is matching');
        }
    }
    /**
* @description - Test method to test if it saves the latest From Address
**/
    @IsTest
    static void testsSaveLatestEnquiryFromAddress() {
        // GIVEN
        Id facultyGradResearchRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Faculty_Graduate_Research')
            .getRecordTypeId();
        Case testCase = new Case(RecordTypeId = facultyGradResearchRecordTypeId, Faculty__c = 'Business and Economics');
        TriggerCommon.disableTrigger('Case');
        insert testCase;
        Test.startTest();
        // WHEN
        System.runAs(new User(Id = UserInfo.getUserId())) {
            EmailFromSelectorController.ThisWrapperClass wrapperResult = EmailFromSelectorController.init(testCase.Id);
            EmailFromSelectorController.saveLatestEnquiryFromAddress('Test456@testgmail.com');
            Test.stopTest();
         // THEN
            System.assert(wrapperResult.lstEmailFrom.size() == 1,'List of Email returned 1 records');
        }
    }
    
    /**
     * @description - Test Faculty School Enquiry filter for From Address
	**/
    @IsTest
    static void testFacultySchoolFilter() {
        // GIVEN
        Id facultyGradResearchRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Faculty_Graduate_Research')
            .getRecordTypeId();
        Case testCase = new Case(RecordTypeId = facultyGradResearchRecordTypeId, Faculty__c = 'MNHS', School__c ='Medicine, Nursing & Health Sciences');
        TriggerCommon.disableTrigger('Case');
        insert testCase;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
        // WHEN
            EmailFromSelectorController.ThisWrapperClass wrapperResult = EmailFromSelectorController.init(testCase.Id);
            Test.stopTest();
        // THEN
            System.assert(wrapperResult.lstEmailFrom.size() == 1,'List of Email returned 1 records');
            System.assert(wrapperResult.lstEmailFrom[0].From_Address__c == 'med-research.degrees@f.e.monash.edu','From Address is matching');
        }
    }
}