/**
 * @author Nick Guia
 * @date 12-09-2020
 * @group Person 360
 * @description Test class for Person360BuilderDirector
 * @revision
 *   10.03.2022  Ibrahim Rumi    - EPBBS-2473 include AccountId to withAffiliation method
 *   23.03.2022  Ibrahim Rumi    - EPBBS-2473 created method resolveContactPointsWithExternalIdTest to test resolveContactPointsWithExternalId
 *   11.07.2023  Vinothraja      - SFTG-3396 Added code block to resolveContactPointsWithExternalIdTest to test multiple contact point affiliation creation
 **/
@istest(isParallel=true)
private class Person360BuilderDirector_Test {

    @TestSetup
    static void makeData(){
          // STEP 1 - Create Agent Onboarding Settings
          insert AgentPortalTestDataBuilder.factory.createAgentOnboardingSettings();

          // STEP 2 - Create a test Agent Portal User
            AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

            Contact con = new AgentPortalTestDataFactory().createApplicantContact();
            con.Personal_email__c = 'testcontact@edu.com';
            con.Mobilephone = '044444444';
            insert con;

            Account acc = [select id from Account where  Status__c = 'Appointed'];

            Application__c app = new AgentPortalTestDataFactory().createApplication(con.id);
            app.Agent__c = acc.id;

            Affiliation__C aff = new AffiliationManageService().createAgencyAccessFromApplication(app);
            insert aff;

            Contact retCon = [select Personal_email__c, Mobilephone from Contact where Email like '%@test.edu'];
            //Create Phone__c CP
            Phone__c testPrimaryPhone =
                new Phone__c(Name = retCon.Mobilephone, Contact__c = retCon.Id,
                Classification__c = 'Private', Type__c = 'Mobile',
                Source__c = 'Undefined',Is_Active__c = true,
                Start_Date__c = Date.today().addYears(-1), End_Date__c = null, Is_Primary__c = TRUE);
            insert testPrimaryPhone;

            //Create Email__C CP
            Email__C em = new Email__c(
            Contact__c = retCon.id,
            Source__c = 'Undefined',Is_Active__c = true,
            Name = retCon.Personal_email__c,
            Classification__c = 'Private',
            Start_Date__c = Date.today().addYears(-1));
        
            insert em;

           //Create Address__c CP
            Address__c addRess = new Address__c();
            addRess.Contact__c = retCon.Id;
            addRess.Start_Date__c = Date.today();
            addRess.Is_Primary__c = true;
            addRess.Is_Active__c = true;
            addRess.Source__c = 'Undefined';
            addRess.Type__c = 'Physical';
            addRess.Classification__c = 'Private';
            addRess.Street_Name__c = '120 Collins Street';
            addRess.City__c = 'Melbourne';
            addRess.State__c = 'Victoria';
            addRess.Post_Code__c = '3000';
            addRess.Country2__c = 'Australia';
            insert addRess;
        
        
    }
    /**
     * @description build a new Person360 record creating the following records
     * and making sure they are all linked together
     *  - Contact
     *  - Affiliation
     *  - Contact Point Affiliation
     *  - Contact Points
     */
    @IsTest
    static void shouldLinkPerson360Objects() {
        //given
        Contact con = new Contact(
            FirstName = 'Person360',
            LastName = 'shouldLinkPerson360Objects'
        );
        String affRecType = 'Prospective_Student';
        Boolean isSuccess = false;
        Person360 p360;
		id accountId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        
        Test.startTest();
        
        //when

        //create a person360 builder instance
        Person360.Person360Builder builder = new Person360.Person360Builder(con);   
        
        //create affiliation               
        builder.withAffiliation(
            accountId,
            affRecType,
            Date.today());
        //create address
        builder.buildAddress()
            .withClassification('Private')
            .withStreetName('123 Collins St')
            .withCity('Melbourne')
            .withPostCode('3000')
            .withType('Mailing')
            .withSource('Contact supplied');
        //create email
        builder.buildEmail()
            .withClassification('Private')
            .withEmailId('Person360@test.org')
            .withSource('Contact supplied');
        //create phone
        builder.buildPhone()
            .withClassification('Private')
            .withPhoneNumber('+61123456789')
            .withType('Mobile')
            .withSource('Contact supplied');
        //create social
        builder.buildSocial()
            .withClassification('Private')
            .withName('Facebook Account')
            .withType('Facebook')
            .withUrl('https://facebook.com/')
            .withSource('Contact supplied');
        //create name
        builder.buildName()
            .withSalutation('Mr')
            .withName('Person 360', 'Test')
            .withSuffix('Jr')
            .withType('Legal')
            .withSource('Contact supplied');
        
        //assemble Person 360 records
        p360 = builder.build();
        isSuccess = new Person360BuilderDirector().resolveDependencies(p360).commitRecords();

        Test.stopTest();

        //then

        System.assert(isSuccess, 'Unable to insert Person360');

        //select the inserted Contact
        con = [SELECT Id 
            FROM Contact 
            WHERE FirstName = 'Person360' 
            AND LastName = 'shouldLinkPerson360Objects' 
            LIMIT 1];
        System.assert(con != null, 'Unable to find Contact created by Builder');

        //check Address
        Address__c addRec = [SELECT Id 
                            FROM Address__c 
                            WHERE Contact__c = :con.Id 
                            LIMIT 1];
        System.assert(addRec != null, 'Unable to find Address record created by Builder');       

        //check email
        Email__c emailRec = [SELECT Id 
                            FROM Email__c 
                            WHERE Contact__c = :con.Id 
                            LIMIT 1];
        System.assert(emailRec != null, 'Unable to find Email record created by Builder');

        //check phone
        Phone__c phonerec = [SELECT Id 
                            FROM Phone__c 
                            WHERE Contact__c = :con.Id 
                            LIMIT 1];
        System.assert(phonerec != null, 'Unable to find Phone record created by Builder');

        //check social
        Social__c socialRec = [SELECT Id 
                            FROM Social__c 
                            WHERE Contact__c = :con.Id 
                            LIMIT 1];
        System.assert(socialRec != null, 'Unable to find Social record created by Builder');

        //check Name
        Name__c nameRec = [SELECT Id 
                            FROM Name__c 
                            WHERE Contact__c = :con.Id 
                            LIMIT 1];
        System.assert(nameRec != null, 'Unable to find Name record created by Builder');

        //check affiliation
        Id recTypeId = Schema.SObjectType.Affiliation__c
                            .getRecordTypeInfosByDeveloperName()
                            .get(affRecType)
                            .getRecordTypeId();
        Affiliation__c affRec = [SELECT Id 
                                FROM Affiliation__c 
                                WHERE Contact__c = :con.Id 
                                AND RecordTypeId = :recTypeId
                                LIMIT 1];
        System.assert(affRec != null, 'Unable to find Affiliation record created by Builder');

        //check contact point
        Contact_Point_Affiliation__c cpRec = [SELECT Id 
                                            FROM Contact_Point_Affiliation__c 
                                            WHERE Contact__c = :con.Id
                                            AND Affiliation__c = :affRec.Id 
                                            LIMIT 1];
        System.assert(cpRec != null, 'Unable to find Contact Point record created by Builder');
    }
    
