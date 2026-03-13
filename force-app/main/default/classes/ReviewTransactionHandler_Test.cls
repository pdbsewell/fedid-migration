/**
 * @author          Zach Soohoo: UC Innovation
 * @description     Test class for review transaction logic
 */
@isTest(isParallel=false) // Test.getStandardPricebookId called on Opportunity trigger
private class ReviewTransactionHandler_Test {
    
    @TestSetup
    static void setupData() {
        // Setup trigger handler
        ucinn_ascendv2__Trigger_Handler__c th = new ucinn_ascendv2__Trigger_Handler__c();
        th.Name = 'Review Transaction Handler Extension';
        th.ucinn_ascendv2__Class__c = 'ReviewTransactionHandler';
        th.ucinn_ascendv2__Object__c = 'ucinn_ascendv2__Review_Transaction__c';
        th.ucinn_ascendv2__Load_Order__c = 1.0;
        th.ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert; BeforeUpdate; BeforeDelete; AfterInsert; AfterUpdate; AfterDelete; AfterUndelete';
        th.ucinn_ascendv2__Is_Active__c = true;
        insert th;
        
        // *********************************************
        // Create Pledge records for multiple testing
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;
        
        Test.startTest();
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid+'A';
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'A';
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge';
        rt1.Pledge_No__c = 'P888888SC';
        rtList.add(rt1);
        
        ucinn_ascendv2__Review_Transaction__c rt2 = new ucinn_ascendv2__Review_Transaction__c();
        rt2.Name = 'PRAX'+guid+'B';
        rt2.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'B';
        rt2.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt2.ucinn_ascendv2__Amount_1__c = 1200;
        rt2.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt2.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt2.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt2.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt2.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt2.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt2.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt2.ucinn_ascendv2__Transaction_Type__c = 'Pledge';
        rt2.Pledge_No__c = 'P000000SC';
        rtList.add(rt2);
        
        insert rtList;
        // *********************************************
    }
    
    @isTest
    static void testInvalidDonor() {
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
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid;
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Gift';
        rtList.add(rt1);
        insert rtList;
        
        System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        System.assertEquals('Invalid Donor', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
    }
    
    @isTest
    static void testInvalidDesignation() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid;
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid;
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'TEST99999';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Gift';
        rtList.add(rt1);
        insert rtList;
        
        System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        System.assertEquals('Invalid Designation', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
    }
    
    @isTest
    static void testInvalidAppeal() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid;
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid;
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = 'TEST99999';
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Gift';
        rtList.add(rt1);
        insert rtList;
        
        System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        System.assertEquals('Invalid Appeal Code', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
    }
    
    @isTest
    static void testDesignationTextMissing() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid;
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid;
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Gift';
        rtList.add(rt1);
        insert rtList;
        
        System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        System.assertEquals('Invalid Designation for designation text missing', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
    }
    
    @isTest
    static void testAppealCodeTestMissing() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);        
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid;
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid;
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Gift';
        rtList.add(rt1);
        insert rtList;
        
        System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        System.assertEquals('Invalid Appeal code for appeal code text missing', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
    }
    
    @isTest
    static void testPledgeAlreadyExist() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge';
        rt1.Pledge_No__c = 'P888888SC';
        rtList.add(rt1);
        insert rtList;
        
        System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        System.assertEquals('Pledge already exist', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
    }
    
    @isTest
    static void testPaymentDesignationDoesNotMatch() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        List<ucinn_ascendv2__Review_Transaction__c> mylist = [Select Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Designation_1_Name__c, ucinn_ascendv2__Appeal_No_Source_Code__c 
                                                              From ucinn_ascendv2__Review_Transaction__c Where Pledge_No__c = 'P888888SC' Limit 1];

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;

        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__Contact__c = mylist[0].ucinn_ascendv2__Contact__c;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'TEST9999';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = mylist[0].ucinn_ascendv2__Appeal_No_Source_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge Payment';
        rt1.Pledge_No__c = 'P888888SC';
        rtList.add(rt1);
        insert rtList;
        
