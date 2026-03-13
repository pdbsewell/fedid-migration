/**
 * @description       : Test class for Person360
 * @author            : Nick Guia
 * @date              : 12-09-2020
 * @group             : Person 360
 * @last modified on  : 19-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *   10-03-2022     Ibrahim Rumi    - EPBBS-2473 include AccountId to withAffiliation method
 *   05-07-2023     Nick Guia       - Added tests for createContactPointAffiliations() 
 *   11.07.2023     Vinothraja      - SFTG-3396 Modified mute CPA test to 
**/
@istest(isParallel=true)
private class Person360_Test {

    @TestSetup
    static void makeData(){
        
        id accountid = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        //create Contact, Affiliation, Contact Point, Contact Point Affiliation
        Contact con = new Contact(
            FirstName = 'Person360_Test',
            LastName = 'SetupContact'
        );
        Person360.Person360Builder builder = new Person360.Person360Builder(con);   

        //create affiliation               
        builder.withAffiliation(
            accountid,
            'Alumni',
            Date.today());
        builder.buildPhone()
            .withClassification('Private')
            .withPhoneNumber('+61123456789')
            .withType('Mobile')
            .withSource('Contact supplied');
        Person360 p360 = builder.build();
        BaseClass bc = new Person360BuilderDirector().resolveDependencies(p360).getBaseClass();
        Boolean isSuccess = bc.commitRecords();
        System.assert(isSuccess, 'Unable to insert Person360');
    }
    
    /**
     * @description build a new Person360 record creating:
     *  - Contact
     *  - Affiliation
     *  - Contact Point Affiliation
     *  - Contact Points
     */
    @IsTest
    static void shouldCreatePerson360WithNewAffiliation() {
        //given
        Contact con = new Contact(
            FirstName = 'Person360',
            LastName = 'Test'
        );
        Person360 p360;

        Test.startTest();

        //when

        //create a person360 builder instance
        Person360.Person360Builder builder = new Person360.Person360Builder(con);   
        id accountId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        //create affiliation               
        builder.withAffiliation(
            accountId,
            'Prospective_Student',
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

        Test.stopTest();

        //then

        //let Person360Director resolve dependencies and generate a BaseClass instance
        BaseClass bc = new Person360BuilderDirector().resolveDependencies(p360).getBaseClass();

        //commit records
        Boolean isSuccess = bc.commitRecords();
        System.assert(isSuccess, 'Unable to insert Person360');
    }
    
    /**
     * @description test manually assign a new Affiliation
     *  and create a new Phone Contact point for it
     */
    @IsTest
    static void shouldCreatePerson360WithManuallyCreatedAffiliation() {
        //given

        //create Contact
        Contact con = [SELECT Id, FirstName, LastName, AccountId
            FROM Contact 
            WHERE FirstName = 'Person360_Test' 
            AND LastName = 'SetupContact'
            LIMIT 1];
        
        //create Affiliation
        Affiliation__c affRec = new Affiliation__c();
        Id affRecTypeId = Schema.SObjectType.Affiliation__c
                            .getRecordTypeInfosByDeveloperName()
                            .get('Prospective_Student')
                            .getRecordTypeId();
        affRec.RecordTypeId = affRecTypeId;
        affRec.Start_Date__c = Date.today();
        affRec.Contact__c = con.Id;
        affRec.Account__c = con.AccountId;

        Person360 p360;

        Test.startTest();

        //when

        //create a person360 builder instance
        Person360.Person360Builder builder = new Person360.Person360Builder(con)
                                                .withAffiliation(affRec);
        builder.buildPhone()
            .withClassification('Private')
            .withPhoneNumber('+61987654321')
            .withType('Mobile')
            .withSource('Contact supplied');

        p360 = builder.build();

        Test.stopTest();

        //then
        
        //let Person360Director resolve dependencies and generate a BaseClass instance
        BaseClass bc = new Person360BuilderDirector().resolveDependencies(p360).getBaseClass();

        //commit records
        Boolean isSuccess = bc.commitRecords();
        System.assert(isSuccess, 'Unable to insert Person360');
    }

    /**
     * @description test option of switching off CPA creation within the Builder
     */
    @isTest
    static void shouldNotCreateCPARecords() {

        // GIVEN
        Contact con = [SELECT Id, FirstName, LastName, AccountId
            FROM Contact 
            WHERE FirstName = 'Person360_Test' 
            AND LastName = 'SetupContact'
            LIMIT 1];
        Person360.Person360Builder builder;
        Contact_Point_Affiliation__c cpa;
        String mobilePhone = '12345678';

        Test.startTest();

        // WHEN

        // mute CPA creation
        builder = new Person360.Person360Builder(con).createContactPointAffiliations(false);
        builder.buildPhone().withPhoneNumber(mobilePhone);
        Person360 p360 = builder.build();

        Test.stopTest();

        // THEN
        Assert.isFalse(builder.isCreateCPA, 'Unable to mute CPA creation'); // should be false
        Assert.isTrue(p360.getContactPointAffiliationMap().isEmpty(), 'Unable to mute CPA creation'); // should always return null
    }


      /**
     * @description test to verify that Phone CPA is created
     */
    @isTest
    static void shouldCreatePhoneCPARecords() {
          // GIVEN
          Contact con = [SELECT Id, FirstName, LastName, AccountId
          FROM Contact  WHERE FirstName = 'Person360_Test' 
          AND LastName = 'SetupContact' LIMIT 1];
          //Create Phone__c CP
          Phone__c phone1 = new Phone__c();
            phone1 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone1,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => Date.today().addDays(-1),
                Phone__c.CreatedDate => System.now(),
                Phone__c.Type__c => 'Mobile',
                Phone__c.Is_Primary__c => true
            });
            Person360.Person360Builder builder = new Person360.Person360Builder(con);

