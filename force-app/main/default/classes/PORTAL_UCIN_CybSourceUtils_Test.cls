@isTest(isParallel=false)
public class PORTAL_UCIN_CybSourceUtils_Test {
    @isTest static void testCreateRecurringSubOnlineDonation() {
        Contact con = new Contact();
        con.LastName = 'Test Last Name';
        insert con;

        Opportunity opp = new Opportunity();
        opp.name = 'test';
        opp.ucinn_ascendv2__Contact__c = con.Id;
        opp.StageName = 'Funded';
        opp.CloseDate = system.today();
        opp.Amount = 12;
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
        payment.ucinn_ascendv2__Payment_Group_ID__c = 'test123';
        payment.ucinn_ascendv2__Opportunity__c = opp.Id;
        insert payment;

        ucinn_ascendv2__Transaction_Data__c transData = new ucinn_ascendv2__Transaction_Data__c();
        transData.ucinn_ascendv2__Merchant_Reference_Code__c = 'test123';
        transData.ucinn_ascendv2__Is_Success__c = true;
        transData.ucinn_ascendv2__Subscription_ID__c = '123';
        transData.ucinn_ascendv2__Authorized_Date__c = system.today();
        transData.ucinn_ascendv2__Contact__c = con.Id;
        transData.ucinn_ascendv2__Transaction_Type__c = 'Recurring Subscription Creation';
        transData.ucinn_ascendv2__Gift_or_Pledge__c = opp.Id;
        insert transData;

        ucinn_ascendv2__Transaction_Data__c transData2 = new ucinn_ascendv2__Transaction_Data__c();
        transData2.ucinn_ascendv2__Merchant_Reference_Code__c = 'test123';
        transData2.ucinn_ascendv2__Is_Success__c = true;
        transData2.ucinn_ascendv2__Subscription_ID__c = '123';
        transData2.ucinn_ascendv2__Authorized_Date__c = system.today();
        transData2.ucinn_ascendv2__Contact__c = con.Id;
        transData2.ucinn_ascendv2__Transaction_Type__c = 'Unsubscribed Payment';
        transData2.ucinn_ascendv2__Gift_or_Pledge__c = opp.Id;
        insert transData2;

        test.startTest();
        PORTAL_UCIN_CybSourceUtils.updateRelatedRecords(new List<ucinn_ascendv2__Transaction_Data__c>{transData, transData2});
        test.stopTest();

        Opportunity thisOpp = [SELECT ID,ucinn_ascendv2__External_Payment_Gateway_ID__c,ucinn_ascendv2__Subscription_ID__c FROM Opportunity WHERE ID =: opp.Id];
        System.Assert(thisOpp.ucinn_ascendv2__External_Payment_Gateway_ID__c == transData.ucinn_ascendv2__Merchant_Reference_Code__c);
        System.Assert(thisOpp.ucinn_ascendv2__Subscription_ID__c == transData.ucinn_ascendv2__Subscription_ID__c);
        
    }
}