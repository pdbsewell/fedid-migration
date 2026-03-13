/**
 * @description       : Test class for ReviewTransationv2Service
 * @author            : Inderpal Dhanoa
 * @date              : 2023-03-01
 * @group             : Test
 * @group             : Engage
 * @last modified on  : 2022-03-01
 * @last modified by  : Inderpal Dhanoa
**/
@isTest//(isParallel=true) System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
public class ReviewTransationv2Service_Test { 
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         01.Mar.2023
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {

        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id proposalRecordTypeId = recordTypes.get('Gift').getRecordTypeId(); 

        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Online_Donation_Interface' AND SobjectType = 'ucinn_ascendv2__Interim__c'].Id;
        
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

        // Interim Record
        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'Test 666', ucinn_ascendv2__Last_Name__c = 'Interim', RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'New');
        insert testInterim;

        
    }

    /*******************************************************************************
     * @author      Inderpal Dhanoa
     * @date         1.March.2023
     * @description  Tests regarding to capturing the syncing
    *******************************************************************************/
	@isTest 
    static void testSyncAppealDesignationInfoCreate() {

        //GIVEN : An Interm and Contact must exist

        Contact cont = [SELECT Id FROM Contact WHERE FirstName = 'temp firstName' ORDER By CreatedDate LIMIT 1];

        ucinn_ascendv2__Interim__c testInterim = [SELECT Id FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'Test 666'];

        //Start test
        Test.startTest();

        // WHEN: A RTV2 record is created
        RecordType transactionRecordType_online = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ucinn_ascendv2__Review_Transaction_v2__c' and DeveloperName = 'Online_Donation_Transaction']; 
        ucinn_ascendv2__Review_Transaction_v2__c reviewTrnscn = (ucinn_ascendv2__Review_Transaction_v2__c)TestDataFactory.createSObject(new ucinn_ascendv2__Review_Transaction_v2__c(Name = 'Payment Name', 
                                                                RecordTypeId = transactionRecordType_online.Id, 
                                                                ucinn_ascendv2__Contact__c = cont.Id, ucinn_ascendv2__Payment_Amount_1_1__c = 1000,ucinn_ascendv2__Is_Anonymous__c = true, Gift_Comments__c = 'Test',
                                                                Source__c = 'Contact Supplied', ucinn_ascendv2__Transaction_Date__c = Date.today(), ucinn_ascendv2__Designation_External_ID_1__c = 'Designation Name',//designationDetail.Name, 
                                                                ucinn_ascendv2__Transaction_Type__c = 'Gift', ucinn_ascendv2__Manual_Review_Reason__c = 'Created from RTv2',
                                                                ucinn_ascendv2__Installment_Frequency_1__c  = 'Irregular', ucinn_ascendv2__Tender_Type_1__c = 'Credit Card', ucinn_ascendv2__Transaction_ID__c='6655040243216368003008',
                                                                ucinn_ascendv2__Interim__c = testInterim.Id, ucinn_ascendv2__External_System_ID__c = 'PRAX-TEST-1234455643', 
                                                                Payment_Settlement_Date__c = Date.today().adddays(-2), Batch_Id__c = '123456', ucinn_ascendv2__Status__c = 'Manual Review'), true);
        
        Test.stopTest();

        // THEN: The Designation lookup should point to the relevant Designation
        reviewTrnscn = [SELECT Id,ucinn_ascendv2__Designation_1__r.Name FROM ucinn_ascendv2__Review_Transaction_v2__c WHERE Id = :reviewTrnscn.Id];
        
        system.assertEquals(reviewTrnscn.ucinn_ascendv2__Designation_1__r.Name, 'Designation Name');

    }

    /*******************************************************************************
     * @author      Inderpal Dhanoa
     * @date         1.Nov.2023
     * @description  Tests regarding to updating the Syncing
    *******************************************************************************/
	@isTest 
    static void testSyncAppealDesignationInfoUpdate() {

        // Designation
        ucinn_ascendv2__Designation__c designation2 =  (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation__c(Name = 'Designation Name 2', ucinn_ascendv2__Program_Code__c = 'GL_Acc', 
                                                             ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack', ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD', Tax_Status_Code__c = 'S1'), true);

        //GIVEN : An Interm and Contact must exist
        Contact cont = [SELECT Id FROM Contact WHERE FirstName = 'temp firstName' ORDER By CreatedDate LIMIT 1];

        ucinn_ascendv2__Interim__c testInterim = [SELECT Id FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'Test 666'];

        RecordType transactionRecordType_online = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ucinn_ascendv2__Review_Transaction_v2__c' and DeveloperName = 'Online_Donation_Transaction']; 
        ucinn_ascendv2__Review_Transaction_v2__c reviewTrnscn = (ucinn_ascendv2__Review_Transaction_v2__c)TestDataFactory.createSObject(new ucinn_ascendv2__Review_Transaction_v2__c(Name = 'Payment Name', 
                                                                RecordTypeId = transactionRecordType_online.Id, 
                                                                ucinn_ascendv2__Contact__c = cont.Id, ucinn_ascendv2__Payment_Amount_1_1__c = 1000,ucinn_ascendv2__Is_Anonymous__c = true, Gift_Comments__c = 'Test',
                                                                Source__c = 'Contact Supplied', ucinn_ascendv2__Transaction_Date__c = Date.today(), ucinn_ascendv2__Designation_External_ID_1__c = 'Designation Name',//designationDetail.Name, 
                                                                ucinn_ascendv2__Transaction_Type__c = 'Gift', ucinn_ascendv2__Manual_Review_Reason__c = 'Created from RTv2',
                                                                ucinn_ascendv2__Installment_Frequency_1__c  = 'Irregular', ucinn_ascendv2__Tender_Type_1__c = 'Credit Card', ucinn_ascendv2__Transaction_ID__c='6655040243216368003008',
                                                                ucinn_ascendv2__Interim__c = testInterim.Id, ucinn_ascendv2__External_System_ID__c = 'PRAX-TEST-1234455643', 
                                                                Payment_Settlement_Date__c = Date.today().adddays(-2), Batch_Id__c = '123456', ucinn_ascendv2__Status__c = 'Manual Review'), true);

          
                                                                
        reviewTrnscn.ucinn_ascendv2__Designation_1__c = null;
        reviewTrnscn.ucinn_ascendv2__Designation_External_ID_1__c = '';
        update reviewTrnscn;

        //Start test
        Test.startTest();
        
        // WHEN: A RTV2 record is updated

        reviewTrnscn.ucinn_ascendv2__Designation_External_ID_1__c = 'Designation Name 2';
        update reviewTrnscn;
        
        Test.stopTest();

        // THEN: The Designation lookup should point to the relevant Designation
        reviewTrnscn = [SELECT Id,ucinn_ascendv2__Designation_1__r.Name FROM ucinn_ascendv2__Review_Transaction_v2__c WHERE Id = :reviewTrnscn.Id];
        
        system.assertEquals(reviewTrnscn.ucinn_ascendv2__Designation_1__r.Name, 'Designation Name 2');                                         
    }
}