/**
* @author Mathew Jose
* @description Apex test class for Opportunity Service class
* @group SF Offers
*
**/
@isTest
public with sharing class OpportunityService_Test {
    @testSetup
    static void setup(){
        Offer_Setting__c setting = new Offer_Setting__c();
        setting.Isca_Template_Id__c = 'ISCA';
        setting.Domestic_Template_Id__c = 'DSCA';
        setting.Monash_Abroad_Template_Id__c = 'MASCA';
        setting.Indonesia_ENG_Template_ID__c	 = 'INDENG';

        insert setting;
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests retrieval the offer template of the opportunity id for deferral opportunities
     * @revision    06/15/2021 - Kristian Vegerano - Created
     */
    @isTest
    public static void testRetrieveOriginalOpportunityTemplateId(){
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);

        Opportunity originalOffer = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id), false);
        originalOffer.Offer_Template__c = 'DSCA';
        insert originalOffer;

        Opportunity deferredOpp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id) ,false);
        deferredOpp.Original_Offer__c = originalOffer.Id;

        Test.startTest();
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.offerLapsedDate = Date.today().addDays(30);
        wrapper.opptyRecord = deferredOpp;

        deferredOpp = OpportunityService.createOffer( JSON.serialize(wrapper) );
        Test.stopTest();

        //one for original, one for deferred
        System.assertEquals(2, [SELECT Id FROM Opportunity WHERE Offer_Template__c = 'DSCA'].size());
    }

    /**
     * @author Kristian Vegerano
     * @date 09/06/2021
     * @description Tests that the offer template field of the opportunity is correctly setup for domestic monash college australia
     */
    @isTest
    public static void createOfferDomesticMonashCollegeAustraliaTest(){
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id) ,false);
        opp.Offer_Template__c = 'Domestic Monash College - Australia';
        
        Test.startTest();
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.offerLapsedDate = Date.today().addDays(30);
        wrapper.opptyRecord = opp;

        opp = OpportunityService.createOffer( JSON.serialize(wrapper) );
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM Opportunity WHERE Offer_Template__c = 'DSCA'].size());
    }

    @isTest
    public static void createOfferDomesticUniAustraliaTest(){
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id) ,false);
        opp.Offer_Template__c = 'Domestic Coursework - Australia';
        
        Test.startTest();
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.offerLapsedDate = Date.today().addDays(30);
        wrapper.opptyRecord = opp;

        opp = OpportunityService.createOffer( JSON.serialize(wrapper) );
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM Opportunity WHERE Signature_Type__c = 'Not Applicable'].size());
    }

    /**
     * @author Kristian Vegerano
     * @date 09/06/2021
     * @description Tests that the offer template field of the opportunity is correctly setup for international coursework australia
     */
    @isTest
    public static void createOfferInternationalCourseworkAustraliaTest(){
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id) ,false);
        opp.Offer_Template__c = 'International Coursework - Australia';

        Test.startTest();
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.offerLapsedDate = Date.today().addDays(30);
        wrapper.opptyRecord = opp;

        opp = OpportunityService.createOffer( JSON.serialize(wrapper) );
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM Opportunity WHERE Offer_Template__c = 'ISCA'].size());
    }
    
    /**
     * @author Kristian Vegerano
     * @date 09/06/2021
     * @description Tests that the offer template field of the opportunity is correctly setup for international coursework monash abroad
     */
    @isTest
    public static void createOfferInternationalCourseworkMonashAbroadTest(){
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id) ,false);
        opp.Offer_Template__c = 'International Coursework - Monash Abroad';

        Test.startTest();
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.offerLapsedDate = Date.today().addDays(30);
        wrapper.opptyRecord = opp;

        opp = OpportunityService.createOffer( JSON.serialize(wrapper) );
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM Opportunity WHERE Offer_Template__c = 'MASCA'].size());
    }

    /**
    * @author Mathew Jose
    * @date 25/10/2019
    * @group SF Offer
    * @description Test method to test generation of a CPQ quote from opportunity using the CPQ API
    **/
    @isTest
    public static void createOfferTest(){
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id) ,false);

        Test.startTest();
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.offerLapsedDate = Date.today().addDays(30);
        wrapper.opptyRecord = opp;

        opp = OpportunityService.createOffer( JSON.serialize(wrapper) );
        Test.stopTest();
    }

    @isTest static void testcreateInternationalOfferOpp(){
        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Name":"ACP-0001", "Course_Title__c": "Hello", "Offer_Response_Date__c" : "2022-01-01", "Course_Start_Date_Updated__c" : "2022-01-01", "Course_Code__c": "F20031", "Course_Product_ID__c": "F20031", "Course_Offering__r": {"attributes": {"type": "Course_Offering__c","url": "/services/data/v49.0/sobjects/Course_Offering__c/a2B4Y0000001GZoUAM"},"Id": "a2B4Y0000001GZoUAM","Start_Date__c": "2020-07-26","End_Date__c": "2022-06-29"},"Application__r": {"attributes": {"type": "Application__c","url": "/services/data/v49.0/sobjects/Application__c/a244Y0000001GRyQAM"},"Id": "a244Y0000001GRyQAM","Campus_Location__c": "Australia","Agent__c": "0014Y000003nfuaQAA","Residency_Status__c": "INTRNTNL"},"Outcome_Status_LOV__r": {"attributes": {"type": "List_of_Values__c","url": "/services/data/v49.0/sobjects/List_of_Values__c/a3m4Y00000002PTQAY"},"Id": "a3m4Y00000002PTQAY","System_Code__c": "OFFER"}}';
        Application_Course_Preference__c acp = (Application_Course_Preference__c) JSON.deserialize(acpString, Application_Course_Preference__c.class);
        Opportunity opp = OpportunityService.createInternationalOfferOpp(new Contact(FirstName = 'Test', LastName = 'Contact', First_Name__c = 'Test Legal', Last_Name__c = 'Contact', AccountId =  null), acp);
        System.assert(opp.Fee_Category__c == 'AU_INT','Internation Offer');
        System.assert(opp.StageName == 'New Offer','New Offer');
        System.assert(opp.Name.containsIgnoreCase('Legal'), 'Oppty Name doesn\'t contain Legal First & Last names');
    }

    @isTest
    public static void testSetOpptyForQuoteGen(){
        Opportunity oppty = new Opportunity();
        OpportunityService.setOpptyForQuoteGen(oppty);
        System.assert(oppty.StageName == 'Processing Offer', 'Opportunity should start processing.');
    }

    @isTest
    public static void testSetOpptyForDeferral(){
        System.assert(OpportunityService.setOpptyForDeferral('0064Y0000029rzLQAQ').Closed_Reason__c == 'Deferred', 'Opportunity should be deferred.');
		System.assert(OpportunityService.setOpptyForDeferral('0064Y0000029rzLQAQ').Closed_Reason_Details__c == 'Student requested deferral', 'Wrong closed Reason details');
    }


    @isTest
    private static void test_calculateVisaDates(){
        Date startDate = Date.newInstance(2019,1,1);
        Date endDate = Date.newInstance(2019,4,30);
        OpportunityService.OverrideDates dates = OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(dates.startDate,startDate.addMonths(-1),'Under 10 months, then start date is one month before');
        System.assertEquals(dates.endDate, endDate.addMonths(1),'Under 10 months, then end date is one month after');

        startDate = Date.newInstance(2019,1,1); 
        endDate = Date.newInstance(2020,4,30);
        dates = OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(dates.startDate,startDate.addMonths(-1),'Over 10 months, then start date is one month before');
        System.assertEquals(dates.endDate, endDate.addMonths(2),'Over 10 months and end in between Jan-Oct, then end date is two months after');

        startDate = Date.newInstance(2019,1,1);
        endDate = Date.newInstance(2020,12,31);
        dates = OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(dates.startDate,startDate.addMonths(-1),'Over 10 months, then start date is one month before');
        System.assertEquals(dates.endDate,  Date.newInstance(2021,3,15),'Over 10 months and end in between Nov-Dec, then end date is 15/3 of next year');
    }

    @isTest 
    static void test_updateOpptyForSpecialistReview(){
        Opportunity oppty = OpportunityService.updateOpptyForSpecialistReview(null);
        System.assert(oppty.StageName == 'Specialist Review');
    }

    @isTest
    static void shouldUpdateVisaDatesCorrectlyWhenDurationIs10MonthsAndFinishingInJan() {
        Date startDate = Date.newInstance(2019,3,1);
        Date endDate = Date.newInstance(2020,1,1);
        OpportunityService.OverrideDates dates = 
            OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(Date.newInstance(2019,2,1), dates.startDate,
            'Expected start Date one month prior to course start date'
        );
        System.assertEquals(Date.newInstance(2020,3,1), dates.endDate,
            'Expected end Date two months after course end date'
        );
    }

    @isTest
    static void shouldUpdateVisaDatesCorrectlyWhenDurationIs10MonthsAndFinishingInFeb() {
        Date startDate = Date.newInstance(2019,4,29);
        Date endDate = Date.newInstance(2020,2,29);
        OpportunityService.OverrideDates dates = 
            OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(Date.newInstance(2019,3,29), dates.startDate,
            'Expected start Date one month prior to course start date'
        );
        System.assertEquals(Date.newInstance(2020,4,29), dates.endDate,
            'Expected end Date two months after course end date'
        );
    }

    @isTest
    static void shouldUpdateVisaDatesCorrectlyWhenDurationIs10MonthsAndFinishingInAugust() {
        Date startDate = Date.newInstance(2019,10,15);
        Date endDate = Date.newInstance(2020,8,15);
        OpportunityService.OverrideDates dates = 
            OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(Date.newInstance(2019,9,15), dates.startDate,
            'Expected start Date one month prior to course start date'
        );
        System.assertEquals(Date.newInstance(2020,10,15), dates.endDate,
            'Expected end Date two months after course end date'
        );
    }

    @isTest
    static void shouldUpdateVisaDatesCorrectlyWhenDurationIs10MonthsAndFinishingInSept() {
        Date startDate = Date.newInstance(2019,11,2);
        Date endDate = Date.newInstance(2020,9,2);
        OpportunityService.OverrideDates dates = 
            OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(Date.newInstance(2019,10,2), dates.startDate,
            'Expected start Date one month prior to course start date'
        );
        System.assertEquals(Date.newInstance(2020,11,2), dates.endDate,
            'Expected end Date two months after course end date'
        );
    }

    @isTest
    static void shouldUpdateVisaDatesCorrectlyWhenDurationIs10MonthsAndFinishingInOct() {
        Date startDate = Date.newInstance(2019,12,1);
        Date endDate = Date.newInstance(2020,10,1);
        OpportunityService.OverrideDates dates = 
            OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(Date.newInstance(2019,11,1), dates.startDate,
            'Expected start Date one month prior to course start date'
        );
        System.assertEquals(Date.newInstance(2020,12,1), dates.endDate,
            'Expected end Date two months after course end date'
        );
    }

    @isTest
    static void shouldUpdateVisaDatesCorrectlyWhenDurationIs10MonthsAndFinishingFinishingInNov() {
        Date startDate = Date.newInstance(2020,1,30);
        Date endDate = Date.newInstance(2020,11,30);
        OpportunityService.OverrideDates dates = 
            OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(Date.newInstance(2019, 12, 30), dates.startDate,
            'Expected start Date one month prior to course start date'
        );
        System.assertEquals(Date.newInstance(2021, 3, 15), dates.endDate,
            'Expected end date to be 15/03 of the year after course end '
        );
    }

    @isTest
    static void shouldUpdateVisaDatesCorrectlyWhenDurationIs10MonthsAndFinishingFinishingInDec() {
        Date startDate = Date.newInstance(2020,2,29);
        Date endDate = Date.newInstance(2020,12,31);
        OpportunityService.OverrideDates dates = 
            OpportunityService.calculateVisaDates(startDate,endDate);
        System.assertEquals(Date.newInstance(2020, 1, 29), dates.startDate,
            'Expected start Date one month prior to course start date'
        );
        System.assertEquals(Date.newInstance(2021, 3, 15), dates.endDate,
            'Expected end date to be 15/03 of the year after course end '
        );
    }

    @isTest static void shouldNotGetOffer(){
        try{
            OpportunityService.getOffer(FakeRecordIdGenerator.generateId(Opportunity.getSObjectType()));
            System.assert(false,
                'Should have failed'
            );
        }catch(Exception e){
            System.assert(true,
                'Opportunity could not be found'
            );
        }
    }
    /**
     * @author  Vinothraja
     * @date    15/09/2021
     * @description Tests whether an opportunity is updated with Deferral reason, when the associated quote is Deferred
     */
    @isTest
    static void testUpdateOpportunityFromQuote() {
        //Account Creation
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);
        //Contact Creation
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(
            AccountId = acc1.Id,
            Email='contact1@email.com',
            Firstname='firstname',
            LastName='lastname'
        ), true);
        //Opportunity Creation
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        //Quote Creation
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c = Test.getStandardPricebookId(), SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c = opp.CloseDate, SBQQ__Primary__c = true),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id), true);  

        Test.startTest();
            QuoteTriggerHandler.lockUserCreation = true;
            
            SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c, 
                                    Product_Status__c, Sub_status_changed_on__c, Contact_Access__c,
                                    SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c,
                                    SBQQ__ExpirationDate__c, In_Technical_Error__c,
                                    SBQQ__EndDate__c, SBQQ__StartDate__c,Template_Type__c,
                                    Offer_Type__c, Expiry_Status__c, Offer_Status_Date__c,
                                    Visa_Start_Date__c, Visa_End_Date__c,
                                    Primary_DocuSign_Envelop_Id__c, Docusign_Expiry_Time__c, OpportunityStage__c, SBQQ__Primary__c
                                    FROM SBQQ__Quote__c];
            
            SBQQ__Quote__c oldQuote = quotes[0];
            
            SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);
            
            QuoteTriggerHandler.QuoteStatusUpdates handler7 = new QuoteTriggerHandler.QuoteStatusUpdates();    
            oldQuote.SBQQ__Status__c = 'Published';
            oldQuote.Sub_Status__c = '';
            //Defer the Quote
            newQuote.SBQQ__Status__c = 'Deferred';
            newQuote.Sub_Status__c = '';  
            
            handler7.process(newQuote,oldQuote);   
            handler7.execute();
        Test.stopTest();         
        // Associated Opportunity should be closed with Deferred reason
        Opportunity updatedOpp = [SELECT id, StageName, Closed_Reason_Details__c 
                                    FROM Opportunity 
                                    WHERE id = : opp.id];
        System.assert(updatedOpp.StageName == 'Canceled/Rejected', 'Quote deferment not updated in Opportunity');
        System.assert(updatedOpp.Closed_Reason_Details__c == 'Student deferred offer', 'Quote deferment not updated in Opportunity');
    }
    /**
     * @author Vinothraja
     * @date 15/09/2021
     * @description Tests whether a closed opportunity is not updated again recursively, when the associated quote is closed
     */
    @isTest
    static void testUpdateOpportunityFromQuote_CancelledOffers() {
        //Account Creation
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);
        //Contact Creation
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(
            AccountId = acc1.Id,
            Email='contact1@email.com',
            Firstname='firstname',
            LastName='lastname'
        ), true);
        //Opportunity Creation - with a Closed Lost Stage
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15), StageName = 'Canceled/Rejected', Closed_Reason__c = 'Cancelled', Closed_Reason_Details__c = 'Other Cancellation Reason'),true);
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        //Quote Creation
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c = Test.getStandardPricebookId(), SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c = opp.CloseDate, SBQQ__Primary__c = true),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id), true);  

        Test.startTest();
            QuoteTriggerHandler.lockUserCreation = true;
            
            SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c, 
                                    Product_Status__c, Sub_status_changed_on__c, Contact_Access__c,
                                    SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c,
                                    SBQQ__ExpirationDate__c, In_Technical_Error__c,
                                    SBQQ__EndDate__c, SBQQ__StartDate__c,Template_Type__c,
                                    Offer_Type__c, Expiry_Status__c, Offer_Status_Date__c,
                                    Visa_Start_Date__c, Visa_End_Date__c,
                                    Primary_DocuSign_Envelop_Id__c, Docusign_Expiry_Time__c, OpportunityStage__c, SBQQ__Primary__c
                                    FROM SBQQ__Quote__c];
            
            SBQQ__Quote__c oldQuote = quotes[0];
            
            SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);
            
            QuoteTriggerHandler.QuoteStatusUpdates handler7 = new QuoteTriggerHandler.QuoteStatusUpdates();    
            oldQuote.SBQQ__Status__c = 'Published';
            oldQuote.Sub_Status__c = '';
            //Defer the Quote
            newQuote.SBQQ__Status__c = 'Deferred';
            newQuote.Sub_Status__c = '';  
            
            handler7.process(newQuote,oldQuote);   
            handler7.execute();
        Test.stopTest();      
        // Associated Opportunity should not be attempted to close, if the Opportunity is already Closed   
        Opportunity updatedOpp = [SELECT id, StageName, Closed_Reason_Details__c 
                                    FROM Opportunity 
                                    WHERE id = : opp.id];
        System.assert(updatedOpp.Closed_Reason_Details__c != 'Student deferred offer', 'Closing a Quote should not update an already closed Oppty');
    }
     /**
     * @author Shalini Mendu
     * @date 02/11/2021
     * @description Tests that the offer template field of the opportunity is correctly setup for indonesia coursework 
     */
    @isTest
    public static void createOfferIndonesia(){
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id) ,false);
        opp.Offer_Template__c = 'Domestic Coursework - Indonesia';
        Test.startTest();
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.offerLapsedDate = Date.today().addDays(30);
        wrapper.opptyRecord = opp;
        opp = OpportunityService.createOffer( JSON.serialize(wrapper) );
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM Opportunity WHERE Template_Type__c='Domestic Coursework Indonesia'].size());
    }

    /**
     * @author Kristian Vegerano
     * @date 14/04/2022
     * @description Tests that the offer template field of the opportunity is correctly setup for avenu offers
     */
    @isTest
    public static void createOfferAvenu(){
        // price book creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);

        // given avenu offer
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = acc.Id, Pricebook2 = pb, PrimaryContact__c = contact.Id) ,false);
        opp.Offer_Template__c = 'Online Coursework - Avenu';

        // when full opportunity and quote is generated
        Test.startTest();
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.offerLapsedDate = Date.today().addDays(30);
        wrapper.opptyRecord = opp;
        opp = OpportunityService.createOffer( JSON.serialize(wrapper) );
        Test.stopTest();

        // then the offer document should have the Online Coursework template
        System.assertEquals(1, [SELECT Id FROM Opportunity WHERE Template_Type__c = 'Online Coursework - Avenu'].size());
    }
}