/*
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for gift creation class
 * note: make keys used in Map<String, Object> params have the correct case
 */


@isTest(isParallel=true)
public class PORTAL_UCIN_GiftCreation_Test {
    @TestSetup
    static void makeData() {
        List<ucinn_ascendv2__Trigger_Handler__c> handlers = new List<ucinn_ascendv2__Trigger_Handler__c>();
        String namespacePrefix = 'ucinn_ascendv2';
        handlers.add(new ucinn_ascendv2__Trigger_Handler__c(Name = 'ascend Review Transaction Handler', ucinn_ascendv2__Is_Active__c = false, ucinn_ascendv2__Is_Asynchronous__c = false,
              ucinn_ascendv2__Class__c = 'ucinn_ascendv2__v2', ucinn_ascendv2__Load_Order__c = 1.00, ucinn_ascendv2__Object__c = new ucinn_ascendv2__Review_Transaction_v2__c().getSObjectType().getDescribe().getName(),
              ucinn_ascendv2__Owned_by_Namespace__c = namespacePrefix, ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete'));
              insert handlers;
              
    }
    //note createInterim should be called by the other functions (but may/may not not hit all the if statements)
    @IsTest
    public static void test_createInterim()
    {
        test.startTest();
        // GIVEN: params used to create interim records
        //Test Data
        Map<String, Object> params = new Map<String, Object>();
        String contact_salutation = 'contact_salutation';
        params.put(contact_salutation, contact_salutation);
        String contact_firstname = 'contact_firstname';
        params.put(contact_firstname, contact_firstname);
        String contact_lastname = 'contact_lastname';
        params.put(contact_lastname, contact_lastname);
        String contact_phone = '123';
        params.put(contact_phone, contact_phone);
        String contact_email = 'contact_email@email.com';
        params.put(contact_email, contact_email);
        String contact_address1 = 'contact_address1';
        params.put(contact_email, contact_email);
        String contact_address2 = 'contact_address2';
        params.put(contact_email, contact_email);
        
        // WHEN: create interim
        //call function
        PORTAL_UCIN_GiftCreation giftCreation = new PORTAL_UCIN_GiftCreation();
        giftCreation.createInterim(params);
        
        // THEN: verify interim was created
        // Assert to see interim got created
        List<ucinn_ascendv2__Interim__c> interimList = [SELECT ID FROM ucinn_ascendv2__Interim__c];
        system.assert(interimList.size() > 0);

        test.stopTest();
    }

    //function around line 215 of class being tested
    @IsTest
    public static void test_rest_of_class()
    {
        test.startTest();
        // params ojbect takes objects lots of objects with Strings describing them
        Map<String, Object> params = new Map<String, Object>();

        // GIVEN: credit card used for donation
        //String credit card number
        params.put('creditCardNumber', '1234 1234 1234 1234');
        params.put('creditCardType', 'VISA');
        //for credit card expiration date, must make sure the card is not expired
        params.put('creditCardExpirationDate', '2199-09-24');
        params.put('paymentChargeId', '123456789');

        String contact_salutation = 'contact_salutation';
        params.put(contact_salutation, contact_salutation);
        String contact_firstname = 'contact_firstname';
        params.put(contact_firstname, contact_firstname);
        String contact_lastname = 'contact_lastname';
        params.put(contact_lastname, contact_lastname);
        String contact_phone = '123';
        params.put('contact_phone', contact_phone);
        String contact_email = 'contact_email@email.com';
        params.put('contact_email', contact_email);
        String contact_address1 = 'contact_address1';
        params.put(contact_email, contact_email);
        String contact_address2 = 'contact_address2';
        params.put(contact_email, contact_email);
        
        // GIVEN: spouse of donor making the donation
        //contact
        Contact spouse = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert spouse;
        
        // GIVEN: donor making the donation
        Contact contact = new Contact(LastName = 'LastName2', FirstName = 'FirstName2', ucinn_ascendv2__Preferred_Spouse__c = spouse.Id);
        params.put('constituentRec', contact);
        insert contact;
        
        //account
        Account account = new Account(Name = 'TestName925');
        insert account;
        params.put('organizationRec', account);
        
        //Opportunity
        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;      
        opp.Name = 'Test Opp'; //Name
        opp.StageName = 'Active'; //StageName
        opp.CloseDate = System.today() + 30; //Close Date
        Opp.Amount = 300;
        Opp.Type = 'Outright';
        Opp.ucinn_ascendv2__Credit_Date__c = System.today();
        //insert opp; //causing issues
        params.put('giftRec', opp);
        
        params.put('externalPaymentGatewayId', 'PRAX-TEST-1234455643');
        
        //Designation detail list
        List<ucinn_ascendv2__Designation_Detail__c> desigDetailList = new List<ucinn_ascendv2__Designation_Detail__c>();
        
        ucinn_ascendv2__Designation_Detail__c desigDetail = new ucinn_ascendv2__Designation_Detail__c();
        desigDetail.ucinn_ascendv2__Amount__c = 300;
        desigDetail.ucinn_ascendv2__Contact__c = contact.Id;

        desigDetailList.add(desigDetail);
        params.put('designationDetailRecList', desigDetailList);
        Map<String, Object> devParams = new Map<String, Object>();

        // WHEN: donation is created
        PORTAL_UCIN_GiftCreation giftCreation = new PORTAL_UCIN_GiftCreation();
        giftCreation.createPortalAnonymousUserGiftTransaction(params, devParams);

        List<ucinn_ascendv2__Review_Transaction_v2__c> createdTransactions = [SELECT ID, ucinn_ascendv2__Payment_Amount_1_1__c FROM ucinn_ascendv2__Review_Transaction_v2__c];

        // THEN: verify that the transaction was created with the correct amount
        // Make sure gift/transactions are created with correct amounts
        System.assertNotEquals(createdTransactions.size(), 0);
        System.assert(createdTransactions[0].ucinn_ascendv2__Payment_Amount_1_1__c == 300);

        params.put('isAnonymousUser', true);
        giftCreation.createPortalAnonymousUserGiftTransaction(params, devParams);
        
        test.stopTest();
    }
}