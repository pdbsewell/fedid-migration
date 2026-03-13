/**
 * @description Test class for PORTAL_InstallmentService
 * @author      Vinothraja
 * @since       12/03/2025
 * @group       Platforms
 */
@isTest(isParallel=false) // uses Test.getStandardPriceBookId() which cannot be used in parallel tests
public with sharing class PORTAL_InstallmentService_Test {
    @TestSetup
    static void makeData(){
        // Create a contact
        Contact cont = (Contact)TestDataFactory.createSObject(
                                new Contact(Salutation = 'Mr',
                                            FirstName = 'First',
                                            LastName = 'Last',
                                            MobilePhone = '111-111-1111',
                                            Email = 'test@test.com',
                                            ucinn_ascendv2__Contact_Type__c = 'Other',
                                            ucinn_ascendv2__Payroll_ID__c = '123'
                                        ), true);
        // Create an Opportunity (Pledge)
        Opportunity opp = (opportunity)TestDataFactory.createSObject(
                                new Opportunity(Name = 'G123',
                                                Type = 'Recurring',
                                                ucinn_ascendv2__External_Payment_Gateway_ID__c = '12345',
                                                ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Credit Card',
                                                RecordTypeId = [Select Id From RecordType WHERE Name = 'Recurring Gift'].Id,
                                                ucinn_ascendv2__Contact__c = cont.Id,
                                                ucinn_ascendv2__Adjustment_Reason_v1__c = 'Terminated',
                                                StageName = 'Active',
                                                CloseDate = Date.today(),
                                                ucinn_ascendv2__Start_Date__c = Date.today(),
                                                Amount = 100
                                            ), true);

        Campaign camp = (Campaign)TestDataFactory.createSObject(new Campaign(Name = '-',
                                                StartDate = Date.today(),
                                                ucinn_ascendv2__Motivation_Code__c = 'Campaign001')
                                            , true);
        
        ucinn_ascendv2__Designation__c designation = (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(
                                new ucinn_ascendv2__Designation__c(ucinn_ascendv2__Designation_Name__c = 'Test Designation',
                                                ucinn_ascendv2__External_System_ID__c = 'Designation001',
                                                ucinn_ascendv2__Acknowledgement_Description__c = 'Designation001',
                                                ucinn_ascendv2__Program_Code__c = 'GL_Acc',
                                                ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack',
                                                ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD',
                                                Tax_Status_Code__c = 'S1')
                                            , true);

        ucinn_ascendv2__Designation_Detail__c dd1 = (ucinn_ascendv2__Designation_Detail__c)TestDataFactory.createSObject(
                                new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__Amount__c = 100,
                                                ucinn_ascendv2__Campaign__c = camp.Id,
                                                ucinn_ascendv2__Designation__c = designation.Id,
                                                ucinn_ascendv2__Opportunity__c = opp.Id,
                                                ucinn_ascendv2__Payment_Frequency__c = 'Bi-Weekly',
                                                ucinn_ascendv2__Number_of_Payments__c = 12,
                                                ucinn_ascendv2__G_L_Account__c = '12345',
                                                ucinn_ascendv2__Start_Date__c = Date.today())
                                            , true);
        // A valid Installment Record
        ucinn_ascendv2__Installment__c installment = new ucinn_ascendv2__Installment__c ( ucinn_ascendv2__Designation__c = designation.id, 
                                                ucinn_ascendv2__Designation_Detail__c = dd1.id, 
                                                ucinn_ascendv2__Opportunity__c = opp.Id);
        insert installment;
    }


    @isTest
    private static void testFindInstallmentListByPledgeId() {

        // GIVEN
        // A valid pledge
        Opportunity pledge = [SELECT id FROM Opportunity LIMIT 1];

        // WHEN
        // Installments are queried for a Pledge
        Test.startTest();
            PORTAL_InstallmentService service = new PORTAL_InstallmentService();
            Map<String, Object> params = new Map<String, Object>();
            params.put('pledgeId', pledge.Id);
            Map<String, Object> result = (Map<String, Object>) service.findInstallmentListByPledgeId(params, new Map<String, Object>());
        Test.stopTest();    

        // THEN
        // verify if the Installment is returned
        Assert.areEqual(((List<ucinn_ascendv2__Installment__c>)result.get('installmentRecList')).size(), 1, 'Installment not returned for Pledge');
    }

    @isTest
    private static void testCalculateInstallmentsForNewPledge() {
        // GIVEN
        // A valid pledge
        Opportunity pledge = [SELECT id FROM Opportunity LIMIT 1];
        // Valid Designation Detail records
        List<ucinn_ascendv2__Designation_Detail__c> lstDD = [SELECT id, ucinn_ascendv2__Designation__c, ucinn_ascendv2__Payment_Frequency__c, ucinn_ascendv2__Amount__c, ucinn_ascendv2__Number_of_Payments__c, ucinn_ascendv2__G_L_Account__c 
                                                                FROM ucinn_ascendv2__Designation_Detail__c 
                                                                WHERE ucinn_ascendv2__Opportunity__c = :pledge.Id];
        // a defined day of the month
        String selectedDayOfMonth = '15';

        // WHEN
        // Installments are calculated for a Pledge
        Test.startTest();
            PORTAL_InstallmentService service = new PORTAL_InstallmentService();
            Map<String, Object> params = new Map<String, Object>();
            params.put('pledgeRec', pledge);
            params.put('designationDetailRecList', lstDD);
            params.put('selectedPaymentDayOfMonth', selectedDayOfMonth);
            Map<String, Object> result = (Map<String, Object>) service.calculateInstallmentsForNewPledge(params, new Map<String, Object>());
        Test.stopTest();   

        // THEN
        // Installments are calculated and returned
        Assert.isNotNull(result.get('installmentRecList'), 'Installments not calculated for Pledge');
    }
}