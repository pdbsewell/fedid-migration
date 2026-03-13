/**
 * @description       : Test class for PaymentSummaryService
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
 * @last modified on  : 2021-04-08
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2022-10-30 - Inderpal Dhanoa - Added test for checking Settlement date
**/
@isTest// (isParallel=true)Insert failed. First exception on row 0; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, SBQQ.OpportunityBefore: execution of BeforeInsert caused by: System.TypeException: Test.getStandardPricebookId()
public class PaymentSummaryService_Test {
    
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         30.Oct.2022
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {

        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id proposalRecordTypeId = recordTypes.get('Gift').getRecordTypeId(); // Proposal record type

        // Account
        Account accnt = (Account)TestDataFactory.createSObject(new Account(Name = 'Test Accnt'), true); 

        // Contact
        Contact cont = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'temp firstName', lastName = 'temp lastName'), true); 

        // Oppty creation
        Opportunity oppty = (Opportunity)TestDataFactory.createSObject(new Opportunity(Name = 'Test Oppty Batch', StageName = 'Identification', CloseDate = date.today().addDays(3), AccountId = accnt.Id //,ucinn_ascendv2__Contact__c = cont.Id
                                                                        , RecordTypeId = proposalRecordTypeId, Amount = 10.00, ucinn_ascendv2__External_Payment_Gateway_ID__c = 'PRAX-081821-082411849'), true);
        
        // Designation
        ucinn_ascendv2__Designation__c designation =  (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation__c(Name = 'Designation Name', ucinn_ascendv2__Program_Code__c = 'GL_Acc', 
                                                             ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack', ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD', Tax_Status_Code__c = 'S1'), true);

         // Designation detail (linked to Oppty)
         ucinn_ascendv2__Designation_Detail__c designationDetail =  (ucinn_ascendv2__Designation_Detail__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation_Detail__c(Name = 'Designation Name', ucinn_ascendv2__Opportunity__c = oppty.Id), true);

        // Payment
        ucinn_ascendv2__Payment__c payment = (ucinn_ascendv2__Payment__c)TestDataFactory.createSObject(new ucinn_ascendv2__Payment__c(Name = 'Payment Name', ucinn_ascendv2__Designation_Detail__c = designationDetail.Id, 
                                            ucinn_ascendv2__Opportunity__c = oppty.Id, Sent_to_SAP__c = false,ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Visa',ucinn_ascendv2__Tender_Type_for_Pledges__c = 'Visa',
                                            ucinn_ascendv2__Payment_Amount__c = 10.00, ucinn_ascendv2__Transaction_ID__c = '6655040243216368003008'), true);
        
        // Review Transaction
        RecordType transactionRecordType_online = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ucinn_ascendv2__Review_Transaction_v2__c' and DeveloperName = 'Online_Donation_Transaction'];
        ucinn_ascendv2__Review_Transaction_v2__c reviewTrnscn = (ucinn_ascendv2__Review_Transaction_v2__c)TestDataFactory.createSObject(new ucinn_ascendv2__Review_Transaction_v2__c(Name = 'Payment Name', RecordTypeId = transactionRecordType_online.Id, 
                                                                ucinn_ascendv2__Contact__c = cont.Id, ucinn_ascendv2__Payment_Amount_1_1__c = 1000,ucinn_ascendv2__Is_Anonymous__c = true, Gift_Comments__c = 'Test',Source__c = 'Contact Supplied',
                                                                ucinn_ascendv2__Transaction_Date__c = Date.today(), ucinn_ascendv2__Designation_External_ID_1__c = designationDetail.Name, ucinn_ascendv2__Transaction_Type__c = 'Gift',
                                                                ucinn_ascendv2__Installment_Frequency_1__c  = 'Irregular', ucinn_ascendv2__Tender_Type_1__c = 'Credit Card', ucinn_ascendv2__Transaction_ID__c = '6655040243216368003009', 
                                                                ucinn_ascendv2__External_System_ID__c = 'PRAX-TEST-1234455643'), true);


    }


    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         30.Oct.2022
     * @description  Tests regarding to capturing the Settlement date
    *******************************************************************************/ 
	@isTest 
    static void testInitiateProcessing() {

        List<ucinn_ascendv2__Payment__c> paymnt = [SELECT Id, Batch_Id__c FROM ucinn_ascendv2__Payment__c WHERE ucinn_ascendv2__Transaction_ID__c = '6655040243216368003008'];
        system.assertEquals(paymnt[0].Batch_Id__c, null);

        List<String> csvRow = new List<String>();
        //csvRow.add('monasherda,PaymentBatchSummary,PaymentBatchDetail,1.10,2022-10-23T13:00:00Z to 2022-10-24T13:00:00Z,,');
        //csvRow.add('RequestID,RequestDate,MerchantID,BatchID,BatchDate,Status,LocalizedRequestDate');
        csvRow.add('6655040243216368003008,2022-10-23T11:44:16Z,monasherda,20342026,2022-10-24T07:11:26Z,BATCHED,2022-10-23T22:44:16+11:00');
        csvRow.add('6655040243216368003009,2022-10-23T11:44:38Z,monasherda,20342026,2022-10-24T07:11:26Z,BATCHED,2022-10-23T22:44:38+11:00');
        csvRow.add('6665254793266190204002,2022-10-23T11:44:39Z,monasherda,20342026,2022-10-24T07:11:26Z,BATCHED,2022-10-23T22:44:39+11:00');

        // given : 

        // when: 

        test.startTest();
        PaymentSummaryService.initiateProcessing(csvRow);
        test.stopTest();

        // then :
        paymnt = [SELECT Id, Batch_Id__c FROM ucinn_ascendv2__Payment__c WHERE ucinn_ascendv2__Transaction_ID__c = '6655040243216368003008'];
        system.assertEquals(paymnt[0].Batch_Id__c, '20342026');

    }

}