/**
 * @description       : Test class for Case : AU : Set Redirection Key flow
 * @author            : Matthew Maramot
 * @created date      : 03/07/2024
**/
@isTest (isParallel=true)
public with sharing class CaseAUSetRedirectionKey_FT {
    final static Id artsGraduateQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Arts_Graduate_Research' LIMIT 1].Id;
    
    //Set up test data that will be used across all test methods
	@testSetup
	static void setup(){
        List<Case> caseList = new List<Case>();

        //Create MRO Enquiry
        Case newMROCase = new Case();
        newMROCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
        caseList.add(newMROCase);

        //Create Arts Faculty Enquiry
        Case newFacultyCase = new Case();
        newFacultyCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Faculty_Graduate_Research').getRecordTypeId();
        newFacultyCase.OwnerId = artsGraduateQueue;
        caseList.add(newFacultyCase);
        insert caseList;
	}

    @isTest
    private static void RedirectionKey_Test() {      
        // GIVEN : MRO or Faculty Graduate Research enquiries
        Case mroCase = [SELECT Id, Enquiry_Type__c, Group__c FROM Case WHERE RecordType.DeveloperName = 'MRO' LIMIT 1];
        Case facultyCase = [SELECT Id, Faculty__c, School__c FROM Case WHERE RecordType.DeveloperName = 'Faculty_Graduate_Research' LIMIT 1];

        // WHEN : Enquiry is updated or created
        Test.startTest();
        mroCase.Enquiry_Type__c = 'Research Development';
        mroCase.Group__c = 'Major Initiative';
        update mroCase;

        // THEN : Redirection Key field will be populated
        Test.stopTest();
        Assert.areEqual(1, [SELECT Id  FROM Case WHERE Redirection_Key__c LIKE 'Research DevelopmentMajor Initiative'].size(), 'MRO key not assigned correctly');
        Assert.areEqual(1, [SELECT Id  FROM Case WHERE Redirection_Key__c LIKE 'Arts'].size(), 'Faculty Graduate enquiry key not assigned correctly'); 
    }
}