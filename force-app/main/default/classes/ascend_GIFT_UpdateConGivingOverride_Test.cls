/**
 * @description ascend_GIFT_UpdateConGivingOverride_Test creates test data and runs the job ascend_GIFT_UpdateConGivingOverride direclty or via schedule.
 *
 * @author Inderpal Dhanoa
 * @date 2023-03-06
 * @revision 1.0
 **/
@isTest//(isParallel=true) System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class ascend_GIFT_UpdateConGivingOverride_Test {

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         06.Mar.2023
     * @description  Test Data setup
    *******************************************************************************/
    @TestSetup
    public static void setupData() {
        // Proposal record type, cannot query by Schema as the name/record
        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id proposalRecordTypeId = recordTypes.get('Major Gift').getRecordTypeId(); // Proposal record type
        Id enterpriseRecordTypeId = recordTypes.get('Enterprise').getRecordTypeId(); // Enterprise record type
        List<Opportunity> l_oppty = new List<Opportunity>();
        String accntName = String.valueOf(JournalBatch_Test.class);
        // Account
        Account accnt = (Account)TestDataFactory.createSObject(new Account(Name = accntName, ucinn_ascendv2__Amount_of_Most_Recent_Gift__c = 20.00), true); 

        // Contact
        Contact cont = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'First', lastName = String.valueOf(JournalBatch_Test.class)), true); 

        // Contact must be assigned (trigger validation on Opportunity object)
        Ucinn_ascendv2__Assignment__c assignment = (Ucinn_ascendv2__Assignment__c)TestDataFactory.createSObject(new Ucinn_ascendv2__Assignment__c(Ucinn_ascendv2__Contact__c = cont.Id, 
                                                                                                            Ucinn_ascendv2__Account__c = accnt.Id, 
                                                                                                            Ucinn_ascendv2__Assigned_Relationship_Manager_User__c = UserInfo.getUserId(),
                                                                                                            ucinn_ascendv2__Assignment_Type__c = 'Alumni Manager'), true); 

        // Oppty creation
        Opportunity oppty1 = (Opportunity)TestDataFactory.createSObject(new Opportunity(Name = accntName, StageName = 'Identification', CloseDate = date.today().addDays(3), AccountId = accnt.Id //,ucinn_ascendv2__Contact__c = cont.Id
                                                                        , RecordTypeId = proposalRecordTypeId, Amount = 10.00, ucinn_ascendv2__External_Payment_Gateway_ID__c = 'PRAX-081821-082411849'), false);
        // Oppty creation
        Opportunity oppty2 = (Opportunity)TestDataFactory.createSObject(new Opportunity(Name = accntName + ' Enterp', StageName = 'Identification', CloseDate = date.today().addDays(3), AccountId = accnt.Id //,ucinn_ascendv2__Contact__c = cont.Id
        , RecordTypeId = enterpriseRecordTypeId, Amount = 10.00, ucinn_ascendv2__External_Payment_Gateway_ID__c = 'PRAX-081821-082411850'), false);

        l_oppty.add(oppty1);
        l_oppty.add(oppty2);
        insert l_oppty;

        oppty1 = [SELECT Id FROM Opportunity WHERE Name = :accntName];
        // Designation
        ucinn_ascendv2__Designation__c designation =  (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation__c(Name = 'Designation Name', ucinn_ascendv2__Program_Code__c = 'GL_Acc', 
                                                              ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack', ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD', Tax_Status_Code__c = 'S1'), true);

         // Designation detail (linked to Oppty) 
        ucinn_ascendv2__Designation_Detail__c designationDetail =  (ucinn_ascendv2__Designation_Detail__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation_Detail__c(Name = '[Default Name]', ucinn_ascendv2__Opportunity__c = oppty1.Id), true);

        // Payment
        ucinn_ascendv2__Payment__c payment = (ucinn_ascendv2__Payment__c)TestDataFactory.createSObject(new ucinn_ascendv2__Payment__c(Name = 'Payment Name', ucinn_ascendv2__Designation_Detail__c = designationDetail.Id, 
                                            ucinn_ascendv2__Opportunity__c = oppty1.Id, Sent_to_SAP__c = false, ucinn_ascendv2__Transaction_ID__c = '100010001001000', Payment_Settled__c = true, Batch_Id__c = '123456',
                                            Payment_Settlement_Date__c = system.now(), ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Visa',
                                            ucinn_ascendv2__Payment_Amount__c = 10.00), true);

         // Session
         ucinn_ascendv2__Session__c session =  (ucinn_ascendv2__Session__c)TestDataFactory.createSObject(new ucinn_ascendv2__Session__c(ucinn_ascendv2__Session_Totals_Approved__c = System.now()), true);

         // Hard/soft credit
         ucinn_ascendv2__Hard_and_Soft_Credit__c hsCredit =  (ucinn_ascendv2__Hard_and_Soft_Credit__c)TestDataFactory.createSObject(new ucinn_ascendv2__Hard_and_Soft_Credit__c(Name = 'Hard/Soft Credit',ucinn_ascendv2__Credit_Amount__c = 10.00,ucinn_ascendv2__Designation_Detail__c = designationDetail.Id,
                                                              ucinn_ascendv2__Credit_Type__c = 'Hard',ucinn_ascendv2__Source__c = 'Payment',ucinn_ascendv2__Payment__c = payment.Id,ucinn_ascendv2__Designation__c = designation.Id,
                                                              ucinn_ascendv2__Session__c = session.Id), true);
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         06.Mar.2023
     * @description  Tests batchConstructor for the Giving summary calculation
    *******************************************************************************/
    @isTest
    public static void batchConstructor_Test(){

        // GIVEN: An Account & Contact exist

        Account accnt = [SELECT Id FROM Account 
                        WHERE Name = :String.valueOf(JournalBatch_Test.class) 
                        ORDER BY createdDate DESC LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE FirstName = 'First' ORDER BY createdDate DESC LIMIT 1];

        Set<Id> contactIdToProcessSet = new Set<Id>{accnt.Id};
        Set<Id> accountIdsToProcessSet = new Set<Id>{con.Id};

        Test.startTest();

        // WHEN : Execute the Batch Job
        ascend_GIFT_UpdateConGivingOverride obj = new ascend_GIFT_UpdateConGivingOverride(); 
        obj.batchConstructor(contactIdToProcessSet, accountIdsToProcessSet);
        Test.stopTest();
        // THEN : Validate the result
        accnt = [SELECT Id, ucinn_ascendv2__Amount_of_Most_Recent_Gift__c FROM Account WHERE Name = :String.valueOf(JournalBatch_Test.class) ORDER BY createdDate DESC LIMIT 1];
        system.assertEquals(20.00, accnt.ucinn_ascendv2__Amount_of_Most_Recent_Gift__c);
    } 

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         06.Mar.2023
     * @description  Tests batchConstructor for the Giving summary calculation
    *******************************************************************************/
    @isTest
    public static void batchConstructor_Test2(){

        // GIVEN: An Account & Contact exist

        Account accnt = [SELECT Id FROM Account 
                        WHERE Name = :String.valueOf(JournalBatch_Test.class) 
                        ORDER BY createdDate DESC LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE FirstName = 'First' ORDER BY createdDate DESC LIMIT 1];

        Set<Id> contactIdToProcessSet = new Set<Id>{accnt.Id};
        Set<Id> accountIdsToProcessSet = new Set<Id>{con.Id};

        Test.startTest();

        // WHEN : Execute the Batch Job

        ascend_GIFT_UpdateConGivingOverride obj = new ascend_GIFT_UpdateConGivingOverride(); 
        String whereClause;
        obj.batchConstructor(whereClause, true);
        Test.stopTest();
        // THEN : Validate the result
        accnt = [SELECT Id, ucinn_ascendv2__Amount_of_Most_Recent_Gift__c FROM Account WHERE Name = :String.valueOf(JournalBatch_Test.class) ORDER BY createdDate DESC LIMIT 1];
        system.assertEquals(20.00, accnt.ucinn_ascendv2__Amount_of_Most_Recent_Gift__c);

    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         06.Mar.2023
     * @description  Tests batchConstructor for the Giving summary calculation
    *******************************************************************************/
    @isTest
    public static void batchStartOverride_Test(){

        // GIVEN: HARD & SOFT Credit record exist

        Test.startTest();

        // WHEN : Execute the Batch Job
        Database.BatchableContext bc;
        ascend_GIFT_UpdateConGivingOverride obj = new ascend_GIFT_UpdateConGivingOverride(); 
        obj.batchStart(bc);
        Test.stopTest();

        // THEN : Validate the result
        Account accnt = [SELECT Id, ucinn_ascendv2__Amount_of_Most_Recent_Gift__c FROM Account WHERE Name = :String.valueOf(JournalBatch_Test.class) ORDER BY createdDate DESC LIMIT 1];
        system.assertEquals(20.00, accnt.ucinn_ascendv2__Amount_of_Most_Recent_Gift__c);

    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         06.Mar.2023
     * @description  Tests batchConstructor Finish for the Giving summary calculation
    *******************************************************************************/
    @isTest
    public static void batchFinish_Test(){
        // GIVEN: HARD & SOFT Credit record exist

        Test.startTest();

        // WHEN : Execute the Batch Job
        Database.BatchableContext bc;
        ascend_GIFT_UpdateConGivingOverride obj = new ascend_GIFT_UpdateConGivingOverride(); 
        obj.batchFinish(bc);
        Test.stopTest();

        // THEN : Validate the result
        Account accnt = [SELECT Id, ucinn_ascendv2__Amount_of_Most_Recent_Gift__c FROM Account WHERE Name = :String.valueOf(JournalBatch_Test.class) ORDER BY createdDate DESC LIMIT 1];
        system.assertEquals(20.00, accnt.ucinn_ascendv2__Amount_of_Most_Recent_Gift__c);
    }
}