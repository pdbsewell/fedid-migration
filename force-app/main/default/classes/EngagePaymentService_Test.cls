/**
 * Payment Service Test class.
 *
 * @author Charlie Park - UC Innovation
 */ 

@isTest(isParallel=false) // Test.getStandardPricebookId called on Opportunity trigger
public class EngagePaymentService_Test {
    @isTest
    public static void testSetAuthorizeAndCharge() {
        RecordType recType = [SELECT Id, Name, Description ,DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Gift'];

        Account acct = new Account();
        acct.Name = 'Account';
        insert acct;

        Contact con = new Contact(LastName = 'Test_Contact',
                          AccountId = acct.Id,
                          Email = 'testCommunityUsermig123@test.com');
        insert con;

        Opportunity opp = new Opportunity();
        opp.Name = 'Gift';
        opp.StageName = 'Funded';
        opp.Amount = 1000;
        opp.CloseDate = Date.today();
        opp.AccountId = acct.Id;
        opp.RecordTypeId = recType.Id;
        insert opp;

        ucinn_ascendv2__Designation__c designation = new ucinn_ascendv2__Designation__c();
        designation.Name = 'Athletics';
        designation.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        designation.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        designation.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        designation.Tax_Status_Code__c = 'S1';
        insert designation;

        ucinn_ascendv2__Designation_Detail__c designDetail = new ucinn_ascendv2__Designation_Detail__c();
        designDetail.ucinn_ascendv2__Opportunity__c = opp.Id;
        insert designDetail;

        ucinn_ascendv2__Payment__c payment = new ucinn_ascendv2__Payment__c();
        payment.ucinn_ascendv2__Credit_Date__c = Date.parse('27/12/2018');
        payment.ucinn_ascendv2__Payment_Amount__c = 1000;
        payment.ucinn_ascendv2__Contact__c = con.Id;
        payment.ucinn_ascendv2__Designation__c = designation.Id;
        payment.ucinn_ascendv2__Designation_Detail__c = designDetail.Id;
        payment.ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Cash';

        test.startTest();
        insert payment;
        test.stopTest();

        ucinn_ascendv2__Payment__c queriedPayment = [SELECT ID,ucinn_ascendv2__Authorize_and_Charge__c FROM ucinn_ascendv2__Payment__c WHERE ID =: payment.Id];
        system.assert(queriedPayment.ucinn_ascendv2__Authorize_and_Charge__c == false);

    }
}