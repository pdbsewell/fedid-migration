/**
 * @author       M.Maramot
 * @date         13/Jan/2025
 * @description  This class contains unit tests for the flow Case : AS : Student Type which
 *               automatically populates the Student Type field on enquiry
 * @revision
 *               13.Jan.25 M.Maramot - Create Class
 **/
@isTest(isParallel=true)
public class Case_AS_StudentType_FT {
    /*******************************************************************************
    * @author       M.Maramot
    * @date         13.Jan.2025
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        // Create existing enquiry to test on update
        Case newEnq = (Case)TestDataFactory.createSObject(new Case(Subject = 'InsertCase',Status = 'Open', 
                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId()), true); 
    }

    /*******************************************************************************
    * @author       M.Maramot
    * @date         13.Jan.2025
    * @description  This method tests that Student Type is auto populated based on Supplied Nationality
    *******************************************************************************/
    static testMethod void testCaseWithNationality() {
        // GIVEN: Enquiries with supplied nationalities
        List<Case> lstEnq = new List<Case>();
        Case createCase = (Case)TestDataFactory.createSObject(new Case(Subject = 'CreateCase',Status = 'Open', 
                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                Supplied_Nationality__c = 'AUSTRALIA'), false);
        lstEnq.add(createCase);

        Case updateCase = [SELECT Id, Supplied_Nationality__c FROM Case WHERE Subject = 'InsertCase' LIMIT 1];
        updateCase.Supplied_Nationality__c = 'OTHER';
        lstEnq.add(updateCase);
        
        
        // WHEN: The enquiries are created or updated
        Test.startTest();
        upsert lstEnq;
        Test.stopTest();

        // THEN: Student Type is field is automatically populated
        List<Case> updatedDomestic = [SELECT Id FROM Case WHERE Student_Type__c = 'Domestic'];
        List<Case> updatedInternational = [SELECT Id FROM Case WHERE Student_Type__c = 'International'];
        Assert.areEqual(1, updatedDomestic.size(), 'Expected an enquiry with Student Type domestic');
        Assert.areEqual(1, updatedInternational.size(), 'Expected an enquiry with Student Type international');
    }

    /*******************************************************************************
    * @author       M.Maramot
    * @date         13.Jan.2025
    * @description  This method tests that Student Type is auto populated based on Residency Status
    *******************************************************************************/
    static testMethod void testCaseWithResidency(){
        // GIVEN: Enquiries with residency status
        List<Case> lstEnq = new List<Case>();
        Case createCase = (Case)TestDataFactory.createSObject(new Case(Subject = 'CreateCase',Status = 'Open', 
                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                Residency_Status__c = 'Australian Citizen'), false);
        lstEnq.add(createCase);

        Case updateCase = [SELECT Supplied_Nationality__c FROM Case WHERE Subject = 'InsertCase' LIMIT 1];
        updateCase.Residency_Status__c = 'Other (International)';
        lstEnq.add(updateCase);
        
        // WHEN: The enquiries are created or updated
        Test.startTest();
        upsert lstEnq;
        Test.stopTest();

        // THEN: Student Type is field is automatically populated
        List<Case> updatedDomestic = [SELECT Id FROM Case WHERE Student_Type__c = 'Domestic'];
        List<Case> updatedInternational = [SELECT Id FROM Case WHERE Student_Type__c = 'International'];
        Assert.areEqual(1, updatedDomestic.size(), 'Expected an enquiry with Student Type domestic');
        Assert.areEqual(1, updatedInternational.size(), 'Expected an enquiry with Student Type international');
    }

    /*******************************************************************************
    * @author       M.Maramot
    * @date         13.Jan.2025
    * @description  This method tests that Student Type is auto populated based on the linked Contact Profile
    *******************************************************************************/
    static testMethod void testCaseWithContactProfile(){
        // Contact creation
        Contact domStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstStudentName', Campus__c = 'Caulfield',
        LastName ='LastName', Email = 'FirstStudentName@test.com', 	Contact_Profile__c = 'Current Student (Dom) [CSD]'), true);

        // WHEN: A case is updated with a Domestic student Contact
        Case updateCase = [SELECT ContactId FROM Case WHERE Subject = 'InsertCase' LIMIT 1];
        updateCase.ContactId = domStudent.Id;

        Test.startTest();
        update updateCase;
        Test.stopTest();
    

        // THEN: Student Type is field is automatically populated
        List<Case> updatedDomestic = [SELECT Id FROM Case WHERE Student_Type__c = 'Domestic'];
        Assert.areEqual(1, updatedDomestic.size(), 'Expected an enquiry with Student Type domestic');
    }

    /*******************************************************************************
    * @author       M.Maramot
    * @date         13.Jan.2025
    * @description  This method tests that Student Type is auto populated based on the linked Citizenship Profile
    *******************************************************************************/
    static testMethod void testCaseWithCitizenship(){
        // GIVEN: International Contact and an Enquiry
        Contact intStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstStudentName', Campus__c = 'Caulfield',
        LastName ='LastName', Email = 'FirstStudentName@test.com', 	Citizenship__c = 'INTERNATIONAL'), true);

        // WHEN: A case is updated with a International student Contact
        Case updateCase = [SELECT ContactId FROM Case WHERE Subject = 'InsertCase' LIMIT 1];
        updateCase.ContactId = intStudent.Id;

        Test.startTest();
        update updateCase;
        Test.stopTest();
    
        // THEN: Student Type is field is automatically populated
        List<Case> updatedInternational = [SELECT Id FROM Case WHERE Student_Type__c = 'International'];
        Assert.areEqual(1, updatedInternational.size(), 'Expected an enquiry with Student Type International');
    }
}