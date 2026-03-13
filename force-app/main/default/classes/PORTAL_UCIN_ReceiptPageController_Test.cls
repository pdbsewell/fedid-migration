/**
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test Class for receipt page controller
 * @revision
 * Date         Author              Modification
 * 24/03/2022   ken mcguire         fixed build error custom validaiton on contact (required field email)
 * 18/07/2022   Chaldrin Cruz       Replaced rt with rtv2
 */
@isTest(isParallel=false) // Test.getStandardPricebookId called on Opportunity trigger
public class PORTAL_UCIN_ReceiptPageController_Test {

    // Create test data
    @testSetup
    public static void setup_base_test_data()
    {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // given: donor
        //MAY NEED TO ADD MORE FIELDS TO THE OBJECTS BELOW TO FIX THE TRIGGER FLOW PROBLEM **************************************
        // Create Constituents
        Contact con1 = (Contact)TestDataFactory.createSObject(new Contact(
            Firstname = 'Contact',
            Lastname = guid,
            email ='test@test.com',
            ucinn_ascendv2__Preferred_Address_Line_1__c = '1182 Warner St',
            ucinn_ascendv2__Preferred_Address_City__c = 'Chico',
            ucinn_ascendv2__Preferred_Address_State__c = 'CA',
            ucinn_ascendv2__Preferred_Address_Postal_Code__c = '95926'), true);
        
        // given: appeal used for gift
        // Create Appeal Codes
        Campaign cmp = (Campaign)TestDataFactory.createSObject(new Campaign(
            Name = 'A-'+guid,
            IsActive = true,
            Status = 'Planned',
            ucinn_ascendv2__Motivation_Code__c = 'A-'+guid), true);
        
        // given: designation ised for gift
        // Create Designations
        ucinn_ascendv2__Designation__c des1 = (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation__c(
        Name = 'D-'+guid+'1',
        ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1',
        ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1),
        ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1),
        ucinn_ascendv2__Program_Code__c = 'GL_Acc', // 7 char
        ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack', // 6 char
        ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD', // 6 char
        Tax_Status_Code__c = 'S1'), true);
        
        // given: review transaction used to create gift
        ucinn_ascendv2__Review_Transaction_v2__c rt = (ucinn_ascendv2__Review_Transaction_v2__c)TestDataFactory.createSObject(new ucinn_ascendv2__Review_Transaction_v2__c (
            RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Review_Transaction_v2__c.getRecordTypeInfosByDeveloperName().get('Online_Donation_Transaction').getRecordTypeId(),
            ucinn_ascendv2__Contact__c = con1.Id,
            ucinn_ascendv2__Payment_Amount_1_1__c = 1000,
            ucinn_ascendv2__Payment_Date_1_1__c = Date.today(),
            ucinn_ascendv2__Is_Anonymous__c = true,
            Gift_Comments__c = 'Test',
            Source__c = 'Contact Supplied',
            ucinn_ascendv2__Designation_1__c = des1.Id,
            ucinn_ascendv2__Transaction_Type__c = 'Gift',
            ucinn_ascendv2__Opportunity_Type__c = 'Outright',
            ucinn_ascendv2__Transaction_Date__c = Date.today(),
            ucinn_ascendv2__Tender_Type_1__c = 'Credit Card',
            ucinn_ascendv2__Campaign__c = cmp.Id,
            ucinn_ascendv2__External_System_ID__c = 'PRAX-12345'), true);
    }
    
    // Testing no year, payment group id scenario
    @IsTest
    public static void noYearAndMisc()
    {
        
        test.startTest();
		// Set up page reference
		// given : when a Review transaction occurs
        PageReference pageRef = Page.PORTAL_UCIN_ReceiptPage;
		Test.setCurrentPage(pageRef);

		// when : the constructor is fired
        ucinn_ascendv2__Review_Transaction_v2__c thisRT = [SELECT ID FROM ucinn_ascendv2__Review_Transaction_v2__c LIMIT 1];
        //Constructor is being tested
        ApexPages.currentPage().getParameters().put('reviewTransactionId', thisRT.Id);
        PORTAL_UCIN_ReceiptPageController rpc = new PORTAL_UCIN_ReceiptPageController();
        List<ucinn_ascendv2__Payment__c> payments = [SELECT ID, ucinn_ascendv2__Designation__r.ucinn_ascendv2__Designation_Name__c, ucinn_ascendv2__Payment_Amount__c, ucinn_ascendv2__Credit_Date__c FROM ucinn_ascendv2__Payment__c];
        // then: verify receipt was generated
        contact con1 = [SELECT firstName, lastName, name, ucinn_ascendv2__Preferred_Address_City__c, ucinn_ascendv2__Preferred_Address_Line_1__c FROM Contact WHERE ucinn_ascendv2__Preferred_Address_Postal_Code__c = '95926' AND ucinn_ascendv2__Preferred_Address_Line_1__c = '1182 Warner St'];
		test.stopTest();
		// then : the constituent wrapper is linked
        system.assertEquals(rpc.constituentWrapper.name, con1.name); 
    }
    
    //Test with payment group Id
    @IsTest
    public static void withPaymentGroupId()
    {
        ucinn_ascendv2__Payment__c thisPayment = [SELECT ID, ucinn_ascendv2__Payment_Group_ID__c FROM ucinn_ascendv2__Payment__c LIMIT 1];

		// given : when a payment group occurs
        ucinn_ascendv2__Review_Transaction_v2__c thisRT = [SELECT ID  FROM ucinn_ascendv2__Review_Transaction_v2__c LIMIT 1];

        test.startTest();
		// when : the constructor is fired
        ApexPages.currentPage().getParameters().put('reviewTransactionId', thisRT.Id); 
        ApexPages.currentPage().getParameters().put('paymentGroupId', 'tempId');
        //Constructor is being tested
        PORTAL_UCIN_ReceiptPageController rpc = new PORTAL_UCIN_ReceiptPageController();

        List<ucinn_ascendv2__Payment__c> payments = [SELECT ID, ucinn_ascendv2__Designation__r.ucinn_ascendv2__Designation_Name__c, ucinn_ascendv2__Payment_Amount__c, ucinn_ascendv2__Credit_Date__c FROM ucinn_ascendv2__Payment__c];

        test.stopTest();
		// then : there are no payment records linked 
		system.assertequals(rpc.receiptPaymentWrapperList.size(), 0); 

    }
}