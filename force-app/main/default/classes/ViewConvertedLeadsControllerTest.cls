/**
 * @description       : Test class ViewConvertedLeadsController
 * @author            : Davey Yu
 * @date              : 2024-03-21
 * @group             : Test
 * @group             : Enterprise
**/
@isTest
public with sharing class ViewConvertedLeadsControllerTest {
    private final static String TEST_SETUP_NAME = 'ViewConvertedLeadsController';
    /*******************************************************************************
    * @author       Davey Yu
    * @date         21/03/2024
    * @description  Test Setup Method for ViewConvertedLeadsController 
    * @revision     1.0
    *******************************************************************************/
    @testSetup
    static void setup() {
         
        Account accountRecord = (Account)TestDataFactory.createSObject(new Account(Name = 'AccountTest', NumberOfEmployees = 1, 
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('External Organisation').getRecordTypeId()), true);

        Contact testContact = (Contact)TestDataFactory.createSObject(new Contact(firstName= 'TestFirstName' , LastName = 'TestLastName', AccountId = accountRecord.Id, 
        RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Not known to Monash systems').getRecordTypeId()), true);

        Opportunity opportunityRecord = (Opportunity)TestDataFactory.createSObject(new Opportunity(name ='OpportunityTest', AccountId = accountRecord.Id, Source__c = 'PURE', StageName = 'Identification',
                                        CloseDate = date.today() + 10, RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId()), true);
 
    }

    /*******************************************************************************
    * @author       Davey Yu
    * @date         21/03/2024
    * @description  Test Method to retrieve related lead records from account page
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void getEntityDataTestFromAccount(){   
        List<Account> accountList = [Select id from Account];
        Test.startTest(); 
        List<Lead> newLeads = TestHelper.createLeads(1);
        Integer ctr = 0;
        Id enterpriseRecordTypeCase = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
        //Given a lead record is created with the account lookup populated
        for(Lead iLead : newLeads) {
            iLead.RecordTypeId = enterpriseRecordTypeCase;
            iLead.Account__c = accountList[0].id;
            ctr++;
        }
        insert newLeads;

        //When user view the account record
        List<ViewConvertedLeadsController.LeadWrapper> relatedLeads = ViewConvertedLeadsController.getEntityData(accountList[0].id);
    
        //Then related lead records should be visible
        System.assertEquals(1, relatedLeads.size()); 
	
        Test.stopTest();
    }

    /*******************************************************************************
    * @author       Davey Yu
    * @date         21/03/2024
    * @description  Test Method to retrieve related lead records from Lead page
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void getEntityDataTestFromLead(){   
        List<Account> accountList = [Select id from Account];
        Test.startTest(); 
        List<Lead> newLeads = TestHelper.createLeads(1);
        Integer ctr = 0;
        Id enterpriseRecordTypeCase = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
        //Given a lead record is created with the account lookup populated
        for(Lead iLead : newLeads) {
            iLead.RecordTypeId = enterpriseRecordTypeCase;
            iLead.Account__c = accountList[0].id;
            ctr++;
        }
        insert newLeads;

        //When user view the lead record
        List<ViewConvertedLeadsController.LeadWrapper> relatedLeads = ViewConvertedLeadsController.getEntityData(newLeads[0].id);
    
        //Then related lead records should be visible 
        System.assertEquals(1, relatedLeads.size()); 
        Test.stopTest();
    }
    
    /*******************************************************************************
    * @author       Davey Yu
    * @date         21/03/2024
    * @description  Test Method to retrieve related lead records from Lead page and expected to return null
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void getEntityDataTestFromOpportunity(){   
        List<Opportunity> oppList = [Select id from Opportunity];
        Test.startTest(); 
        List<Lead> newLeads = TestHelper.createLeads(1);
        Integer ctr = 0;
        Id enterpriseRecordTypeCase = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
        //Given a lead record is created with the account lookup populated
        for(Lead iLead : newLeads) {
            iLead.RecordTypeId = enterpriseRecordTypeCase;
            ctr++;
        }
        insert newLeads;

        //When user view the lead record
        List<ViewConvertedLeadsController.LeadWrapper> relatedLeads = ViewConvertedLeadsController.getEntityData(null);
    
        //Then related lead records should be visible 
        System.assertEquals(null, relatedLeads); 
        Test.stopTest();
    }

}