        Boolean isIgnoreDesignationEnabled = False;
        List<Review_Transaction_Setting__mdt> mdtList = [Select Id, Boolean_Value__c From Review_Transaction_Setting__mdt Where DeveloperName='Pledge_Payment_Ignore_Designation'];
        if (!mdtList.isEmpty()) {
            isIgnoreDesignationEnabled = mdtList[0].Boolean_Value__c;
        }
        
        if (!isIgnoreDesignationEnabled) {
            System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
            System.assertEquals('Payment Designation does not match', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
        }
    }
    
    @isTest
    static void testPaymentAppealDoesNotMatch() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        List<ucinn_ascendv2__Review_Transaction__c> mylist = [Select Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Designation_1_Name__c, ucinn_ascendv2__Appeal_No_Source_Code__c 
                                                              From ucinn_ascendv2__Review_Transaction__c Where Pledge_No__c = 'P888888SC' Limit 1];

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;

        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__Contact__c = mylist[0].ucinn_ascendv2__Contact__c;
        rt1.ucinn_ascendv2__Designation_1_Name__c = mylist[0].ucinn_ascendv2__Designation_1_Name__c;
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = 'TEST9999';
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge Payment';
        rt1.Pledge_No__c = 'P888888SC';
        rtList.add(rt1);
        insert rtList;
        
        Boolean isIgnoreDesignationEnabled = False;
        List<Review_Transaction_Setting__mdt> mdtList = [Select Id, Boolean_Value__c From Review_Transaction_Setting__mdt Where DeveloperName='Pledge_Payment_Ignore_Designation'];
        if (!mdtList.isEmpty()) {
            isIgnoreDesignationEnabled = mdtList[0].Boolean_Value__c;
        }
        
        if (!isIgnoreDesignationEnabled) {
            System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
            System.assertEquals('Payment Appeal does not match', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
        }
    }
    
    @isTest
    static void testPledge() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        
        ucinn_ascendv2__Designation__c des2 = new ucinn_ascendv2__Designation__c();
        des2.Name = 'D-'+guid+'2';
        des2.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'2';
        des2.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des2.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des2.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des2.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des2.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des2.Tax_Status_Code__c = 'S1';
        desList.add(des2);
        
        ucinn_ascendv2__Designation__c des3 = new ucinn_ascendv2__Designation__c();
        des3.Name = 'D-'+guid+'3';
        des3.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'3';
        des3.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des3.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des3.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des3.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des3.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des3.Tax_Status_Code__c = 'S1';
        desList.add(des3);
        
        ucinn_ascendv2__Designation__c des4 = new ucinn_ascendv2__Designation__c();
        des4.Name = 'D-'+guid+'4';
        des4.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'4';
        des4.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des4.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des4.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des4.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des4.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des4.Tax_Status_Code__c = 'S1';
        desList.add(des4);
        
        ucinn_ascendv2__Designation__c des5 = new ucinn_ascendv2__Designation__c();
        des5.Name = 'D-'+guid+'5';
        des5.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'5';
        des5.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des5.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des5.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des5.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des5.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des5.Tax_Status_Code__c = 'S1';
        desList.add(des5);
        
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid;
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid;
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Designation_2_Name__c = 'D-'+guid+'2';
        rt1.ucinn_ascendv2__Designation_3_Name__c = 'D-'+guid+'3';
        rt1.ucinn_ascendv2__Designation_4_Name__c = 'D-'+guid+'4';
        rt1.ucinn_ascendv2__Designation_5_Name__c = 'D-'+guid+'5';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 100;
        rt1.ucinn_ascendv2__Amount_2__c = 200;
        rt1.ucinn_ascendv2__Amount_3__c = 300;
        rt1.ucinn_ascendv2__Amount_4__c = 400;
        rt1.ucinn_ascendv2__Amount_5__c = 500;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge';
        rtList.add(rt1);
        insert rtList;

        System.assertEquals('Posted', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
    }
    
    @isTest
    static void testPledgeUpdate() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        List<ucinn_ascendv2__Review_Transaction__c> mylist = [Select Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Designation_1_Name__c, ucinn_ascendv2__Appeal_No_Source_Code__c,
                                                                  ucinn_ascendv2__Is_Ready_To_Post__c, ucinn_ascendv2__Session__c
                                                              From ucinn_ascendv2__Review_Transaction__c Where Pledge_No__c = 'P000000SC' Limit 1];