     /**
     * @description build a new Person360 record creating the following records
     * and making sure they are all linked together with external id
     *  - Contact
     *  - Affiliation
     *  - Contact Point Affiliation
     *  - Contact Points
     */
    @isTest
    static void resolveContactPointsWithExternalIdTest(){
        
        //given
        Contact con = new Contact(
            FirstName = 'Person360',
            LastName = 'shouldLinkPerson360Objects'
        );
        String affRecType = 'Prospective_Student';
        Boolean isSuccess = false;
        Person360 p360;
		id accountId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        
        Test.startTest();
        //when

        //create a person360 builder instance
        Person360.Person360Builder builder = new Person360.Person360Builder(con);   
        
        //create affiliation               
        builder.withAffiliation(
            accountId,
            affRecType,
            Date.today());
        //create address
        builder.buildAddress()
            .withClassification('Private')
            .withStreetName('123 Collins St')
            .withCity('Melbourne')
            .withPostCode('3000')
            .withType('Mailing')
            .withSource('Contact supplied');
        //create email
        builder.buildEmail()
            .withClassification('Private')
            .withEmailId('Person360@test.org')
            .withSource('Contact supplied');
        //create phone - Mobile
        builder.buildPhone()
            .withClassification('Private')
            .withPhoneNumber('+61123456789')
            .withType('Mobile')
            .withSource('Contact supplied');
        //create phone - Landline
        builder.buildPhone()
            .withClassification('Private')
            .withPhoneNumber('+61123456790')
            .withType('Landline')
            .withSource('Contact supplied');
        //create social
        builder.buildSocial()
            .withClassification('Private')
            .withName('Facebook Account')
            .withType('Facebook')
            .withUrl('https://facebook.com/')
            .withSource('Contact supplied');
        //create name
        builder.buildName()
            .withSalutation('Mr')
            .withName('Person 360', 'Test')
            .withSuffix('Jr')
            .withType('Legal')
            .withSource('Contact supplied');
        
        //assemble Person 360 records
        p360 = builder.build();
        BaseClass bc = new Person360BuilderDirector()
            		.resolveContactPointsWithExternalId()
            		.resolveDependencies(p360)
            		.getBaseClass();

        Test.stopTest();
        
        System.assert(bc != null, 'Unable to get baseclass');
    }

