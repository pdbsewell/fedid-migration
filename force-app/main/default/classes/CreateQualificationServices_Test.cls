/**
* @author 
* @date 2019
* @group Test Class
* @description
*/
@isTest(isParallel=true)
private class CreateQualificationServices_Test {
    static testMethod void test_fetchInitialData() {
        Country_Attribute__c countryAttribute = new Country_Attribute__c(
            Country__c = 'Australia'
        );
        insert countryAttribute;

        Institution__c institution = new Institution__c(
            Institution_Name__c = 'STI'
        );
        insert institution;

        String admissionTestRecTypeId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Admission_Test'].Id;
        Qualification__c qualificationEnglishTest = new Qualification__c(
            RecordTypeId = admissionTestRecTypeId,
            Available_on_Portal__c = true,
            Qualification_Name__c = 'SMCL English Test',
            Callista_Code__c = 'Test Callista Code 1'
        );
        insert qualificationEnglishTest;

        String admissionTertiaryId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Tertiary_Qualification'].Id;
        Qualification__c qualificationTertiary = new Qualification__c(
            RecordTypeId = admissionTertiaryId,
            Qualification_Name__c = 'SMCL Tertiary',
            Callista_Code__c = 'Test Callista Code 2'
        );
        insert qualificationTertiary;
        
        CreateQualificationServices.DataWrapper result = CreateQualificationServices.fetchInitialData();
        
        // Assert
        System.assertNotEquals(null, result);
        System.assert(result.qualificationRecordTypeOptions != null);
        System.assert(result.countryStudiedOptions != null);
        System.assert(result.institutionOptions != null);
        System.assert(result.completionStatusOptions != null);
        System.assert(result.ausStateOptions != null);
        System.assert(result.qualificationOptions != null);
        System.assert(result.admissionTestOptions != null);
        System.assert(result.tertiaryQualificationLevelOptions != null);
        System.assert(result.qualificationGPACalcMethodOptions != null);
        System.assert(result.monashEquivalentGPAOptions != null);
        System.assert(result.verificationStatusOptions != null);
    }

    static testMethod void test_createQualification() {
        // Create test account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;
        System.assert(testAccount.Id != null, '### Insert Test Account Failed.');

        //Create test contact
        Contact testContact = new Contact();
        testContact.FirstName = 'Test FirstName';
        testContact.LastName = 'Test LastName';
        testContact.MobilePhone = '0481977625';
        testContact.Email = 'testemail001@monash.edu';
        testContact.Birthdate = Date.today().addYears(-11);
        testContact.SAP_Staff_Id__c = '';
        insert testContact;
        System.assert(testContact.Id != null, '### Insert Test Contact Failed.');

        Application__c application = new Application__c(
            Assessment_Status__c = 'In Progress',
            Task_Duplicate_Check__c = 'In Progress',
            Task_GTE__c = 'In Progress',
            Task_MinEnglish__c = 'In Progress',
            Applicant__c = testContact.Id
        );
        insert application;
        System.assert(application.Id != null, '### Error! Application creation failed.');

        String conQualOtherRecTypeId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Other_Qualification' AND sObjectType = 'Contact_Qualification__c'].Id;
        Contact_Qualification__c contactQualification = new Contact_Qualification__c(
            RecordTypeId = conQualOtherRecTypeId,
            Other_Qualification__c = 'Test Other Qualification'
        );
        String jsonParam = JSON.serialize(contactQualification);
        CreateQualificationServices.DataWrapperAddResult result = CreateQualificationServices.createQualification(application.Id, jsonParam);

        // Assert
        System.assertNotEquals(null, result);
        System.assert(result.status == 'success');
        System.assert([SELECT COUNT() FROM Contact_Qualification__c] > 0);
        System.assert([SELECT COUNT() FROM Application_Qualification_Provided__c] > 0);
    }
}