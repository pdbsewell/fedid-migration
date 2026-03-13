/**
 * @author Zachary Soohoo, UC Innovation
 * @date 1/28/20
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test Class for PORTAL_UCIN_Utils
 * note: make keys used in Map<String, Object> params have the correct case
 */


@isTest(isParallel=false) // User DML operations not permitted in Parallel
public class PORTAL_UCIN_Utils_Test {   
	@IsTest
    public static void test_replaceSelectedText() {
        // GIVEN: text string to process
        String textString = '<p>test the selected text [FirstName] here.</p>';
        // WHEN: process text string
        // THEN: verify text has been replaced
        Assert.AreEqual('test the selected text [FirstName] here.', PORTAL_UCIN_Utils.replaceSelectedText(textString));
    }
    
    @IsTest
    public static void test_ascendCompatibilityQueryParser() {
        // GIVEN: text string to process
        String textString = 'Anything';
        // WHEN: process text string
        // THEN: verify text is blank
        Assert.AreEqual('', PORTAL_UCIN_Utils.ascendCompatibilityQueryParser(textString));
    }
    
    @IsTest
    public static void test_namespaceprefixes() {
        // GIVEN: text strings to process
        String underscoredNamespacePrefix = PORTAL_UCIN_Utils.namespacePrefixWithDoubleUnderscoresOrEmpty;
        // WHEN: process text strings
        // THEN: verify text is blank
        Assert.AreEqual('', underscoredNamespacePrefix);
    }
    
    @IsTest
    public static void test_getBaseURL() {
        // WHEN: get base url
        // THEN: base url is blank
        Assert.AreNotEqual('', PORTAL_UCIN_Utils.getBaseURL());
    }

        
    @IsTest
    public static void test_oneLineDonationParseParams() {
        test.startTest();
        
        Map<String, Object> params = new Map<String, Object>();
        
        String isAnonymousUser = 'isAnonymousUser';
        Boolean anon = true;
        params.put(isAnonymousUser, anon);
        
        // GIVEN: credit card used for donation
        //TRY PUTTING IN THE SAME PARAMS AS YOU DID FOR THE CLASS PORTAL_UCIN_GiftCreation
        params.put('creditCardNumber', '1234 1234 1234 1234');
        params.put('creditCardType', 'VISA');
        //for credit card expiration date, must make sure the card is not expired (having trouble converting date to string)
        params.put('creditCardExpirationDate', '2199-09-24');
        params.put('paymentChargeId', '123456789');
        
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
        params.put('giftRec', opp);
        
        //Designation detail list
        List<ucinn_ascendv2__Designation_Detail__c> desigDetailList = new List<ucinn_ascendv2__Designation_Detail__c>();
        
        ucinn_ascendv2__Designation_Detail__c desigDetail = new ucinn_ascendv2__Designation_Detail__c();
        desigDetail.ucinn_ascendv2__Amount__c = 300;
        desigDetail.ucinn_ascendv2__Contact__c = contact.Id;

		desigDetailList.add(desigDetail);
		params.put('designationDetailRecList', desigDetailList);
        params.put('externalPaymentGatewayId', 'PRAX-TEST-1234455643'); // make sure param uses same case in PORTAL_UCIN_DonationController
        
        // WHEN: donation is created
        PORTAL_UCIN_DonationController.createNewOnlineDonation(params);

        List<ucinn_ascendv2__Review_Transaction_v2__c> createdTransactions = [SELECT ID, ucinn_ascendv2__Payment_Amount_1_1__c FROM ucinn_ascendv2__Review_Transaction_v2__c];
        String receiptURL = Portal_UCIN_Utils.getReviewTransactionReceiptURL(createdTransactions[0].Id);            
        PORTAL_UCIN_DonationController.createGiftReceipt(createdTransactions[0].Id, '', 'test@test.com', receiptURL, null);

        PORTAL_UCIN_Utils.createGiftReceiptFile(createdTransactions[0].Id, '', receiptURL, null);
        test.stopTest();

        // THEN: verify that the transaction was created with the correct amount
        // Make sure gift/transactions are created with correct amounts
        Assert.AreNotEqual(createdTransactions.size(), 0);
        Assert.IsTrue(createdTransactions[0].ucinn_ascendv2__Payment_Amount_1_1__c == 300);
    }
}