      /**
     * @description build a new Person360 record with the preexisting following records
     * and making sure they are all linked together
     *  - Contact
     *  - Affiliation
     *  - Contact Points
     */
    @IsTest
    static void shouldCreateCPAsFromPerson360() {
        Contact con = [select id,AccountId from Contact where Mobilephone = '044444444'];
        //when
        Person360BuilderDirector.Options opt = new Person360BuilderDirector.Options();
        Person360.Person360Builder builder = new Person360.Person360Builder(con);
        opt.commitContact = false;
        opt.commitAffiliation = false;
        opt.commitContactPoints = false;
        opt.useExternalId = false;
        Test.startTest();

        //Create CPAs for Phone/Email/Address
        builder.withAffiliation([select Id from Affiliation__c])
        .withPhone([select Id from Phone__c])
        .withEmail([select Id from Email__c])
        .withAddress([select Id from Address__c]);
        Person360 p360 = builder.build();
        BaseClass bc = new Person360BuilderDirector().resolveDependencies(p360, opt).getBaseClass();
        BaseClass.ResultSet result = bc.commitRecordsPartial();

        Test.stopTest();
        Assert.areEqual(3, [SELECT ID FROM Contact_Point_Affiliation__c]?.size(), ' There should be 3 CPA records created');

    }

       /**
     * @description build a new Person360 record using existing
     *  - Contact
     *  - Affiliation
     *  - Contact Points
     */
    @IsTest
    static void shouldCreateCPAsFromPerson360List() {
        Contact con = [select id,AccountId from Contact where Mobilephone = '044444444'];
        //when
        Person360BuilderDirector.Options opt = new Person360BuilderDirector.Options();
        Person360.Person360Builder builder = new Person360.Person360Builder(con);
        opt.commitContact = false;
        opt.commitAffiliation = false;
        opt.commitContactPoints = false;
        opt.useExternalId = false;
        Test.startTest();
        //Create CPAs for Phone/Email/Address
        builder.withAffiliation([select Id from Affiliation__c])
        .withPhone([select Id from Phone__c])
        .withEmail([select Id from Email__c])
        .withAddress([select Id from Address__c]);
        Person360 p360 = builder.build();
        BaseClass bc = new Person360BuilderDirector().resolveDependencies(new List<Person360>{p360}, opt).getBaseClass();
        BaseClass.ResultSet result = bc.commitRecordsPartial();

        Test.stopTest();
        Assert.areEqual(3, [SELECT ID FROM Contact_Point_Affiliation__c]?.size(), ' There should be 3 CPA records created');

      }
}