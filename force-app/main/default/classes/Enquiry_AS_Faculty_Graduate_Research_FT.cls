/**
* @author Arnie Ug
* @date 22/05/2024
* @group Test Class for Flows
* @description  Test Class to test the functionality of Enquiry_AS_Faculty_Graduate_Research Flow
* @history     22/05/2024 - Arnie Ug - Initial Creation, MGROI-250/251 prepopulating case information
*
**/

@isTest(isParallel=true)
private class Enquiry_AS_Faculty_Graduate_Research_FT {

    @testSetup
    static void setup() {
        //Populate custom settings
        MonConTestDataFactory.createSObject(new RecordTypes_Allowed_on_CaseTrigger__c(), true);
        MonConTestDataFactory.createSObject(new Environment_Settings__c(), true);
        MonConTestDataFactory.createSObject(new CalabrioIntegration__c(), true);
        //Create test course
        MonConTestDataFactory.createSObject(new Course__c(), true);
        //Create test contact to associate the enquiry with
        MonConTestDataFactory.createSObject(new Contact(), true);
    }

    /**
    * @description test auto populate Pharmacy's course location and campus
    * @history 30/05/2024 - Initial Creation
    */
    @isTest
    static void testPopulateFacultyPharmacyCourseLocation() {
        //GIVEN course location and campus is NOT populated
        Case tCase = new Case();
        tCase.Subject = 'course location and campus chaeck';
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.Faculty__c = 'Pharmacy and Pharmaceutical Sciences';
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        insert tCase;
        Test.stopTest();

        //THEN course location and campus should be Parkville
        Case updatedCase = [SELECT Id, Campus__c, Course_Location__c FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual('Parkville', updatedCase.Campus__c, 'Campus__c did not populate into Parkville');
        Assert.areEqual('Parkville', updatedCase.Course_Location__c, 'Course_Location__c did not populate into Parkville');
    }

    /**
    * @description test do not auto populate Pharmacy's course location and campus when it is already populated
    * @history 30/05/2024 - Initial Creation
    */
    @isTest
    static void testPopulateFacultyPharmacyCourseLocationNegative() {
        //GIVEN course location and campus is populated
        String campus = 'Caulfield';
        String courseLocation = 'CAUFIELD';
        Case tCase = new Case();
        tCase.Subject = 'course location and campus chaeck';
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.Campus__c = campus;
        tCase.Course_Location__c = courseLocation;
        tCase.Faculty__c = 'Pharmacy and Pharmaceutical Sciences';
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        insert tCase;
        Test.stopTest();

        //THEN course location and campus should be not change to Parkville
        Case updatedCase = [SELECT Id, Campus__c, Course_Location__c FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual(campus, updatedCase.Campus__c, 'Campus__c was overidden');
        Assert.areEqual(courseLocation, updatedCase.Course_Location__c,  'Course_Location__c was overidden');
    }

    /**
    * @description categorize, remove contact and solve enquiry for EOIs
    * @history 30/05/2024 - Initial Creation
    */
    @isTest
    static void testPopulateFacultyPharmacyEOI() {
        //GIVEN case was created from Pharamacy EOI process
        Case tCase = new Case();
        tCase.Subject = 'Submission: Expression of Interest Form for PhD and MPhil Degrees'; //identifier
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.Faculty__c = 'Pharmacy and Pharmaceutical Sciences';
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        insert tCase;
        Test.stopTest();

        //THEN multiple values should be defaulted after creation
        Case updatedCase = [SELECT Id, Enquiry_Type__c, Category_Level_1__c, Category_Level_2__c, ContactId, Status FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual('Future Course', updatedCase.Enquiry_Type__c, 'Enquiry_Type__c value incorrect');
        Assert.areEqual('Expression of Interest', updatedCase.Category_Level_1__c, 'Category_Level_1__c value incorrect');
        Assert.areEqual('General', updatedCase.Category_Level_2__c, 'Category_Level_2__c value incorrect');
        Assert.areEqual(null, updatedCase.ContactId, 'ContactId value incorrect');
        Assert.areEqual('Solved', updatedCase.Status, 'Status value incorrect');
    }
}