//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User
@IsTest(IsParallel=false)
public class appAddQualificationCC_Test {

    /* 
    * Data setup
    */
	@TestSetup static void setup() {
        // create test partner accounts
        Id partnerAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        List<Account> l_partnerAccounts = new List<Account>();
        l_partnerAccounts.add(new Account(Name = 'Searchable Partner University',
                                          RecordTypeId = partnerAccountRecordTypeId));
        l_partnerAccounts.add(new Account(Name = 'Unsearchable Partnertest University',
                                          RecordTypeId = partnerAccountRecordTypeId));
        insert l_partnerAccounts;
        //Insert test countries
        List<Country_Attribute__c> countriesList = new List<Country_Attribute__c>();
        Country_Attribute__c china = new Country_Attribute__c(Name = 'China (Excl Sars And Taiwan Prov)',
                                                                Callista_country__c = 'China (Excludes SARs And Taiwan Province)',
                                                                Country__c = 'China');
        countriesList.add(china);
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                    Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                    Country__c = 'Australia');
        countriesList.add(australia);   
        insert countriesList;
    }

    static Contact createContact()
    {
        Contact c = new Contact();
        c.FirstName = 'Tester';
        c.LastName = 'Surname';
        insert c;
        return c;
    }

    static Contact_Qualification__c createContactQualification()
    {
        List<RecordType> recTypes = [SELECT Id, Name, SobjectType
        FROM        RecordType
        WHERE       SobjectType = 'Contact_Qualification__c'
        AND Name = 'Secondary Education'
        ORDER BY    Name DESC];

        RecordType rt = recTypes[0];

        Contact_Qualification__c cq = new Contact_Qualification__c();
        cq.RecordTypeId = rt.Id;
        return cq;
    }


    @IsTest
    public static void test_getQualificationRecordTypeOptions()
    {
        List<Map<String,String>> listResults = appAddQualificationCC.getQualificationRecordTypeOptions();

        List<RecordType> listExpected = [SELECT Id, Name, SobjectType
        FROM        RecordType
        WHERE       SobjectType = 'Contact_Qualification__c'
        ORDER BY    Name DESC];

        Assert.areEqual(listResults.size(), listExpected.size());
    }

    @IsTest
    public static void test_getCountryOptions()
    {
        List<Map<String,String>> listResults = appAddQualificationCC.getCountryOptions();

        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        Assert.areEqual(listResults.size(), ple.size(), 'Country Options returned');
    }

    @IsTest
    public static void test_getCountryAttributes()
    {
        // get a test country
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry testCountry = ple[0];

        // insert a test record
        Country_Attribute__c countryAttr = new Country_Attribute__c();
        countryAttr.Country__c = testCountry.getValue();
        countryAttr.Callista_Country__c = testCountry.getValue();
        insert countryAttr;

        // test method
        List<Map<String,String>> listResults = appAddQualificationCC.getCountryAttributes();

        // expected result
        List<Country_Attribute__c> listExpected = [SELECT Id, Country__c
        FROM Country_Attribute__c
        WHERE       Country__c != NULL and (NOT callista_country__C LIKE '% %')];

        Assert.areEqual(listResults.size(), listExpected.size(), 'Country Attributes returned');
    }

    @IsTest
    public static void test_getAusStateOptions()
    {
        List<Map<String,String>> listResults = appAddQualificationCC.getAusStateOptions();

        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.State__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        Assert.areEqual(listResults.size(), ple.size());
    }

    @IsTest
    public static void test_getCompletionStatusOptions()
    {
        List<Map<String,String>> listResults = appAddQualificationCC.getCompletionStatusOptions();

        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        Assert.areEqual(listResults.size(), ple.size());
    }

    @IsTest
    public static void test_getAdmissionTestOptions()
    {
        String admissionTestRecTypeId = [SELECT Id, Name, sObjectType
        FROM RecordType
        WHERE DeveloperName = 'Admission_Test'].Id;

        // create a qualification
        Qualification__c testQual = StudFirst_TestHelper.createQualification('testQual');
        testQual.RecordTypeId = admissionTestRecTypeId;
        testQual.Available_on_Portal__c = true;
        insert testQual;
        
        List<Qualification__c> listExpected = [SELECT Qualification_Name__c
        FROM Qualification__c
        WHERE RecordTypeId =: admissionTestRecTypeId
        AND Available_on_Portal__c = true
        ORDER BY    Qualification_Name__c ];
	
        Test.startTest();
        
        List<Map<String,String>> listResults = appAddQualificationCC.getAdmissionTestOptions();
        Assert.areEqual(listResults.size(), listExpected.size());
        Test.stopTest();
    }

    @IsTest
    public static void test_noUserAccess()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = new Contact();
        c.FirstName = 'Someone';
        c.LastName = 'Else';
        insert c;

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;
        Test.startTest();
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = appAddQualificationCC.getCurrentUserAndQualifications(app.Id);
            Boolean access = (Boolean) mapResults.get(appAddQualificationCC.FIELD_ACCESS_ALLOWED);
            Assert.areEqual(false, access);
        }
        Test.stopTest();
    }

    @IsTest
    public static void test_getCurrentUserAndQualificationsNoAppId()
    {
        Test.startTest();
        Map<String, Object> mapResults = appAddQualificationCC.getCurrentUserAndQualifications(null);
        Assert.areEqual(null, mapResults, 'GetCurrentUserAndQuals:: Null Id');
        Test.stopTest();
    }
    
    /**
     * @author      ???
     * @description Tests initializing app add qualification component on my.app
     * @revision    07/04/2022 - Kristian Vegerano - Update - asserts partner account search
     */
    @IsTest
    public static void test_getCurrentUserAndQualifications(){
        // create community user 
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;
        // create a contact-qualification that is "historical"
        Contact_Qualification__c cqOld = createContactQualification();
        cqOld.Contact__c = applicant.ContactId;
        insert cqOld;

        // add an institution
        Institution__c testSchool = new Institution__c();
        testSchool.Institution_Code__c = 'TEST0001';
        testSchool.Institution_Name__c= 'TEST ACADEMY';
        insert testSchool;

        // create a contact-qualification that is "draft"
        Contact_Qualification__c cqDraft = createContactQualification();
        cqDraft.Contact__c = applicant.ContactId;
        cqDraft.Institution_Code__c = testSchool.Institution_Code__c;
        cqDraft.Institution_Name__c = testSchool.Institution_Name__c;
        insert cqDraft;

        // create the apq
        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
        aqp.Contact_Qualification__c = cqDraft.Id;
        aqp.Application__c = app.Id;
        insert aqp;

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = appAddQualificationCC.getCurrentUserAndQualifications(app.Id);
    
            List<Institution__c> listInstitutions= (List<Institution__c>)mapResults.get(appAddQualificationCC.FIELD_DRAFT_INSTITUTIONS);
            Assert.areEqual(listInstitutions.size(), 1, 'Draft Institutions');
    
            List<Contact_Qualification__c> draftQualifications = (List<Contact_Qualification__c>) mapResults.get(appAddQualificationCC.FIELD_DRAFT_QUALIFICATIONS);
            Assert.areEqual(draftQualifications.size(),1, 'Draft Qualifications');
    
            List<Contact_Qualification__c> historicalQualifications = (List<Contact_Qualification__c>) mapResults.get(appAddQualificationCC.FIELD_HISTORICAL_QUALIFICATIONS);
            Assert.areEqual(historicalQualifications.size(),1, 'Historical Qualifications');

            // checks the number of partner account included on the search
            Assert.areEqual(2, (new List<String>((Set<String>)mapResults.get('PARTNER_ACCOUNTS'))).size(), 'Partner Accounts'); // one partner account included one partner account excluded because of the test keyword
        }
        Test.stopTest();
    }


    @IsTest
    public static void test_getQualificationsByApplicationAndContact()
    {
        // create contact
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        // create a contact-qualification that is "historical"
        Contact_Qualification__c cqOld = new Contact_Qualification__c();
        cqOld.Contact__c = c.Id;
        insert cqOld;


        // add an institution
        Institution__c testSchool = new Institution__c();
        testSchool.Institution_Code__c = 'TEST0001';
        testSchool.Institution_Name__c= 'TEST ACADEMY';
        insert testSchool;

        // create a contact-qualification that is "draft"
        Contact_Qualification__c cqDraft = new Contact_Qualification__c();
        cqDraft.Contact__c = c.Id;
        cqDraft.Institution_Code__c = testSchool.Institution_Code__c;
        cqDraft.Institution_Name__c = testSchool.Institution_Name__c;
        insert cqDraft;


        // create the apq
        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
        aqp.Contact_Qualification__c = cqDraft.Id;
        aqp.Application__c = app.Id;
        insert aqp;


        Map<String, Object> mapResults = appAddQualificationCC.getQualificationsByApplicationAndContact(app.Id, c.Id);

        List<Institution__c> listInstitutions= (List<Institution__c>)mapResults.get(appAddQualificationCC.FIELD_DRAFT_INSTITUTIONS);
        Assert.areEqual(listInstitutions.size(), 1, 'Draft Institutions should be 1');

        List<Contact_Qualification__c> draftQualifications = (List<Contact_Qualification__c>) mapResults.get(appAddQualificationCC.FIELD_DRAFT_QUALIFICATIONS);
        Assert.areEqual(draftQualifications.size(),1, 'Draft Qualifications should be 1');

        List<Contact_Qualification__c> historicalQualifications = (List<Contact_Qualification__c>) mapResults.get(appAddQualificationCC.FIELD_HISTORICAL_QUALIFICATIONS);
        Assert.areEqual(historicalQualifications.size(),1, 'Historical Qualifications should be 1');
    }



    @IsTest
    public static void test_updateQualificationToContact()
    {        
        // create community user 
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        // create a contact-qualification
        Contact_Qualification__c cq = createContactQualification();
        cq.Contact__c = c.Id;
        insert cq;

        // create the apq
        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
        aqp.Contact_Qualification__c = cq.Id;
        aqp.Application__c = app.Id;
        insert aqp;

        String sInstitute = 'Other Test Academy';
        cq.Other_Institution__c = sInstitute;

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String,Object> mapResults = appAddQualificationCC.upsertQualificationToContact(c.Id, app.Id, cq);
    
            Contact_Qualification__c cqUpdated = [SELECT Id, Other_Institution__c FROM Contact_Qualification__c WHERE id =: cq.Id];
            Assert.areEqual(cqUpdated.Other_Institution__c, sInstitute);
        }
        Test.stopTest();
    }

    @IsTest
    public static void test_updateQualificationToContactNoAccess()
    {        
        // create community user 
        User applicant = StudFirst_TestHelper.createCommunityUser();           
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        
        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        // create a contact-qualification
        Contact_Qualification__c cq = createContactQualification();
        cq.Contact__c = c.Id;
        insert cq;

        // create the apq
        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
        aqp.Contact_Qualification__c = cq.Id;
        aqp.Application__c = app.Id;
        insert aqp;

        String sInstitute = 'Other Test Academy';
        cq.Other_Institution__c = sInstitute;

        Test.startTest();        
        Map<String,Object> mapResults = appAddQualificationCC.upsertQualificationToContact(c.Id, app.Id, cq);
        Assert.isTrue(mapResults != null, 'Result should not be null');

        Contact_Qualification__c cqUpdated = [SELECT Id, Other_Institution__c FROM Contact_Qualification__c WHERE id =: cq.Id];
        Assert.areEqual(cqUpdated.Other_Institution__c, sInstitute);
        
        Test.stopTest();
    }



    @IsTest
    public static void test_insertQualificationToContact()
    {
        // create contact
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        // create a contact-qualification
        Contact_Qualification__c cq = createContactQualification();
        cq.Contact__c = c.Id;

        Map<String,Object> mapResults = appAddQualificationCC.upsertQualificationToContact(c.Id, app.Id, cq);
        Assert.isTrue(mapResults != null, 'Result should not be null');

        List<Application_Qualification_Provided__c> aqpResult = [SELECT Id FROM Application_Qualification_Provided__c
        WHERE Application__c =: app.Id AND Contact_Qualification__c =: cq.Id];
        Assert.areEqual(1, aqpResult.size());
    }

    @IsTest
    public static void test_deleteContactAndAppQualification()
    {
        // create community user 
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        // create a contact-qualification
        Contact_Qualification__c cq = createContactQualification();
        cq.Contact__c = c.Id;
        insert cq;

        // create the apq
        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
        aqp.Contact_Qualification__c = cq.Id;
        aqp.Application__c = app.Id;
        insert aqp;

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String,Object> mapResults = appAddQualificationCC.deleteContactAndAppQualification(cq.Id, app.Id);
            Assert.isTrue(mapResults != null, 'Result should not be null');
    
            List<Contact_Qualification__c> cqResult = [SELECT Id FROM Contact_Qualification__c WHERE id =:cq.Id];
            Assert.areEqual(0, cqResult.size());
    
            List<Application_Qualification_Provided__c> aqpResult = [SELECT Id FROM Application_Qualification_Provided__c
            WHERE Application__c =: app.Id AND Contact_Qualification__c =: cq.Id];
            Assert.areEqual(0, aqpResult.size());
        }
        Test.stopTest();
    }

    @IsTest
    public static void test_deleteContactAndAppQualificationNoAccess()
    {
        // create community user 
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        // create a contact-qualification
        Contact_Qualification__c cq = new Contact_Qualification__c();
        cq.Contact__c = c.Id;
        insert cq;

        // create the apq
        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
        aqp.Contact_Qualification__c = cq.Id;
        aqp.Application__c = app.Id;
        insert aqp;

        Map<String,Object> mapResults = appAddQualificationCC.deleteContactAndAppQualification(cq.Id, app.Id);
        Assert.isTrue(mapResults != null, 'Result should not be null');

        List<Contact_Qualification__c> cqResult = [SELECT Id FROM Contact_Qualification__c WHERE id =:cq.Id];        

        List<Application_Qualification_Provided__c> aqpResult = [SELECT Id FROM Application_Qualification_Provided__c
        WHERE Application__c =: app.Id AND Contact_Qualification__c =: cq.Id];
        
        // should NOT be deleted due to incorrect access
        Assert.areEqual(1, cqResult.size());
        Assert.areEqual(1, aqpResult.size());
    }

    @IsTest
    public static void test_saveCreditIntention()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Credit_Intention__c = true;
        insert app;

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String,Object> mapResults = appAddQualificationCC.saveCreditIntention(app.Id, false);    
            Application__c appResult = (Application__c) mapResults.get(appAddQualificationCC.FIELD_APPLICATION);
            Assert.areEqual(false, appResult.Credit_Intention__c, 'Credit intention should be false');
        }
        Test.stopTest();       
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests associate the application to the partner account
     * @revision    03/02/2021 - Kristian Vegerano - Created
     */
    @IsTest
    public static void testAssociateApplicationToPartnerManual() {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Credit_Intention__c = true;
        insert app;

        //Start test
        Test.startTest();

        appAddQualificationCC.associateApplicationToPartner(app.Id, null, 'TestAccount');

        Test.stopTest();

        Assert.areEqual([SELECT Id FROM Account WHERE Name = 'TestAccount'].Id, [SELECT Id, Agent__c FROM Application__c WHERE Id = :app.Id].Agent__c);
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests remove the partner/agent account from the application
     * @revision    03/02/2021 - Kristian Vegerano - Created
     */
    @IsTest
    public static void testRemovePartnerOnApplication() {
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Account testAccount = new Account(Name = 'TestAccount', RecordTypeId = partnerRecordTypeId);
        insert testAccount;

        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Agent__c = testAccount.Id;
        app.Credit_Intention__c = true;
        insert app;

        //Start test
        Test.startTest();

        appAddQualificationCC.removePartnerOnApplication(app.Id);

        Test.stopTest();

        Assert.areEqual(null, [SELECT Id, Agent__c FROM Application__c WHERE Id = :app.Id].Agent__c);
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests updateApplication - which updates the serialized application parameter
     * @revision    19/01/2022 - Kristian Vegerano - Created
     */
    @IsTest
    public static void testUpdateApplication() {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        // create serialized application parameter
        app.English_Language_Proficiency__c = 'Yes';
        String frontEndApplication = JSON.serialize(app);

        // start test
        Test.startTest();

            appAddQualificationCC.updateApplication(frontEndApplication);

        Test.stopTest();

        // check results
        Assert.areEqual('Yes', [SELECT Id, Agent__c, English_Language_Proficiency__c FROM Application__c WHERE Id = :app.Id].English_Language_Proficiency__c);
    }


     /**
     * @author     SMen
     * @description Tests getCountryNameById -  retrieves the country name in format by ID
     */
    @IsTest
    public static void testGetCountryNameById() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.ContactId];
        // GIVEN : There is a country record for China
        Country_Attribute__c ca = [select id from Country_Attribute__c where Callista_Country__c = 'China (Excludes SARs And Taiwan Province)'];
        String countryName;
        // start test
        Test.startTest();
            //WHEN : A community user tries to retrieve ISO format Country name providing the Id
            System.runAs(applicant){ 
                countryName =  appAddQualificationCC.getCountryNameById(ca.Id, CountryServices.FORMAT_ISO);
            }

        Test.stopTest();
        //THEN : The ISO countryName value must be retrieved
        Assert.isTrue(countryName.equalsIgnoreCase('China'), 'It did not retrieve the correct value');
    }

    @IsTest
    public static void testGetEnglishProficiencyPicklistValues() {
        // Act: Call the method under test
        List<Map<String, String>> result;
        Test.startTest();
        result = appAddQualificationCC.getEnglishProficiencyPicklistValues();
        Test.stopTest();

        // Assert: Validate the output
        Assert.isTrue(result != null, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Picklist should have at least one active value returned.');
    }

    @IsTest
    static void testGetRecordTypeIdForEnglishTest() {
        // Retrieve expected RecordTypeId
        Id expectedRecordTypeId = Schema.SObjectType.Contact_Qualification__c
                .getRecordTypeInfosByDeveloperName()
                .get('English_Test')
                ?.getRecordTypeId();

        // Validate existence of the RecordType
        Assert.areNotEqual(null, expectedRecordTypeId, 'Record Type "English_Test" does not exist.');

        // Call the method under test
        Id result = appAddQualificationCC.getRecordTypeIdForEnglishTest();

        // Assert the result matches the expected RecordTypeId
        Assert.areEqual(expectedRecordTypeId, result, 'The RecordTypeId fetched is incorrect.');
    }

    @IsTest
    static void testGetLanguageOfInstruction() {
        // Create test data
        Qualification__c qualification = new Qualification__c(Qualification_Name__c = 'Test Language of Instruction', Callista_Code__c='LOI');
        insert qualification;

        // Call the method under test
        Id result = appAddQualificationCC.getLanguageOfInstruction();

        // Assert the result
        Assert.areEqual(qualification.Id, result, 'The method did not return the correct Qualification Id.');
    }


}