        //Create Session
        ucinn_ascendv2__Session__c ses = new ucinn_ascendv2__Session__c();
        ses.Name = 'S'+guid;
        ses.ucinn_ascendv2__Session_Date__c = Date.today();
        insert ses;

        if (mylist[0].ucinn_ascendv2__Session__c == null) {
            mylist[0].ucinn_ascendv2__Session__c = ses.Id;
            Update mylist;
        }
        
        
        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;
        
        mylist[0].ucinn_ascendv2__Contact__c = conList[0].Id;
        mylist[0].ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        mylist[0].ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        mylist[0].ucinn_ascendv2__Is_Ready_To_Post__c = True;
        Update mylist;
        
        System.debug('charlie11' + mylist);
        System.debug('charlie' + ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:mylist[0].Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
        System.assertEquals('Posted', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:mylist[0].Id])[0].ucinn_ascendv2__Status__c);
    }
    
    @isTest
    static void testPledgePayment() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        List<ucinn_ascendv2__Review_Transaction__c> mylist = [Select Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Designation_1_Name__c, ucinn_ascendv2__Appeal_No_Source_Code__c 
                                                              From ucinn_ascendv2__Review_Transaction__c Where Pledge_No__c = 'P888888SC' Limit 1];

        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__Contact__c = mylist[0].ucinn_ascendv2__Contact__c;
        rt1.ucinn_ascendv2__Designation_1_Name__c = mylist[0].ucinn_ascendv2__Designation_1_Name__c;
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = mylist[0].ucinn_ascendv2__Appeal_No_Source_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge Payment';
        rt1.Pledge_No__c = 'P888888SC';
        rtList.add(rt1);
        insert rtList;
        
        System.assertEquals('Posted', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        
    }
    
    @isTest
    static void testPledgePaymentNoPledgeNumber() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        List<ucinn_ascendv2__Review_Transaction__c> mylist = [Select Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Designation_1_Name__c, ucinn_ascendv2__Appeal_No_Source_Code__c 
                                                              From ucinn_ascendv2__Review_Transaction__c Where Pledge_No__c = 'P888888SC' Limit 1];

        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__Contact__c = mylist[0].ucinn_ascendv2__Contact__c;
        rt1.ucinn_ascendv2__Designation_1_Name__c = mylist[0].ucinn_ascendv2__Designation_1_Name__c;
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = mylist[0].ucinn_ascendv2__Appeal_No_Source_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge Payment';
        rtList.add(rt1);
        insert rtList;
                
        System.assertEquals('Posted', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:mylist[0].Id])[0].ucinn_ascendv2__Status__c);
    }
    
    @isTest
    static void testPledgePaymentCreateOutrightGift() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        
        ucinn_ascendv2__Designation__c des2 = new ucinn_ascendv2__Designation__c();
        des2.Name = 'D-'+guid+'2';
        des2.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'2';
        des2.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des2.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des2.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des2.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des2.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des2.Tax_Status_Code__c = 'S1';
        desList.add(des2);
        
        ucinn_ascendv2__Designation__c des3 = new ucinn_ascendv2__Designation__c();
        des3.Name = 'D-'+guid+'3';
        des3.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'3';
        des3.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des3.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des3.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des3.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des3.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des3.Tax_Status_Code__c = 'S1';
        desList.add(des3);
        
        ucinn_ascendv2__Designation__c des4 = new ucinn_ascendv2__Designation__c();
        des4.Name = 'D-'+guid+'4';
        des4.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'4';
        des4.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des4.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des4.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des4.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des4.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des4.Tax_Status_Code__c = 'S1';
        desList.add(des4);
        
        ucinn_ascendv2__Designation__c des5 = new ucinn_ascendv2__Designation__c();
        des5.Name = 'D-'+guid+'5';
        des5.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'5';
        des5.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des5.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des5.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des5.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des5.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des5.Tax_Status_Code__c = 'S1';
        desList.add(des5);
        
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid;
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid;
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1__c = desList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Designation_2_Name__c = 'D-'+guid+'2';
        rt1.ucinn_ascendv2__Designation_3_Name__c = 'D-'+guid+'3';
        rt1.ucinn_ascendv2__Designation_4_Name__c = 'D-'+guid+'4';
        rt1.ucinn_ascendv2__Designation_5_Name__c = 'D-'+guid+'5';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 100;
        rt1.ucinn_ascendv2__Amount_2__c = 200;
        rt1.ucinn_ascendv2__Amount_3__c = 300;
        rt1.ucinn_ascendv2__Amount_4__c = 400;
        rt1.ucinn_ascendv2__Amount_5__c = 500;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge Payment';
        rtList.add(rt1);
        insert rtList;

        System.assertEquals('Posted', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
    }
    
    @isTest
    static void testGift() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid;
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid;
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 100;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Gift';
        rt1.ucinn_ascendv2__Status__c = 'Manual Review';
        rt1.ucinn_ascendv2__Manual_Review_Reason__c = 'Testing';
        rtList.add(rt1);
        insert rtList;
        
        //Create Session
        ucinn_ascendv2__Session__c ses = new ucinn_ascendv2__Session__c();
        ses.Name = 'S'+guid;
        ses.ucinn_ascendv2__Session_Date__c = Date.today();
        insert ses;
        
        rt1.ucinn_ascendv2__Session__c = ses.id;
        rt1.ucinn_ascendv2__Status__c = 'New';
        rt1.ucinn_ascendv2__Manual_Review_Reason__c = null;
        update rt1;

        System.assertEquals('Posted', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        System.assertEquals(True, ([Select ucinn_ascendv2__Is_Ready_for_G_L__c From ucinn_ascendv2__Session__c Where Id = :ses.Id])[0].ucinn_ascendv2__Is_Ready_for_G_L__c);
    }
    @isTest
    static void testPledgeNotFound() {
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;
        
        // Create Designations
        List<ucinn_ascendv2__Designation__c> desList = new List<ucinn_ascendv2__Designation__c>();
        ucinn_ascendv2__Designation__c des1 = new ucinn_ascendv2__Designation__c();
        des1.Name = 'D-'+guid+'1';
        des1.ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1';
        des1.ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1);
        des1.ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1);
        des1.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        des1.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        des1.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        des1.Tax_Status_Code__c = 'S1';
        desList.add(des1);
        insert desList;
        
        // Create Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> rtList = new List<ucinn_ascendv2__Review_Transaction__c>();
        ucinn_ascendv2__Review_Transaction__c rt1 = new ucinn_ascendv2__Review_Transaction__c();
        rt1.Name = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid+'2';
        rt1.ucinn_ascendv2__Contact__c = conList[0].Id;
        rt1.ucinn_ascendv2__Designation_1_Name__c = 'D-'+guid+'1';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__Appeal_No_Source_Code__c = cmp.ucinn_ascendv2__Motivation_Code__c;
        rt1.ucinn_ascendv2__Amount_1__c = 1200;
        rt1.ucinn_ascendv2__Installment_Amount_1__c = 100;
        rt1.ucinn_ascendv2__Installment_Amount_2__c = 200;
        rt1.ucinn_ascendv2__Installment_Amount_3__c = 300;
        rt1.ucinn_ascendv2__Number_Of_Payments__c = '3';
        rt1.ucinn_ascendv2__Transaction_Date__c = Date.today();
        rt1.ucinn_ascendv2__First_Payment_Date__c = Date.today(); // This is required
        rt1.ucinn_ascendv2__Payment_Frequency__c = 'Annual';      // This is required
        rt1.ucinn_ascendv2__Transaction_Type__c = 'Pledge Payment';
        rt1.Pledge_No__c = 'P7';
        rtList.add(rt1);
        insert rtList;
        
        System.assertEquals('Manual Review', ([Select ucinn_ascendv2__Status__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Status__c);
        System.assertEquals('No Pledge match found', ([Select ucinn_ascendv2__Manual_Review_Reason__c From ucinn_ascendv2__Review_Transaction__c Where Id=:rt1.Id])[0].ucinn_ascendv2__Manual_Review_Reason__c);
    }
    
}