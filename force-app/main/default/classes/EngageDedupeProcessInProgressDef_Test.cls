@isTest(isParallel=true)
public class EngageDedupeProcessInProgressDef_Test {
    
    @testSetup
    public static void testInProgressInterimSetup() {
        
        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Online_Donation_Interface' AND RecordType.NamespacePrefix = 'ucinn_ascendv2'].Id;

        Contact testContact = new Contact(LastName = 'Test',
                                          FirstName = 'Contact');
        
        Contact testContact2 = new Contact(LastName = 'Test2',
                                          FirstName = 'Contact2');
        
        insert new List<Contact>{testContact, testContact2};

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestInProg', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim', 
                                                                                RecordTypeId = reRecordTypeID, 
                                                                                ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Phone_1__c = '1231231234',
                                                                                ucinn_ascendv2__Email_1__c = 'Email@Email.com',
                                                                                ucinn_ascendv2__Address_1_Line_1__c = 'Address Line 1',
                                                                                ucinn_ascendv2__Contact__c = testContact.Id);
        //For manual review.
        ucinn_ascendv2__Interim__c testInterim2 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestInProg2', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim2', 
                                                                                RecordTypeId = reRecordTypeID, 
                                                                                ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Phone_1__c = '1231231234',
                                                                                ucinn_ascendv2__Email_1__c = 'Email@Email.com',
                                                                                ucinn_ascendv2__Email_1_Type__c = 'Private',
                                                                                ucinn_ascendv2__Phone_1_Type__c = 'Mobile',
                                                                                ucinn_ascendv2__Address_1_Line_1__c = 'Address Line 1',
                                                                                ucinn_ascendv2__Contact__c = testContact2.Id);

        insert new List<ucinn_ascendv2__Interim__c> {testInterim, testInterim2};
            
        //Should cause manual review on invalid phone type
        testInterim.ucinn_ascendv2__Phone_1_Type__c = 'ERROR';
        
        update testInterim;
            
        
        
        ucinn_ascendv2__Session__c session = new ucinn_ascendv2__Session__c();
        session.Name = 's1test';
        session.ucinn_ascendv2__Gift_Pledge_Payment_Amount__c = 10;
        session.ucinn_ascendv2__Session_Date__c = Date.today();
        session.ucinn_ascendv2__No_of_Transactions_Posted__c = 1;
        session.ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c = 10;
        session.ucinn_ascendv2__Session_Date__c = Date.today();
        session.ucinn_ascendv2__Source__c = 'PRAX';
        session.ucinn_ascendv2__Is_Ready_for_G_L__c = true;
        session.ucinn_ascendv2__Is_Completed_by_Gift_Specialist__c = true;
        session.ucinn_ascendv2__Session_Completed_By__c = null;
        session.ucinn_ascendv2__Session_Started__c = DateTime.now();
        session.ucinn_ascendv2__Session_Completed__c = DateTime.now();
        session.ucinn_ascendv2__Session_Totals_Approved__c = DateTime.now();
        insert session;
        
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid+'A';
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'A';
        rt1.ucinn_ascendv2__Contact__c = testContact.Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Interim__c = testInterim2.Id;
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge';
        rt1.Pledge_No__c = 'P888888SC';
        rt1.ucinn_ascendv2__session__c = session.id;
        insert rt1;

    }
    
    @isTest
    public static void testInProgressInterim() {
        Test.startTest();
            
        EngageDedupeProcessInProgressDef base = new EngageDedupeProcessInProgressDef();
        base.batchConstructor('Online Donation Interface');
        EngageDedupeProcessInProgressBatch batch = new EngageDedupeProcessInProgressBatch('Online Donation Interface', base);
        Database.executeBatch(batch, 5);
        
        Test.stopTest();     
        ucinn_ascendv2__Interim__c testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'TestInProg'][0];
        ucinn_ascendv2__Interim__c testInterim2 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'TestInProg2'][0];
        System.assert(testInterim.ucinn_ascendv2__Manual_Review_Reason__c != null, 'This interim should be in manual review.');
        System.assert(testInterim2.ucinn_ascendv2__Manual_Review_Reason__c == null, 'This interim should not be in manual review.');
        System.assert(testInterim.ucinn_ascendv2__Status__c == 'Manual Review', 'This interim should have been placed in manual review for invalid phone type.');
    }
    

    
}