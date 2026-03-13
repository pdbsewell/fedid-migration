/**
 * @description      : Test class for VaccinateCases
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 28-02-2022
 * @last modified by  : tom.gangemi@monash.edu
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   19-10-2021 - Angelo Rivera - Initial Creation
 * 2.0   28-02-2022 - Tom Gangemi   - SA-1312
**/

@IsTest(IsParallel=true)
private class VaccinateCases_Test {

    @TestSetup
    static void setup() {
        Contact testContact = (Contact) MonConTestDataFactory.createSObject(new Contact(), true);

        List<Case> lstCases = new List<Case>();

        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Special_Consideration').getRecordTypeId();

        // 2x Staff Approved
        Case cse = new Case();
        cse.SuppliedEmail = 'testEmail@test.edu';
        cse.Enquiry_Type__c = 'Vaccinate Monash - Staff';
        cse.Category_Level_1__c = 'COVID-19 Vaccination Proof';
        cse.Category_Level_2__c = 'COVID Certificate';
        cse.RecordTypeId = caseRecType;
        cse.ContactId = testContact.Id;
        cse.Status = 'Solved';
        cse.Case_Outcome__c = 'Approved Vaccination Certificate';
        lstCases.add(cse);

        Case cse1 = new Case();
        cse1.SuppliedEmail = 'testEmail@test.edu';
        cse1.Enquiry_Type__c = 'Vaccinate Monash - Staff';
        cse1.Category_Level_1__c = 'COVID-19 Vaccination Proof';
        cse1.Category_Level_2__c = 'COVID Certificate';
        cse1.RecordTypeId = caseRecType;
        cse1.ContactId = testContact.Id;
        cse1.Status = 'Solved';
        cse1.Case_Outcome__c = 'Approved Vaccination Certificate';
        lstCases.add(cse1);

        // 1x Staff Exemption
        Case cse5 = new Case();
        cse5.SuppliedEmail = 'testEmail@test.edu';
        cse5.Enquiry_Type__c = 'Vaccinate Monash - Staff';
        cse5.Category_Level_1__c = 'COVID-19 Vaccination Proof';
        cse5.Category_Level_2__c = 'COVID Certificate';
        cse5.RecordTypeId = caseRecType;
        cse5.ContactId = testContact.Id;
        cse5.Status = 'Solved';
        cse5.Case_Outcome__c = 'Approved Exemption';
        lstCases.add(cse5);

        // 1x Student Approved
        Case cse2 = new Case();
        cse2.SuppliedEmail = 'testEmail@test.edu';
        cse2.Enquiry_Type__c = 'Vaccinate Monash - Students';
        cse2.Category_Level_1__c = 'COVID-19 Vaccination Proof';
        cse2.Category_Level_2__c = 'COVID Certificate';
        cse2.RecordTypeId = caseRecType;
        cse2.ContactId = testContact.Id;
        cse2.Status = 'Solved';
        cse2.Case_Outcome__c = 'Approved Vaccination Certificate';
        lstCases.add(cse2);

        // 1x Student COVID-19 Fully Vaccinated
        Case cse3 = new Case();
        cse3.SuppliedEmail = 'testEmail@test.edu';
        cse3.Enquiry_Type__c = 'Vaccinate Monash - Students';
        cse3.Category_Level_1__c = 'COVID-19 Vaccination Proof';
        cse3.Category_Level_2__c = 'COVID Certificate';
        cse3.RecordTypeId = caseRecType;
        cse3.ContactId = testContact.Id;
        cse3.Status = 'Solved';
        cse3.Case_Outcome__c = 'COVID-19 Fully Vaccinated';
        lstCases.add(cse3);

        // 1x Student Awaiting
        Case cseAwaiting = new Case();
        cseAwaiting.SuppliedEmail = 'testEmail@test.edu';
        cseAwaiting.Enquiry_Type__c = 'Vaccinate Monash - Students';
        cseAwaiting.Category_Level_1__c = 'COVID-19 Vaccination Proof';
        cseAwaiting.Category_Level_2__c = 'COVID Certificate';
        cseAwaiting.RecordTypeId = caseRecType;
        cseAwaiting.ContactId = testContact.Id;
        cseAwaiting.Status = 'Open';
        lstCases.add(cseAwaiting);

        // 1x Student Boosted
        Case cse4 = new Case();
        cse4.SuppliedEmail = 'testEmail@test.edu';
        cse4.Enquiry_Type__c = 'Vaccinate Monash - Students';
        cse4.Category_Level_1__c = 'COVID-19 Vaccination Proof';
        cse4.Category_Level_2__c = 'COVID Certificate';
        cse4.RecordTypeId = caseRecType;
        cse4.ContactId = testContact.Id;
        cse4.Status = 'Solved';
        cse4.Case_Outcome__c = 'COVID-19 Boosted';
        lstCases.add(cse4);

        insert lstCases;


    }

    private static void setupRestContext(Boolean isV2) {
        RestRequest req = new RestRequest();
        req.requestURI = 'apexrest/VaccinateCases/';
        if(isV2)
            req.requestURI += 'V2';
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void testSMSBotV1() {
        setupRestContext(false);

        // Call service
        VaccinateCases.getCases();

        // Deserialize response
        String respBody = RestContext.response.responseBody.toString();
        Type respType = List<VaccinateCases.VaccinateMonashWrapper>.class;
        List<VaccinateCases.VaccinateMonashWrapper> results =
                (List<VaccinateCases.VaccinateMonashWrapper>)JSON.deserialize(respBody, respType);

        Assert.areEqual(2, results.size());
        VaccinateCases.VaccinateMonashWrapper students = results[0];
        Assert.areEqual(Label.Vaccinate_Monash_Students, students.enquiryType);
        Assert.areEqual(3, students.approved);
        Assert.areEqual(1, students.awaiting);
        Assert.areEqual(4, students.submitted);

        VaccinateCases.VaccinateMonashWrapper staff = results[1];
        Assert.areEqual(Label.Vaccinate_Monash_Staff, staff.enquiryType);
        Assert.areEqual(3, staff.approved);
        Assert.areEqual(0, staff.awaiting);
        Assert.areEqual(3, staff.submitted);
    }

    @IsTest
    static void testSMSBotV2() {
        setupRestContext(true);

        // Call service
        VaccinateCases.getCases();

        // Deserialize response
        String respBody = RestContext.response.responseBody.toString();
        Type respType = List<VaccinateCases.VaccinateMonashV2Wrapper>.class;
        List<VaccinateCases.VaccinateMonashV2Wrapper> results =
                (List<VaccinateCases.VaccinateMonashV2Wrapper>)JSON.deserialize(respBody, respType);

        Assert.areEqual(2, results.size());
        VaccinateCases.VaccinateMonashV2Wrapper students = results[0];
        Assert.areEqual(Label.Vaccinate_Monash_Students, students.enquiryType);
        Assert.areEqual(2, students.twoDosesOrExempt);
        Assert.areEqual(1, students.threeDoses);
        Assert.areEqual(1, students.awaiting);

        VaccinateCases.VaccinateMonashV2Wrapper staff = results[1];
        Assert.areEqual(Label.Vaccinate_Monash_Staff, staff.enquiryType);
        Assert.areEqual(3, staff.twoDosesOrExempt);
        Assert.areEqual(0, staff.threeDoses);
        Assert.areEqual(0, staff.awaiting);
    }

}