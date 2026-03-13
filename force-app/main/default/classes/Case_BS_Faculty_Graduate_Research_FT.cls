/**
* @author Arnie Ug
* @date 07/08/2024
* @group Test Class for Flows
* @description  Test Class to test the functionality of Case_BS_Faculty_Graduate_Research Flow
* @history     07/08/2024 - Arnie Ug - Initial Creation, MGROI-313 prepopulating case information
*
**/

@isTest // (isParallel=true) not set due to APEX_DATA_ACCESS_RESTRICTION operations not permitted User
private class Case_BS_Faculty_Graduate_Research_FT {

    
    static final string BASE_FGR_EMAIL = 'myrunasuser@testorg.com';
    static final string BASE_BIOMED_FGR_EMAIL = 'mybiomedrunasuser@testorg.com';

    @testSetup
    static void setup() {
        // User setup
        createFacultyGradResearchUser();
    }

    /**
    * @description test faculty graduate research subject category mapping
    * @history 07/08/2024 - Initial Creation
    */
    @isTest
    static void testCategoryToSubjectLineMappingHDRDocReq() {
        //GIVEN sibject has <below value>
        Case tCase = new Case();
        tCase.Subject = 'Higher DREAMS Document request has been submitted';
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        System.runAs(getRunAsUser(BASE_FGR_EMAIL)) {
            insert tCase;
        }
        Test.stopTest();

        //THEN category level 1, and category level 2 is mapped accordingly
        Case updatedCase = [SELECT Id, Enquiry_Type__c, Category_Level_1__c, Category_Level_2__c, Course_Location__c FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual('Graduate Research Admissions', updatedCase.Category_Level_1__c);
        Assert.areEqual('Assessment', updatedCase.Category_Level_2__c);
    }

    /**
    * @description test faculty graduate research subject category mapping
    * @history 07/08/2024 - Initial Creation
    */
    @isTest
    static void testCategoryToSubjectLineMappingHDRCandApp() {
        //GIVEN sibject has <below value>
        Case tCase = new Case();
        tCase.Subject = 'HDR Candidature Application for';
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        System.runAs(getRunAsUser(BASE_FGR_EMAIL)) {
            insert tCase;
        }
        Test.stopTest();

        //THEN category level 1, and category level 2 is mapped accordingly
        Case updatedCase = [SELECT Id, Enquiry_Type__c, Category_Level_1__c, Category_Level_2__c, Course_Location__c FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual('Graduate Research Admissions', updatedCase.Category_Level_1__c);
        Assert.areEqual('Assessment', updatedCase.Category_Level_2__c);
        Assert.areEqual('Future Course', updatedCase.Enquiry_Type__c);
    }
    
    /**
    * @description test faculty graduate research subject category mapping
    * @history 07/08/2024 - Initial Creation
    */
    @isTest
    static void testCategoryToSubjectLineMappingOfferRes() {
        //GIVEN sibject has <below value>
        Case tCase = new Case();
        tCase.Subject = 'Offer response request outcome';
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        System.runAs(getRunAsUser(BASE_FGR_EMAIL)) {
            insert tCase;
        }
        Test.stopTest();

        //THEN category level 1, and category level 2 is mapped accordingly
        Case updatedCase = [SELECT Id, Enquiry_Type__c, Category_Level_1__c, Category_Level_2__c, Course_Location__c FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual('Graduate Research Admissions', updatedCase.Category_Level_1__c);
        Assert.areEqual('Acceptance', updatedCase.Category_Level_2__c);
        Assert.areEqual('Current Course', updatedCase.Enquiry_Type__c);
    }
    
    /**
    * @description test faculty graduate research subject category mapping
    * @history 07/08/2024 - Initial Creation
    */
    @isTest
    static void testCategoryToSubjectLineMappingDocExam() {
        //GIVEN sibject has <below value>
        Case tCase = new Case();
        tCase.Subject = 'Doctorate Examination';
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        System.runAs(getRunAsUser(BASE_FGR_EMAIL)) {
            insert tCase;
        }
        Test.stopTest();

        //THEN category level 1, and category level 2 is mapped accordingly
        Case updatedCase = [SELECT Id, Enquiry_Type__c, Category_Level_1__c, Category_Level_2__c, Course_Location__c FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual('Candidature', updatedCase.Category_Level_1__c);
        Assert.areEqual('Thesis Submission', updatedCase.Category_Level_2__c);
        Assert.areEqual('Current Course', updatedCase.Enquiry_Type__c);
    }

    
    /**
    * @description test faculty graduate research subject category mapping
    * @history 07/08/2024 - Initial Creation
    */
    @isTest
    static void testCategoryToSubjectLineMappingEnrollment() {
        //GIVEN sibject has <below value>
        Case tCase = new Case();
        tCase.Subject = 'Enrollment information';
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        System.runAs(getRunAsUser(BASE_FGR_EMAIL)) {
            insert tCase;
        }
        Test.stopTest();

        //THEN category level 1, and category level 2 is mapped accordingly
        Case updatedCase = [SELECT Id, Enquiry_Type__c, Category_Level_1__c, Category_Level_2__c, Course_Location__c FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual('Candidature', updatedCase.Category_Level_1__c);
        Assert.areEqual('Enrolment', updatedCase.Category_Level_2__c);
        Assert.areEqual('Future Course', updatedCase.Enquiry_Type__c);
    }
    
    /**
    * @description test faculty graduate research subject category mapping
    * @history 07/08/2024 - Initial Creation
    */
    @isTest
    static void testCategoryToSubjectLineMappingSupAccConfirm() {
        //GIVEN sibject has <below value>
        Case tCase = new Case();
        tCase.Subject = 'Supervisor Accreditation Confirmation';
        tCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        tCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();

        //WHEN
        Test.startTest();
        System.runAs(getRunAsUser(BASE_FGR_EMAIL)) {
            insert tCase;
        }
        Test.stopTest();

        //THEN category level 1, and category level 2 is mapped accordingly
        Case updatedCase = [SELECT Id, Enquiry_Type__c, Category_Level_1__c, Category_Level_2__c, Course_Location__c FROM Case WHERE Id = :tCase.Id LIMIT 1];

        Assert.areEqual('Supervisor Accreditation', updatedCase.Category_Level_1__c);
        Assert.areEqual('Accreditation', updatedCase.Category_Level_2__c);
        Assert.areEqual('Current Course', updatedCase.Enquiry_Type__c);
    }

    static User getRunAsUser(String emailParam) {
        return [SELECT Id, Username FROM User WHERE Email = :emailParam];
    }

    static User baseFacultyGradResearchUser(){
        // Create the partner account owner user
        String username = 'User' + Math.random()*100 + Datetime.now().getTime() + '@test.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Faculty Graduate Research Profile']; 
        UserRole r = [SELECT Id FROM UserRole WHERE Name='Chemistry - Graduate Research']; // can be any userrole her

        User u = new User(Alias = 'standt', Email=BASE_FGR_EMAIL, 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=username);

        return u;
    }

    static User createFacultyGradResearchUser() {
        User u = baseFacultyGradResearchUser();

        insert u;
        return u;
    }

}