            //WHEN
            Test.startTest();
            builder = builder.withPhone(phone1);
            Test.stopTest();

            //THEN
            Assert.isTrue(builder.cpaMap.size()==1, 'Unable to create  CPA'); 
            Assert.isTrue(builder.cpaMap.get('Phone__c')!=null, 'Unable to create Phone CPA'); 

        }

   /**
     * @description test to verify that Email__c CPA is created
     */
    @isTest
    static void shouldCreateEmailCPARecords() {
          // GIVEN
          Contact con = [SELECT Id, FirstName, LastName, AccountId
          FROM Contact 
          WHERE FirstName = 'Person360_Test' 
          AND LastName = 'SetupContact'
          LIMIT 1];
          //Create Email__c CP
          Email__c email = new Email__c( // survivor
            Id = fflib_IDGenerator.generate(Email__c.SObjectType), 
            Key_UID__c = 'GreenEmail@gmail.com'
            );
            Person360.Person360Builder builder = new Person360.Person360Builder(con);

            //WHEN
            Test.startTest();
            builder = builder.withEmail(email);
            Test.stopTest();

            //THEN
            Assert.isTrue(builder.cpaMap.size()==1, 'Unable to create  CPA'); 
            Assert.isTrue(builder.cpaMap.get('Email__c')!=null, 'Unable to create Email CPA'); 
    }

    /**
     * @description test to verify that Address CPA is created
     */
    @isTest
    static void shouldCreateAddressCPARecords() {
          // GIVEN
          Contact con = [SELECT Id, FirstName, LastName, AccountId
          FROM Contact 
          WHERE FirstName = 'Person360_Test' 
          AND LastName = 'SetupContact'
          LIMIT 1];
          //Create Address__c CP
          Address__c address = new Address__c();
           address = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Address__c.Start_Date__c => Date.today(),
                Address__c.CreatedDate => System.now(),
                Address__c.Classification__c => 'Monash',
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => true
            });
            Person360.Person360Builder builder = new Person360.Person360Builder(con);
            //WHEN
            Test.startTest();
            builder = builder.withAddress(address);
            Test.stopTest();

            //THEN
            Assert.isTrue(builder.cpaMap.size()==1, 'Unable to create  CPA'); 
            Assert.isTrue(builder.cpaMap.get('Address__c')!=null, 'Unable to create Address CPA'); 

           }
}