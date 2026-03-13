/**
 * @description       : Test class for ascend_GIFT_RecurringGiftOverride
 * @author            : UC Innovation
 * @date              : 2023-03-08
 * @group             : Test
 * @group             : Engage
 * @last modified on  : 2023-03-08
 * @last modified by  : UC Innovation
**/
@isTest
public class ascend_GIFT_RecurringGiftOverride_Test {
    
    /*******************************************************************************
     * @author       UC Innovation
     * @date         06.Mar.2023
     * @description  Tests adjustRecurringGift for the Gift termination
    *******************************************************************************/
    @isTest
    public static void adjustRecurringGift_Test() {
        Map<String, Object> paramMap = new Map<String, Object>();
        
        Contact cont = (Contact)TestDataFactory.createSObject(new Contact(Salutation = 'Mr',FirstName = 'First',LastName = 'Last',MobilePhone = '111-111-1111',Email = 'test@test.com',ucinn_ascendv2__Contact_Type__c = 'Other',ucinn_ascendv2__Payroll_ID__c = '123'), true);

        Campaign camp = (Campaign)TestDataFactory.createSObject(new Campaign(Name = '-',StartDate = Date.today(),ucinn_ascendv2__Motivation_Code__c = 'Campaign001'), true);
        
        ucinn_ascendv2__Designation__c designation = (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation__c(ucinn_ascendv2__Designation_Name__c = 'Test Designation',ucinn_ascendv2__External_System_ID__c = 'Designation001',ucinn_ascendv2__Acknowledgement_Description__c = 'Designation001',ucinn_ascendv2__Program_Code__c = 'GL_Acc',ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack',ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD',Tax_Status_Code__c = 'S1'), true);
        
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(Name = 'G123',Type = 'Recurring',ucinn_ascendv2__External_Payment_Gateway_ID__c = '12345',ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Credit Card',RecordTypeId = [Select Id From RecordType WHERE Name = 'Recurring Gift'].Id,ucinn_ascendv2__Contact__c = cont.Id,ucinn_ascendv2__Adjustment_Reason_v1__c = 'Terminated',StageName = 'Active',CloseDate = Date.today(),ucinn_ascendv2__Start_Date__c = Date.today(),Amount = 100), true);
        
        ucinn_ascendv2__Designation_Detail__c dd1 = (ucinn_ascendv2__Designation_Detail__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__Amount__c = 100,ucinn_ascendv2__Campaign__c = camp.Id,ucinn_ascendv2__Designation__c = designation.Id,ucinn_ascendv2__Opportunity__c = opp.Id,ucinn_ascendv2__Start_Date__c = Date.today()), true);
        
        ucinn_ascendv2__Payment__c payment = (ucinn_ascendv2__Payment__c)TestDataFactory.createSObject(new ucinn_ascendv2__Payment__c(ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Cash',ucinn_ascendv2__Opportunity__c = opp.Id,ucinn_ascendv2__Payment_Group_ID__c = '123',ucinn_ascendv2__Payment_Amount__c = 100,ucinn_ascendv2__Designation_Detail__c = dd1.Id,ucinn_ascendv2__Designation__c = designation.Id,ucinn_ascendv2__Transaction_Type__c = 'Recurring Gift Payment'), true);

        // Session
        ucinn_ascendv2__Session__c session =  (ucinn_ascendv2__Session__c)TestDataFactory.createSObject(new ucinn_ascendv2__Session__c(ucinn_ascendv2__Session_Totals_Approved__c = System.now()), true);

        // Hard/soft credit
        ucinn_ascendv2__Hard_and_Soft_Credit__c hsCredit =  (ucinn_ascendv2__Hard_and_Soft_Credit__c)TestDataFactory.createSObject(new ucinn_ascendv2__Hard_and_Soft_Credit__c(Name = 'Hard/Soft Credit',ucinn_ascendv2__Credit_Amount__c = 10.00,ucinn_ascendv2__Designation_Detail__c = dd1.Id,
        ucinn_ascendv2__Credit_Type__c = 'Hard',ucinn_ascendv2__Source__c = 'Payment',ucinn_ascendv2__Payment__c = payment.Id,ucinn_ascendv2__Designation__c = designation.Id,ucinn_ascendv2__Session__c = session.Id), true);

        paramMap.put('giftRec', opp);
        paramMap.put('paymentRec', null);
        paramMap.put('paymentRecNoCreate', payment);
        paramMap.put('designationDetailRecNoCreate', dd1);
        paramMap.put('designationDetailList', new List<ucinn_ascendv2__Designation_Detail__c>{dd1});
        paramMap.put('hardAndSoftCreditList', new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>{hsCredit});
        paramMap.put('hardAndSoftCreditDeleteList', new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>());
        paramMap.put('hardAndSoftCreditList_DCO',  new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>());
        paramMap.put('hardAndSoftCreditDeleteList_DCO',  new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>());
        paramMap.put('tributeList', new List<ucinn_ascendv2__Tribute__c>());
        
        //GIVEN: A payment record exists

        Test.startTest();
        
        //WHEN: Recurring gift is adjusted
        ascend_GIFT_RecurringGiftOverride rgOverride = new ascend_GIFT_RecurringGiftOverride();
        
        rgOverride.adjustRecurringGift(paramMap);

        test.stopTest();

        // THEN: The payment is relinked to an Adjusted Opportunity (ending with A)  
        payment = [SELECT Id,ucinn_ascendv2__Opportunity__c,ucinn_ascendv2__Opportunity__r.Name FROM ucinn_ascendv2__Payment__c WHERE id= :payment.Id];
        String s_adjustedOpp = payment.ucinn_ascendv2__Opportunity__r.Name;
        system.assert(s_adjustedOpp.endsWith('A'));
    }
}